
# Get urls of files in selected folders. Requires only data
function get_urls1(url_inputs::String,allowed_ext::Vector{String})
    # Get a reference to url accumulators
    input_urls = Vector{Vector{String}}(undef,0)
    filenames = Vector{Vector{String}}(undef,0)
    # Empty a url accumulator
    empty!(input_urls)
    # Return if empty
    if isempty(url_inputs)
        @warn "Directory is empty."
        return nothing
    end
    # Get directories containing our images and labels
    dirs = getdirs(url_inputs)
    # If no directories, then set empty string
    if length(dirs)==0
        dirs = [""]
    end
    # Collect urls
    for k = 1:length(dirs)
        input_urls_temp = Vector{String}(undef,0)
        dir = dirs[k]
        # Get files in a directory
        files_input = getfiles(string(url_inputs,"/",dir))
        files_input = filter_ext(files_input,allowed_ext)
        # Push urls into an accumulator
        for l = 1:length(files_input)
            push!(input_urls_temp,string(url_inputs,"/",dir,"/",files_input[l]))
        end
        push!(filenames,files_input)
        push!(input_urls,input_urls_temp)
    end
    if dirs==[""]
        url_split = split(url_inputs,('/','\\'))
        dirs = [url_split[end]]
    end
    return input_urls,dirs,filenames
end

# Get urls of files in selected folders. Requires data and labels
function get_urls2(url_inputs::String,label_url::String,allowed_ext::Vector{String})
    # Get a reference to url accumulators
    input_urls = Vector{Vector{String}}(undef,0)
    label_urls = Vector{Vector{String}}(undef,0)
    filenames = Vector{Vector{String}}(undef,0)
    fileindices = Vector{Vector{Int64}}(undef,0)
    # Empty url accumulators
    empty!(input_urls)
    empty!(label_urls)
    # Return if empty
    if isempty(url_inputs) || isempty(label_url)
        @error "Empty urls."
        return nothing,nothing,nothing
    end
    # Get directories containing our images and labels
    dirs_input= getdirs(url_inputs)
    dirs_labels = getdirs(label_url)
    # Keep only those present for both images and labels
    dirs = intersect(dirs_input,dirs_labels)
    # If no directories, then set empty string
    if length(dirs)==0
        dirs = [""]
    end
    # Collect urls
    cnt = 0
    for k = 1:length(dirs)
        input_urls_temp = Vector{String}(undef,0)
        label_urls_temp = Vector{String}(undef,0)
        # Get files in a directory
        files_input = getfiles(string(url_inputs,"/",dirs[k]))
        files_labels = getfiles(string(label_url,"/",dirs[k]))
        # Filter files
        files_input = filter_ext(files_input,allowed_ext)
        files_labels = filter_ext(files_labels,allowed_ext)
        # Remove extensions from files
        filenames_input = remove_ext(files_input)
        filenames_labels = remove_ext(files_labels)
        # Intersect file names
        inds1, inds2 = intersect_inds(filenames_labels, filenames_input)
        # Keep files present for both images and labels
        files_input = files_input[inds2]
        files_labels = files_labels[inds1]
        # Push urls into accumulators
        num = length(files_input)
        for l = 1:num
            push!(input_urls_temp,string(url_inputs,"/",files_input[l]))
            push!(label_urls_temp,string(label_url,"/",files_labels[l]))
        end
        push!(filenames,filenames_input[inds2])
        push!(fileindices,cnt+1:num)
        push!(input_urls,input_urls_temp)
        push!(label_urls,label_urls_temp)
        cnt = num
    end
    return input_urls,label_urls,dirs,filenames,fileindices
end

function load_regression_data(url::String)
    ext_raw = split(url,".")[end]
    ext = Unicode.normalize(ext_raw, casefold=true)
    if ext=="csv"
        labels_info = DataFrame(CSVFiles.load(url))
    else ext=="xlsx"
        labels_info = DataFrame(XLSX.readtable(url,1)...)
    end
    filenames_labels::Vector{String} = labels_info[:,1]
    labels_original_T = map(ind->Vector(labels_info[ind,2:end]),1:size(labels_info,1))
    loaded_labels::Vector{Vector{Float32}} = convert(Vector{Vector{Float32}},labels_original_T)
    return filenames_labels,loaded_labels
