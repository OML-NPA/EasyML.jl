
#---make_classes functions---------------------------------------

function set_problem_type(ind)
    ind = fix_QML_types(ind)
    if ind==0 
        model_data.problem_type = :Classification
    elseif ind==1
        model_data.problem_type = :Regression
    elseif ind==2
        model_data.problem_type = :Segmentation
    end
    return nothing
end

function get_problem_type()
    if problem_type()==:Classification
        return 0
    elseif problem_type()==:Regression
        return 1
    elseif problem_type()==:Segmentation
        return 2
    end
end

function reset_classes_main(model_data)
    if problem_type()==:Classification
        model_data.classes = Vector{ImageClassificationClass}(undef,0)
    elseif problem_type()==:Regression
        model_data.classes = Vector{ImageRegressionClass}(undef,0)
    elseif problem_type()==:Segmentation
        model_data.classes = Vector{ImageSegmentationClass}(undef,0)
    end
    return nothing
end
reset_classes() = reset_classes_main(model_data::ModelData)

function append_classes_main(model_data::ModelData,data)
    data = fix_QML_types(data)
    type = eltype(model_data.classes)
    if problem_type()==:Classification
        class = ImageClassificationClass()
        class.name = data[1]
    elseif problem_type()==:Regression
        class = ImageRegressionClass()
        class.name = data[1]
    elseif problem_type()==:Segmentation
        class = ImageSegmentationClass()
        class.name = String(data[1])
        class.color = Int64.([data[2],data[3],data[4]])
        class.parents = data[5]
        class.overlap = Bool(data[6])
        class.BorderClass.enabled = Bool(data[7])
        class.BorderClass.thickness = Int64(data[8])
    end
    push!(model_data.classes,class)
    return nothing
end
append_classes(data) = append_classes_main(model_data,data)

function num_classes_main(model_data::ModelData)
    return length(model_data.classes)
end
num_classes() = num_classes_main(model_data::ModelData)

function get_class_main(model_data::ModelData,index,fieldname)
    fieldname = fix_QML_types(fieldname)
    index = Int64(index)
    if fieldname isa Vector
        fieldnames = Symbol.(fieldname)
        data = model_data.classes[index]
        for field in fieldnames
            data = getproperty(data,field)
        end
        return data
    else
        return getfield(model_data.classes[index],Symbol(fieldname))
    end
end
get_class_field(index,fieldname) = get_class_main(model_data,index,fieldname)


#---get_urls functions------------------------------------------------------

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

function intersect_inds(ar1,ar2)
    inds1 = Array{Int64,1}(undef, 0)
    inds2 = Array{Int64,1}(undef, 0)
    for i=1:length(ar1)
        inds_log = ar2.==ar1[i]
        if any(inds_log)
            push!(inds1,i)
            push!(inds2,findfirst(inds_log))
        end
    end
    return (inds1, inds2)
end

function get_urls_main(model_data::ModelData,prepared_data::PreparedData)
    url_inputs = prepared_data.url_inputs
    url_labels = prepared_data.url_labels
    if input_type()==:Image
        allowed_ext = ["png","jpg","jpeg"]
    end
    if problem_type()==:Classification
        classification_data = prepared_data.ClassificationData
        input_urls,dirs,_ = get_urls1(url_inputs,allowed_ext)
        labels = map(class -> class.name,model_data.classes)
        dirs_raw = intersect(dirs,labels)
        intersection_bool = map(x-> x in labels,dirs_raw)
        if sum(intersection_bool)!=length(labels)
            inds = findall((!).(intersection_bool))
            for i in inds
                @warn string(dirs_raw[i]," is not a name of one of the labels. The folder was ignored.")
            end
            dirs = dirs_raw[inds]
            input_urls = input_urls[inds]
        else
            dirs = dirs_raw
            input_urls = input_urls
        end
        if isempty(input_urls)
            @warn "The folder did not have any suitable data."           
        else
            classification_data.Urls.input_urls = input_urls
            classification_data.Urls.label_urls = dirs
        end
    elseif problem_type()==:Regression
        regression_data = prepared_data.RegressionData
        input_urls_raw,_,filenames_inputs_raw = get_urls1(url_inputs,allowed_ext)
        input_urls = reduce(vcat,input_urls_raw)
        filenames_inputs = reduce(vcat,filenames_inputs_raw)
        filenames_labels,loaded_labels = load_regression_data(url_labels)
        intersect_regression_data!(input_urls,filenames_inputs,loaded_labels,filenames_labels)
        if isempty(input_urls)
            @warn "The folder did not have any suitable data."
        else
            regression_data.Urls.input_urls = input_urls
            regression_data.Urls.labels_url = url_labels
            regression_data.Urls.initial_data_labels = loaded_labels
        end
    elseif problem_type()==:Segmentation
        segmentation_data = prepared_data.SegmentationData
        input_urls_raw,label_urls_raw,_,_,_ = get_urls2(url_inputs,url_labels,allowed_ext)
        input_urls = reduce(vcat,input_urls_raw)
        label_urls = reduce(vcat,label_urls_raw)
        if isempty(input_urls)
            @warn "The folder did not have any suitable data."           
        else
            segmentation_data.Urls.input_urls = input_urls
            segmentation_data.Urls.label_urls = label_urls
        end
    end
    return nothing
