
# Get urls of files in selected folders. Requires only data
function get_urls1(settings::Union{Training,Validation,Application},allowed_ext::Vector{String})
    # Get a reference to url accumulators
    input_urls = Vector{Vector{String}}(undef,0)
    filenames = Vector{Vector{String}}(undef,0)
    # Empty a url accumulator
    empty!(input_urls)
    # Get directories containing data and labels
    input_dir = settings.input_dir
    # Return if no directories
    if isempty(input_dir)
        @warn "Directory is empty."
        return nothing
    end
    # Get directories containing our images and labels
    dirs = getdirs(input_dir)
    # If no directories, then set empty string
    if length(dirs)==0
        dirs = [""]
    end
    # Collect urls
    for k = 1:length(dirs)
        input_urls_temp = Vector{String}(undef,0)
        dir = dirs[k]
        # Get files in a directory
        files_input = getfiles(string(input_dir,"/",dir))
        files_input = filter_ext(files_input,allowed_ext)
        # Push urls into an accumulator
        for l = 1:length(files_input)
            push!(input_urls_temp,string(input_dir,"/",dir,"/",files_input[l]))
        end
        push!(filenames,files_input)
        push!(input_urls,input_urls_temp)
    end
    if dirs==[""]
        url_split = split(input_dir,"/")
        dirs = [url_split[end]]
    end
    return input_urls,dirs,filenames
end

# Get urls of files in selected folders. Requires data and labels
function get_urls2(settings::Union{Training,Validation},allowed_ext::Vector{String})
    # Get a reference to url accumulators
    input_urls = Vector{Vector{String}}(undef,0)
    label_urls = Vector{Vector{String}}(undef,0)
    filenames = Vector{Vector{String}}(undef,0)
    fileindices = Vector{Vector{Int64}}(undef,0)
    # Empty url accumulators
    empty!(input_urls)
    empty!(label_urls)
    # Get directories containing images and labels
    input_dir = settings.input_dir
    label_dir = settings.label_dir
    # Return if no directories
    if isempty(input_dir) || isempty(label_dir)
        @error "Empty urls."
        return nothing,nothing,nothing
    end
    # Get directories containing our images and labels
    dirs_input= getdirs(input_dir)
    dirs_labels = getdirs(label_dir)
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
        files_input = getfiles(string(input_dir,"/",dirs[k]))
        files_labels = getfiles(string(label_dir,"/",dirs[k]))
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
            push!(input_urls_temp,string(input_dir,"/",files_input[l]))
            push!(label_urls_temp,string(label_dir,"/",files_labels[l]))
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
    labels_info = DataFrame(CSVFiles.load(url))
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

# Imports images using urls
function load_images(urls::Vector{String})
    num = length(urls)
    imgs = Vector{Array{RGB{N0f8},2}}(undef,num)
    for i = 1:num
        imgs[i] = load_image(urls[i])
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

# Returns color for labels, whether should be combined with other
# labels and whether border data should be obtained
function get_class_data(classes::Vector{ImageSegmentationClass})
    num = length(classes)
    class_names = Vector{String}(undef,num)
    class_parents = Vector{Vector{String}}(undef,num)
    labels_color = Vector{Vector{Float64}}(undef,num)
    labels_incl = Vector{Vector{Int64}}(undef,num)
    for i=1:num
        class = classes[i]
        class_names[i] = classes[i].name
        class_parents[i] = classes[i].parents
        labels_color[i] = class.color
    end
    for i=1:num
        labels_incl[i] = findall(any.(map(x->x.==class_parents[i],class_names)))
    end
    class_inds = Vector{Int64}(undef,0)
    for i = 1:num
        if !classes[i].not_class
            push!(class_inds,i)
        end
    end
    num = length(class_inds)
    border = Vector{Bool}(undef,num)
    border_thickness = Vector{Int64}(undef,num)
    for i in class_inds
        class = classes[i]
        border[i] = class.border
        border_thickness[i] = class.border_thickness
    end
    return class_inds,labels_color,labels_incl,border,border_thickness
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
function rotate_img(img::AbstractArray{Real,2},angle_val::Float64)
    if angle!=0
        img_out = imrotate(img,angle_val,axes(img))
        replace_nan!(img_out)
        return(img_out)
    else
        return(img)
    end
end

function rotate_img(img::AbstractArray{T,3},angle_val::Float64) where T<:AbstractFloat
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