end

function intersect_regression_data!(input_urls::Vector{String},filenames_inputs::Vector{String},
        loaded_labels::Vector{Vector{Float32}},filenames_labels::Vector{String})
    num = length(filenames_inputs)
    inds_adj = zeros(Int64,num)
    inds_remove = Vector{Int64}(undef,0)
    cnt = 1
    l = length(filenames_inputs)
    while cnt<=l
        filename = filenames_inputs[cnt]
        ind = findfirst(x -> x==filename, filenames_labels)
        if isnothing(ind)
            deleteat!(input_urls,cnt)
            deleteat!(filenames_inputs,cnt)
            l-=1
        else
            inds_adj[cnt] = ind
            cnt += 1
        end
    end
    num = cnt - 1
    inds_adj = inds_adj[1:num]
    filenames_labels_temp = filenames_labels[inds_adj]
    loaded_labels_temp = loaded_labels[inds_adj]
    r = length(filenames_labels_temp)+1:length(filenames_labels)
    deleteat!(filenames_labels,r)
    deleteat!(loaded_labels,r)
    filenames_labels .= filenames_labels_temp
    loaded_labels .= loaded_labels_temp
    return nothing
end

# Removes rows and columns from image sides if they are uniformly black.
function correct_view(img::Array{Float32,2},label::Array{RGB{Normed{UInt8,8}},2})
    field = dilate(imfilter(img.<0.3, Kernel.gaussian(4)).>0.5,20)
    areaopen!(field,30000)
    field = .!(field)
    field_area = sum(field)
    field_outer_perim = sum(outer_perim(field))/1.25
    circularity = (4*pi*field_area)/(field_outer_perim^2)
    if circularity>0.9
        row_bool = anydim(field,1)
        col_bool = anydim(field,2)
        col1 = findfirst(col_bool)[1]
        col2 = findlast(col_bool)[1]
        row1 = findfirst(row_bool)[1]
        row2 = findlast(row_bool)[1]
        img = img[row1:row2,col1:col2]
        label = label[row1:row2,col1:col2]
    end
    img = rescale(img,(0,1))
    return img,label
end

# Rotate Array
function rotate_array(img::AbstractArray{Real,2},angle_val::Float64)
    if angle!=0
        img_out = imrotate(img,angle_val,axes(img))
        replace_nan!(img_out)
        return(img_out)
    else
        return(img)
    end
end

function rotate_array(img::AbstractArray{T,3},angle_val::Float64) where T<:AbstractFloat
    if angle!=0
        img_out = copy(img)
        for i = 1:size(img,3)
            slice = img[:,:,i]
            temp = imrotate(slice,angle_val,axes(slice))
            replace_nan!(temp)
            img_out[:,:,i] = convert.(T,temp)
        end
        return(img_out)
    else
        return(img)
    end
end

function rotate_array(img::BitArray{3},angle_val::Float64)
    if angle!=0
        img_out = copy(img)
        for i = 1:size(img,3)
            slice = img[:,:,i]
            temp = imrotate(slice,angle_val,axes(slice))
            replace_nan!(temp)
            img_out[:,:,i] = temp.>0
        end
        return(img_out)
    else
        return(img)
    end
end