end


#---prepare_data functions-------------------------------------------------------------------

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
        if !classes[i].overlap
            push!(class_inds,i)
        end
    end
    num = length(class_inds)
    border = Vector{Bool}(undef,num)
    border_thickness = Vector{Int64}(undef,num)
    for i in class_inds
        class = classes[i]
        border[i] = class.BorderClass.enabled
        border_thickness[i] = class.BorderClass.thickness
    end
    return class_inds,labels_color,labels_incl,border,border_thickness
end


# Augments images and labels using rotation and mirroring
function augment(float_img::Array{Float32,3},size12::Tuple{Int64,Int64},
        num_angles::Int64,mirroring_inds::Vector{Int64})
    data = Vector{Array{Float32,3}}(undef,0)
    angles_range = range(0,stop=2*pi,length=num_angles+1)
    angles = collect(angles_range[1:end-1])
    num = length(angles)
    for g = 1:num
        angle_val = angles[g]
        img2 = rotate_img(float_img,angle_val)
        size1_adj = size12[1]*0.9
        size2_adj = size12[2]*0.9
        num1 = Int64(floor(size(img2,1)/size1_adj))
        num2 = Int64(floor(size(img2,2)/size2_adj))
        step1 = Int64(floor(size1_adj/num1))
        step2 = Int64(floor(size2_adj/num2))
        num1 = max(num1-1,1)
        num2 = max(num2-1,1)
        for i = 1:num1
            for j = 1:num2
                ymin = (i-1)*step1+1
                xmin = (j-1)*step2+1
                I1 = img2[ymin:ymin+size12[1]-1,xmin:xmin+size12[2]-1,:]
                if std(I1)<0.01
                    continue
                else
                    for h in mirroring_inds
                        if h==1
                            I1_out = I1
                        else
                            I1_out = reverse(I1, dims = 2)
                        end
                        data_out = I1_out
                        if !isassigned(data_out)
                            return nothing
                        end
                        push!(data,data_out)
                    end
                end
            end
        end
    end
    return data
end

# Augments images and labels using rotation and mirroring
function augment(float_img::Array{Float32,3},label::BitArray{3},size12::Tuple{Int64,Int64},
        num_angles::Int64,min_fr_pix::Float64,mirroring_inds::Vector{Int64})
    data = Vector{Tuple{Array{Float32,3},BitArray{3}}}(undef,0)
    lim = prod(size12)*min_fr_pix
    angles_range = range(0,stop=2*pi,length=num_angles+1)
    angles = collect(angles_range[1:end-1])
    num = length(angles)
    for g = 1:num
        angle_val = angles[g]
        img2 = rotate_img(float_img,angle_val)
        label2 = rotate_img(label,angle_val)
        size1_adj = size12[1]*0.9
        size2_adj = size12[2]*0.9
        num1 = Int64(floor(size(img2,1)/size1_adj))
        num1 = max(num1,1)
        num2 = Int64(floor(size(img2,2)/size2_adj))
        num2 = max(num2,1)
        step1 = Int64(floor(size(img2,1)/num1))
        step2 = Int64(floor(size(img2,2)/num2))
        num1 = max(num1-1,1)
        num2 = max(num2-1,1)
        for i in 1:num1
            for j in 1:num2
                ymin = (i-1)*step1+1
                xmin = (j-1)*step2+1
                I1 = img2[ymin:ymin+size12[1]-1,xmin:xmin+size12[2]-1,:]
                I2 = label2[ymin:ymin+size12[1]-1,xmin:xmin+size12[2]-1,:]
                if std(I1)<0.01 || sum(I2)<lim
                    continue
                else
                    for h in mirroring_inds
                        if h==1
                            I1_out = I1
                            I2_out = I2
                        elseif h==2
                            I1_out = reverse(I1, dims = 2)
                            I2_out = reverse(I2, dims = 2)
                        end
                        data_out = (I1_out,I2_out)
                        push!(data,data_out)
                    end
                end
            end
        end
    end
    return data