function rotate_img(img::BitArray{3},angle_val::Float64)
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
function apply_border_data(data_in::BitArray{3},classes::Vector{ImageSegmentationClass})
    class_inds,_,_,border,border_thickness = get_class_data(classes)
    inds_border = findall(border)
    if isnothing(inds_border)
        return data_in
    end
    num_border = length(inds_border)
    num_feat = length(class_inds)
    data = BitArray{3}(undef,size(data_in)[1:2]...,num_border)
    for i = 1:num_border #@floop ThreadedEx() 
        border_num_pixels = border_thickness[i]
        ind_feat = inds_border[i]
        ind_border = num_feat + ind_feat
        data_feat_bool = data_in[:,:,ind_feat]
        data_feat = convert(Array{Float32},data_feat_bool)
        data_border = data_in[:,:,ind_border]
        border_bool = data_border
        background1 = erode(data_feat_bool .& border_bool,border_num_pixels)
        background2 = outer_perim(border_bool)
        background2[data_feat_bool] .= false
        background2 = dilate(background2,border_num_pixels+1)
        background = background1 .| background2
        skel = thinning(border_bool)
        background[skel] .= true
        if classes[i].border_remove_objs
            components = label_components((!).(border_bool),conn(4))
            intensities = component_intensity(components,data_feat)
            bad_components = findall(intensities.<0.7)
            for i = 1:length(bad_components)
                components[components.==bad_components[i]] .= 0
            end
            objects = data_feat.!=0
            objects[skel] .= false
            segmented = segment_objects(components,objects)
            borders = mapwindow(x->!allequal(x), segmented, (3,3))
            segmented[borders] .= 0
            data[:,:,ind_feat] = segmented.>0
        else
            data_feat_bool[background] .= false
            data[:,:,i] = data_feat_bool
        end
    end
    return data
end

#---
function accuracy_classification(predicted::A,actual::A) where {T<:Float32,A<:AbstractArray{T,2}}
    acc = Vector{Float32}(undef,0)
    for i in 1:size(predicted,2)
        _ , actual_ind = findmax(actual[1,i])
        _ , predicted_ind = findmax(predicted[1,i])
        if actual_ind==predicted_ind
            push!(acc,1)
        else
            push!(acc,0)
        end
    end
    return mean(acc)
end

function accuracy_regression(predicted::A,actual::A) where {T<:Float32,A<:AbstractArray{T,2}}
    err = abs.(actual .- predicted)
    err_relative = mean(err./actual)
    if err_relative>0.5f0
        acc = 0.25f0/err_relative
    else
        acc = 1f0 - err_relative
    end
    return acc
end

function accuracy_segmentation(predicted::A,actual::A) where {T<:Float32,A<:AbstractArray{T,4}}
    # Convert to BitArray
    actual_bool = actual.>0
    predicted_bool = predicted.>0.5
    # Calculate accuracy
    correct_bool = predicted_bool .& actual_bool
    num_correct = convert(Float32,sum(correct_bool))
    acc = num_correct/prod(size(predicted)[1:2])
    return acc
end

# Weight accuracy using inverse frequency
function accuracy_segmentation_weighted(predicted::A,actual::A) where {T<:Float32,A<:AbstractArray{T,4}}
    # Get input dimensions
    array_size = size(actual)
    array_size12 = array_size[1:2]
    num_feat = array_size[3]
    num_batch = array_size[4]
    # Convert to BitArray
    actual_bool = actual.>0
    predicted_bool = predicted.>0.5
    # Calculate correct and incorrect class pixels as a BitArray
    correct_bool = predicted_bool .& actual_bool
    dif_bool = xor.(predicted_bool,actual_bool)
    # Calculate correct and incorrect background pixels as a BitArray
    correct_background_bool = (!).(dif_bool .| actual_bool)
    dif_background_bool = dif_bool-actual_bool
    # Number of elements
    numel = prod(array_size12)
    # Count number of class pixels
    pix_sum::Array{Float32,4} = collect(sum(actual_bool,dims=(1,2,4)))
    pix_sum_perm = permutedims(pix_sum,[3,1,2,4])
    class_counts = pix_sum_perm[:,1,1,1]
    # Calculate weight for each pixel
    fr = class_counts./numel./num_batch
    w = 1 ./fr
    w2 = 1 ./(1 .- fr)
    w_sum = w + w2
    w = w./w_sum
    w2 = w2./w_sum
    w_adj = w./class_counts
    w2_adj = w2./(numel*num_batch .- class_counts)
    # Initialize vectors for storing accuracies
    classes_accuracy = Vector{Float32}(undef,num_feat)
    background_accuracy = Vector{Float32}(undef,num_feat)
    # Calculate accuracies
    for i = 1:num_feat
        # Calculate accuracy for a class
        sum_correct = sum(correct_bool[:,:,i,:])
        sum_dif = sum(dif_bool[:,:,i,:])
        sum_comb = sum_correct*sum_correct/(sum_correct+sum_dif)
        classes_accuracy[i] = w_adj[i]*sum_comb
        # Calculate accuracy for a background
        sum_correct = sum(correct_background_bool[:,:,i,:])
        sum_dif = sum(dif_background_bool[:,:,i,:])
        sum_comb = sum_correct*sum_correct/(sum_correct+sum_dif)
        background_accuracy[i] = w2_adj[i]*sum_comb
    end
    # Calculate final accuracy
    acc = mean(classes_accuracy+background_accuracy)
    if acc>1.0
        acc = 1.0f0
    end
    return acc
end