# Use border data to better separate objects
"""
    apply_border_data(input_data::BitArray{3},classes::Vector{ImageSegmentationClass})

Used for segmentation. Uses borders of objects that a neural network detected in order 
to separate objects from each other. Output from a neural network should be fed after 
converting to BitArray.
"""
function apply_border_data(input_data::BitArray{3},classes::Vector{ImageSegmentationClass})
    class_inds,_,_,border,border_thickness = get_class_data(classes)
    inds_border = findall(border)
    if isnothing(inds_border)
        return input_data
    end
    num_border = length(inds_border)
    num_classes = length(class_inds)
    data = BitArray{3}(undef,size(input_data)[1:2]...,num_border)
    for i = 1:num_border
        border_num_pixels = border_thickness[i]
        ind_classes = inds_border[i]
        ind_border = num_classes + ind_classes
        data_classes_bool = input_data[:,:,ind_classes]
        data_classes = convert(Array{Float32},data_classes_bool)
        data_border = input_data[:,:,ind_border]
        border_bool = data_border
        background1 = erode(data_classes_bool .& border_bool,border_num_pixels)
        background2 = outer_perim(border_bool)
        background2[data_classes_bool] .= false
        background2 = dilate(background2,border_num_pixels+1)
        background = background1 .| background2
        skel = thinning(border_bool)
        background[skel] .= true
        if classes[i].border_remove_objs
            components = label_components((!).(border_bool),conn(4))
            intensities = component_intensity(components,data_classes)
            bad_components = findall(intensities.<0.7)
            for i = 1:length(bad_components)
                components[components.==bad_components[i]] .= 0
            end
            objects = data_classes.!=0
            objects[skel] .= false
            segmented = segment_objects(components,objects)
            borders = mapwindow(x->!allequal(x), segmented, (3,3))
            segmented[borders] .= 0
            data[:,:,ind_classes] = segmented.>0
        else
            data_classes_bool[background] .= false
            data[:,:,i] = data_classes_bool
        end
    end
    return data
end

#---
function accuracy_classification(predicted::A,actual::A) where {T<:Float32,A<:AbstractArray{T,2}}
    acc = Vector{Float32}(undef,0)
    for i in 1:size(predicted,2)
        _ , actual_ind = collect(findmax(actual[:,i]))
        _ , predicted_ind = collect(findmax(predicted[:,i]))
        if actual_ind==predicted_ind
            push!(acc,1)
        else
            push!(acc,0)
        end
    end
    return mean(acc)
end

function accuracy_classification_weighted(predicted::A,actual::A,ws::Vector{T}) where {T<:Float32,A<:AbstractArray{T,2}}
    l = size(predicted,2)
    acc = Vector{Float32}(undef,l)
    w = Vector{Float32}(undef,l)
    for i = 1:l
        _ , actual_ind = collect(findmax(actual[:,i]))
        _ , predicted_ind = collect(findmax(predicted[:,i]))
        w[i] = ws[actual_ind]
        if actual_ind==predicted_ind
            acc[i] = 1
        else
            acc[i] = 0
        end
    end
    return mean(acc,StatsBase.weights(w))
end

function accuracy_regression(predicted::A,actual::A) where {T<:Float32,A<:AbstractArray{T,2}}
    err = abs.(actual .- predicted)
    err_relative = mean(err./actual)
    acc = 1/(1+err_relative)
    return acc
end

function accuracy_segmentation(predicted::A,actual::A) where {T<:Float32,A<:AbstractArray{T,4}}
    # Convert to BitArray
    actual_bool = actual.>0
    predicted_bool = predicted.>0.5
    # Calculate accuracy
    correct_bool = predicted_bool .& actual_bool
    num_correct = convert(Float32,sum(correct_bool))
    acc = num_correct/prod(size(predicted))
    return acc
end

# Weight accuracy using inverse frequency
function accuracy_segmentation_weighted(predicted::A,actual::A,ws::Vector{T}) where {T<:Float32,A<:AbstractArray{T,4}}
    # Convert to BitArray
    actual_bool = actual.>0
    predicted_bool = predicted.>0.5
    # Calculate correct and incorrect class pixels as a BitArray
    correct_bool = predicted_bool .& actual_bool
    dif_bool = xor.(predicted_bool,actual_bool)
    # Calculate class accuracies
    sum_correct_int_dim4 = collect(sum(correct_bool, dims = [1,2,4]))
    sum_dif_int_dim4 = collect(sum(dif_bool, dims = [1,2,4]))
    sum_correct_int = collect(Iterators.flatten(sum_correct_int_dim4))
    sum_dif_int = collect(Iterators.flatten(sum_dif_int_dim4))
    sum_correct = convert(Vector{Float32},sum_correct_int)
    sum_dif = convert(Vector{Float32},sum_dif_int)
    classes_accuracy = sum_correct./(sum_correct.+sum_dif)
    acc = sum(ws.*classes_accuracy)
    return acc
end