end

function prepare_data(model_data::ModelData,classification_data::ClassificationData,
        size12::Tuple{Int64,Int64},data_preparation_options::DataPreparationOptions,
        progress::Channel)
    num_angles = data_preparation_options.Images.num_angles
    mirroring_inds = Vector{Int64}(undef,0)
    if data_preparation_options.Images.mirroring
        append!(mirroring_inds,[1,2])
    else
        push!(mirroring_inds,1)
    end
    input_urls = classification_data.Urls.input_urls
    label_urls = classification_data.Urls.label_urls
    labels = map(class -> class.name, model_data.classes)
    data_labels_initial = map((label,l) -> repeat([findfirst(label.==labels)],l),label_urls,length.(input_urls))
    num = length(input_urls)
    # Get number of images
    num_all = sum(length.(input_urls))
    # Return progress target value
    put!(progress, 2*num_all + 1)
    # Load images
    imgs = map(x -> load_images(x,progress),input_urls)
    # Initialize accumulators
    data_input = Vector{Vector{Array{Float32,3}}}(undef,num)
    data_label = Vector{Vector{Int32}}(undef,num)
    chunk_size = convert(Int64,round(num/num_threads()))
    @floop ThreadedEx(basesize = chunk_size) for k = 1:num
        current_imgs = imgs[k]
        num2 = length(current_imgs)
        label = data_labels_initial[k]
        data_input_temp = Vector{Vector{Array{Float32,3}}}(undef,num2)
        data_label_temp = Vector{Vector{Int32}}(undef,num2)
        for l = 1:num2
            # Abort if requested
            #if check_abort_signal(channels.data_preparation_modifiers)
            #    return nothing
            #end
            # Get a current image
            img_raw = current_imgs[l]
            # Convert to float
            if data_preparation_options.Images.grayscale
                img = image_to_gray_float(img_raw)
            else
                img = image_to_color_float(img_raw)
            end
            # Augment images
            data = augment(img,size12,num_angles,mirroring_inds)
            data_input_temp[l] = data
            data_label_temp[l] = repeat([label[l]],length(data))
            # Return progress
            put!(progress, 1)
        end
        data_input_flat_temp = reduce(vcat,data_input_temp)
        data_label_flat_temp = reduce(vcat,data_label_temp)
        data_input[k] = data_input_flat_temp
        data_label[k] = data_label_flat_temp
    end
    # Flatten input images and labels array
    data_input_flat = reduce(vcat,data_input)
    data_label_flat = reduce(vcat,data_label)
    # Return results
    classification_data.Results.data_input = data_input_flat
    classification_data.Results.data_labels = data_label_flat
    # Return progress
    put!(progress, 1)
    return nothing
end

function prepare_data(model_data::ModelData,regression_data::RegressionData,
        size12::Tuple{Int64,Int64},data_preparation_options::DataPreparationOptions,
        progress::Channel)
    input_size = model_data.input_size
    num_angles = data_preparation_options.Images.num_angles
    mirroring_inds = Vector{Int64}(undef,0)
    if data_preparation_options.Images.mirroring
        append!(mirroring_inds,[1,2])
    else
        push!(mirroring_inds,1)
    end
    input_urls = regression_data.Urls.input_urls
    initial_label_data = copy(regression_data.Urls.initial_data_labels)
    # Get number of images
    num = length(input_urls)
    # Return progress target value
    put!(progress, 2*num+1)
    num = length(input_urls)
    # Load images
    imgs = load_images(input_urls,progress)
    # Initialize accumulators
    data_input = Vector{Vector{Array{Float32,3}}}(undef,num)
    data_label = Vector{Vector{Vector{Float32}}}(undef,num)
    chunk_size = convert(Int64,round(num/num_threads()))
    @floop ThreadedEx(basesize = chunk_size) for k = 1:num
        # Abort if requested
        #if check_abort_signal(channels.data_preparation_modifiers)
        #    return nothing
        #end
        # Get a current image
        img_raw = imgs[k]
        img_raw = imresize(img_raw,input_size[1:2])
        # Get current label
        label = initial_label_data[k]
        # Convert to float
        if data_preparation_options.Images.grayscale
            img = image_to_gray_float(img_raw)
        else
            img = image_to_color_float(img_raw)
        end
        # Augment images
        temp_input = augment(img,size12,num_angles,mirroring_inds)
        temp_label = repeat([label],length(temp_input))
        data_input[k] = temp_input
        data_label[k] = temp_label
        # Return progress
        put!(progress, 1)
    end
    # Flatten input images and labels array
    data_input_flat = reduce(vcat,data_input)
    data_label_flat = reduce(vcat,data_label)
    # Return results
    regression_data.Results.data_input = data_input_flat
    regression_data.Results.data_labels = data_label_flat
    # Return progress
    put!(progress, 1)
    return nothing