# Returns an accuracy function
function get_accuracy_func(training::Training)
    if settings.problem_type==:Classification
        return accuracy_classification
    elseif settings.problem_type==:Regression
        return accuracy_regression
    elseif settings.problem_type==:Segmentation
        if training.Options.General.weight_accuracy
            return accuracy_segmentation_weighted
        else
            return accuracy_segmentation
        end
    end
end

#--- Applying a neural network
# Getting a slice and its information
function prepare_data(input_data::Union{Array{Float32,4},CuArray{Float32,4}},ind_max::Int64,
        max_value::Int64,offset::Int64,num_parts::Int64,ind_split::Int64,j::Int64)
    start_ind = 1 + (j-1)*ind_split
    if j==num_parts
        end_ind = max_value
    else
        end_ind = start_ind + ind_split-1
    end
    correct_size = end_ind-start_ind+1
    start_ind = start_ind - offset
    start_ind = start_ind<1 ? 1 : start_ind
    end_ind = end_ind + offset
    end_ind = end_ind>max_value ? max_value : end_ind
    temp_data = input_data[:,start_ind:end_ind,:,:]
    max_dim_size = size(temp_data,ind_max)
    offset_add = Int64(ceil(max_dim_size/16)*16) - max_dim_size
    temp_data = pad(temp_data,(0,offset_add),same)
    output_data = (temp_data,correct_size,offset_add)
    return output_data
end

# Makes output mask to have a correct size for stiching
function fix_size(temp_predicted::Union{Array{Float32,4},CuArray{Float32,4}},
        num_parts::Int64,correct_size::Int64,ind_max::Int64,
        offset_add::Int64,j::Int64)
    temp_size = size(temp_predicted,ind_max)
    offset_temp = (temp_size - correct_size) - offset_add
    if offset_temp>0
        div_result = offset_add/2
        offset_add1 = Int64(floor(div_result))
        offset_add2 = Int64(ceil(div_result))
        if j==1
            temp_predicted = temp_predicted[:,
                (1+offset_add1):(end-offset_temp-offset_add2),:,:]
        elseif j==num_parts
            temp_predicted = temp_predicted[:,
                (1+offset_temp+offset_add1):(end-offset_add2),:,:]
        else
            temp = (temp_size - correct_size - offset_add)/2
            offset_temp = Int64(floor(temp))
            offset_temp2 = Int64(ceil(temp))
            temp_predicted = temp_predicted[:,
                (1+offset_temp+offset_add1):(end-offset_temp2-offset_add2),:,:]
        end
    elseif offset_temp<0
        throw(DomainError("offset_temp should be greater or equal to zero"))
    end
end

# Accumulates and stiches slices (CPU)
function accum_parts(model::Chain,input_data::Array{Float32,4},
        num_parts::Int64,offset::Int64)
    input_size = size(input_data)
    max_value = maximum(input_size)
    ind_max = findfirst(max_value.==input_size)
    ind_split = convert(Int64,floor(max_value/num_parts))
    predicted = Vector{Array{Float32,4}}(undef,0)
    for j = 1:num_parts
        temp_data,correct_size,offset_add =
            prepare_data(input_data,ind_max,max_value,num_parts,offset,ind_split,j)
        temp_predicted::Array{Float32,4} = model(temp_data)
        temp_predicted = fix_size(temp_predicted,num_parts,correct_size,ind_max,offset_add,j)
        push!(predicted,temp_predicted)
    end
    if ind_max==1
        predicted_out = reduce(vcat,predicted)
    else
        predicted_out = reduce(hcat,predicted)
    end
    return predicted_out
end

# Accumulates and stiches slices (GPU)
function accum_parts(model::Chain,input_data::CuArray{Float32,4},
        num_parts::Int64,offset::Int64)
    input_size = size(input_data)
    max_value = maximum(input_size)
    ind_max = findfirst(max_value.==input_size)
    ind_split = convert(Int64,floor(max_value/num_parts))
    predicted = Vector{CuArray{Float32,4}}(undef,0)
    for j = 1:num_parts
        temp_data,correct_size,offset_add =
            prepare_data(input_data,ind_max,max_value,offset,num_parts,ind_split,j)
        temp_predicted = model(temp_data)
        temp_predicted = fix_size(temp_predicted,num_parts,correct_size,ind_max,offset_add,j)
        push!(predicted,collect(temp_predicted))
        CUDA.unsafe_free!(temp_predicted)
    end
    if ind_max==1
        predicted_out = reduce(vcat,predicted)
    else
        predicted_out = reduce(hcat,predicted)
    end
    return predicted_out
end

# Runs data thorugh a neural network
function forward(model::Chain,input_data::Array{Float32};
        num_parts::Int64=30,offset::Int64=20,use_GPU::Bool=true)
    if use_GPU
        input_data_gpu = CuArray(input_data)
        model = move(model,gpu)
        if num_parts==1
            predicted = collect(model(input_data_gpu))
        else
            predicted = collect(accum_parts(model,input_data_gpu,num_parts,offset))
        end
    else
        if num_parts==1
            predicted = model(input_data)
        else
            predicted = accum_parts(model,input_data,num_parts,offset)
        end
    end
    return predicted
end