function get_weights(classes::Vector{<:AbstractClass},options::Options)
    if options.TrainingOptions.Accuracy.weight_accuracy
        if problem_type()==:Classification
            return map(class -> class.weight,classes)
        elseif problem_type()==:Regression
            return Vector{Float32}(undef,0)
        else # Segmentation
            true_classes_bool = (!).(map(class -> class.not_class, classes))
            classes = classes = classes[true_classes_bool]
            weights = map(class -> class.weight,classes)
            borders_bool = map(class -> class.border, classes)
            border_weights = weights[borders_bool]
            append!(weights,border_weights)
            return weights
        end
    else
        return Vector{Float32}(undef,0)
    end
end

function calculate_weights(counts::Vector{Int64})
    frequencies = counts./sum(counts)
    inv_frequencies = 1 ./frequencies
    weights64 = inv_frequencies./sum(inv_frequencies)
    weights = convert(Vector{Float32},weights64)
    return weights
end

function get_weights(classes::Vector{<:AbstractClass},training_data::TrainingData,options::Options)
    local counts::Vector{Int64}
    if options.TrainingOptions.Accuracy.weight_accuracy
        if problem_type()==:Classification
            classification_labels = training_data.ClassificationData.data_labels
            counts = map(x -> count(x.==classification_labels),1:length(classes))
            weights = calculate_weights(counts)
            for i = 1:length(classes)
                classes[i].weight = weights[1]
            end
        elseif problem_type()==:Regression
            weights = Vector{Float32}(undef,0)
        else # Segmentation
            classes = model_data.classes
            num = length(classes)
            true_classes_bool = (!).(map(class -> class.not_class, classes))
            classes = classes[true_classes_bool]
            regression_labels = training_data.SegmentationData.data_labels
            counts = zeros(Int64,num)
            for data in regression_labels
                counts .+= collect(Iterators.flatten(sum(data[:,:,1:num],dims = [1,2])))
            end
            borders_bool = map(class -> class.border, classes)
            border_counts = counts[borders_bool]
            append!(counts,border_counts)
            weights = calculate_weights(counts)
            for i = 1:length(classes)
                classes[i].weight = weights[i]
            end
        end
    else
        weights = Vector{Float32}(undef,0)
    end
    return weights
end

# Returns an accuracy function
function get_accuracy_func(weights::Vector{Float32},options::Options)
    weight = options.TrainingOptions.Accuracy.weight_accuracy
    if problem_type()==:Classification
        if weight
            return (x,y) -> accuracy_classification_weighted(x,y,weights)
        else
            return accuracy_classification
        end
    elseif problem_type()==:Regression
        return accuracy_regression
    elseif problem_type()==:Segmentation
        if weight
            return  (x,y) -> accuracy_segmentation_weighted(x,y,weights)
        else
            return accuracy_segmentation
        end
    end
end

#---Padding
same(sizes::NTuple{N,Int64},vect::Array{T}) where {N,T} = ones(T,sizes).*vect
same(sizes::NTuple{N,Int64},vect::CUDA.CuArray{T}) where {N,T} = CUDA.ones(T,sizes).*vect