end

function prepare_data(model_data::ModelData,segmentation_data::SegmentationData,
        size12::Tuple{Int64,Int64},data_preparation_options::DataPreparationOptions,
        progress::Channel)
    classes = model_data.classes
    min_fr_pix = data_preparation_options.Images.min_fr_pix
    num_angles = data_preparation_options.Images.num_angles
    background_cropping = data_preparation_options.Images.BackgroundCropping
    mirroring_inds = Vector{Int64}(undef,0)
    if data_preparation_options.Images.mirroring
        append!(mirroring_inds,[1,2])
    else
        push!(mirroring_inds,1)
    end
    input_urls = segmentation_data.Urls.input_urls
    label_urls = segmentation_data.Urls.label_urls
    # Get number of images
    num = length(input_urls)
    # Return progress target value
    put!(progress, 3*num+1)
    # Get class data
    class_inds,labels_color,labels_incl,border,border_thickness = get_class_data(classes)
    border_num = (border_thickness.-1).÷2
    # Load images
    imgs = load_images(input_urls,progress)
    labels = load_images(label_urls,progress)
    # Initialize accumulators
    data_input = Vector{Vector{Array{Float32,3}}}(undef,num)
    data_label = Vector{Vector{Array{Float32,3}}}(undef,num)
    # Make input images
    chunk_size = convert(Int64,round(num/num_threads()))
    @floop ThreadedEx(basesize = chunk_size) for k = 1:num
        # Abort if requested
        #if check_abort_signal(channels.data_preparation_modifiers)
        #    return nothing
        #end
        # Get current images
        img_raw = imgs[k]
        labelimg = labels[k]
        # Convert to float
        if data_preparation_options.Images.grayscale
            img = image_to_gray_float(img_raw)
        else
            img = image_to_color_float(img_raw)
        end
        # Convert an image to BitArray
        label = label_to_bool(labelimg,class_inds,labels_color,labels_incl,border,border_num)
        # Crop to remove black background
        if background_cropping.enabled
            threshold = background_cropping.threshold
            closing_value = background_cropping.closing_value
            img,label = crop_background(img,label,threshold,closing_value)
        end
        # Augment images
        data = augment(img,label,size12,num_angles,min_fr_pix,mirroring_inds)
        data_input[k] = getfield.(data, 1)
        data_label[k] = getfield.(data, 2)
        # Return progress
        put!(progress, 1)
    end
    # Flatten input images and labels array
    data_input_flat = reduce(vcat,data_input)
    data_label_flat = reduce(vcat,data_label)
    # Return results
    segmentation_data.Results.data_input = data_input_flat
    segmentation_data.Results.data_labels = data_label_flat
    # Return progress
    put!(progress, 1)
    return nothing
end

function prepare_data_main(model_data::ModelData,
        prepared_data::PreparedData,channels::Channels)
    # Initialize
    data_preparation_options = options.DataPreparationOptions
    size12 = model_data.input_size[1:2]
    if problem_type()==:Classification
        data = prepared_data.ClassificationData
    elseif problem_type()==:Regression
        data = prepared_data.RegressionData
    elseif problem_type()==:Segmentation
        data = prepared_data.SegmentationData
    end
    progress = channels.data_preparation_progress
    t = Threads.@spawn prepare_data(model_data,data,size12,data_preparation_options,progress)
    push!(prepared_data.tasks,t)
    return t
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
        border::Vector{Bool},border_num::Vector{Int64})
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
        bitarrays = map(x -> .==(labelimg,x)[:,:,:],colors_current)
        label[:,:,i] = any(reduce(cat3,bitarrays),dims=3)
    end
    # Make classes outlining object borders
    for j=1:length(inds_borders)
        ind = inds_borders[j]
        border = outer_perim(label[:,:,ind])
        dilate!(border,border_num[ind])
        label[:,:,num+j] = border
    end
    return label
end


#---Other-----------------------------------------------------------

function remove_ext(files::Vector{String})
    filenames = copy(files)
    for i=1:length(files)
        chars = collect(files[i])
        ind = findfirst(chars.=='.')
        filenames[i] = String(chars[1:ind-1])
    end
    return filenames
end

cat3(A::AbstractArray, B::AbstractArray) = cat(A, B; dims=Val(3))

function replace_nan!(x)
    type = eltype(x)
    for i = eachindex(x)
        if isnan(x[i])
            x[i] = zero(type)
        end
    end
end