function pad(array::A,padding::NTuple{2,Int64},fun::typeof(same)) where A<:AbstractArray{<:AbstractFloat, 4}
    div_result = padding./2
    leftpad = Int64.(floor.(div_result))
    rightpad = Int64.(ceil.(div_result))
    if padding[1]!=0
        accum = Vector{A}(undef,0)
        for i in 1:size(array,3)
            temp_array = array[:,:,i,:,:]
            vec1 = collect(temp_array[1,:]')
            vec2 = collect(temp_array[end,:]')
            s_ar2 = size(temp_array,2)
            s1 = (leftpad[1],s_ar2,1,1)
            s2 = (rightpad[1],s_ar2,1,1)
            output_array = vcat(fun(s1,vec1),temp_array,fun(s2,vec2))
            push!(accum,output_array)
        end
        final_array = reduce(cat3,accum)
    else
        final_array = array
    end
    if padding[2]!=0
        accum = Vector{A}(undef,0)
        for i in 1:size(final_array,3)   
            temp_array = final_array[:,:,i,:,:]
            vec1 = temp_array[:,1]
            vec2 = temp_array[:,end]
            s_ar1 = size(temp_array,1)
            s1 = (s_ar1,leftpad[2],1,1)
            s2 = (s_ar1,rightpad[2],1,1)
            output_array = hcat(fun(s1,vec1),temp_array,fun(s2,vec2))
            push!(accum,output_array)
        end
        final_array = reduce(cat3,accum)
    end
    return final_array
end

function pad(array::A,padding::NTuple{2,Int64},
        fun::Union{typeof(zeros),typeof(ones)}) where {T<:AbstractFloat,A<:AbstractArray{T, 4}}
    div_result = padding./2
    leftpad = Int64.(floor.(div_result))
    rightpad = Int64.(ceil.(div_result))
    if padding[1]!=0
        accum = Vector{A}(undef,0)
        for i in 1:size(array,3)
            temp_array = array[:,:,i,:,:]
            s_ar2 = size(temp_array,2)
            s1 = (leftpad[1],s_ar2,1,1)
            s2 = (rightpad[1],s_ar2,1,1)
            output_array = vcat(fun(T,s1),temp_array,fun(T,s2))
            push!(accum,output_array)
        end
        final_array = reduce(cat3,accum)
    else
        final_array = array
    end
    if padding[2]!=0
        accum = Vector{A}(undef,0)
        for i in 1:size(final_array,3)   
            temp_array = final_array[:,:,i,:,:]
            s_ar1 = size(temp_array,1)
            s1 = (s_ar1,leftpad[2],1,1)
            s2 = (s_ar1,rightpad[2],1,1)
            output_array = hcat(fun(T,s1),temp_array,fun(T,s2))
            push!(accum,output_array)
        end
        final_array = reduce(cat3,accum)
    end
    return final_array
end

function conn(num::Int64)
    if num==4
        kernel = [false true false
                  true true true
                  false true false]
    else
        kernel = [true true true
                  true true true
                  true true true]
    end
    return kernel
end

# Imports images using urls
function load_images(urls::Vector{String})
    num = length(urls)
    imgs = Vector{Array{RGB{N0f8},2}}(undef,num)
    for i = 1:num
        imgs[i] = load_image(urls[i])
    end
    return imgs
end

function load_images(urls::Vector{String},channel::Channel)
    num = length(urls)
    imgs = Vector{Array{RGB{N0f8},2}}(undef,num)
    for i = 1:num
        imgs[i] = load_image(urls[i])
        put!(channel,1)
    end
    return imgs
end

# Imports image
function load_image(url::String)
    img::Array{RGB{N0f8},2} = load(url)
    return img
end

# Convert images to grayscale Array{Float32,2}
function image_to_gray_float(image::Array{RGB{Normed{UInt8,8}},2})
    img_temp = channelview(float.(Gray.(image)))
    return collect(reshape(img_temp,size(img_temp)...,1))
end

# Convert images to RGB Array{Float32,3}
function image_to_color_float(image::Array{RGB{Normed{UInt8,8}},2})
    img_temp = permutedims(channelview(float.(image)),[2,3,1])
    return collect(img_temp)
end

# Convert images to BitArray{3}
function label_to_bool(labelimg::Array{RGB{Normed{UInt8,8}},2}, class_inds::Vector{Int64},
        labels_color::Vector{Vector{Float64}},labels_incl::Vector{Vector{Int64}},
        border::Vector{Bool},border_thickness::Vector{Int64})
    colors = map(x->RGB((n0f8.(./(x,255)))...),labels_color)
    num = length(class_inds)
    num_borders = sum(border)
    inds_borders = findall(border)
    label = fill!(BitArray{3}(undef, size(labelimg)...,
        num + num_borders),0)
    # Find classes based on colors
    for i in class_inds
        colors_current = [colors[i]]
        inds = findall(map(x->issubset(i,x),labels_incl))
        if !isempty(class_inds)
            push!(colors_current,colors[inds]...)
        end
        bitarrays = map(x -> .==(labelimg,x),colors_current)
        label[:,:,i] = any(reduce(cat3,bitarrays),dims=3)
    end
    # Make classes outlining object borders
    for j=1:length(inds_borders)
        ind = inds_borders[j]
        dil = dilate(outer_perim(label[:,:,ind]),border_thickness[ind])
        label[:,:,num+j] = dil
    end
    return label
end