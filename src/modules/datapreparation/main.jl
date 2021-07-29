

#----------------------------------------------------------------

# Allows to write to data from GUI
function set_model_data_main(model_data::ModelData,field,value)
    field_string::String = fix_QML_types(field)
    value_string::String = fix_QML_types(value)
    field = Symbol(field_string)
    value = Symbol(value_string)
    values = getproperty(model_data, field)
    if !(value in values)
        push!(values,value)
    end
    return nothing
end
set_model_data(field,values) = set_model_data_main(model_data,field,values)

function get_model_data_main(model_data::ModelData,field,value)
    field_string = fix_QML_types(field)
    value_string = fix_QML_types(value)
    field = Symbol(field_string)
    values_string = string.(getproperty(model_data, field))
    if value_string in values_string
        return true
    else
        return false
    end
end
get_model_data(field,value) = get_model_data_main(model_data,field,value)

function rm_model_data_main(model_data::ModelData,field,value)
    field_string = fix_QML_types(field)
    value_string = fix_QML_types(value)
    field = Symbol(field_string)
    values = getproperty(model_data, field)
    values_string = string.(values)
    ind = findall(value_string.==values_string)
    if !isempty(ind)
        deleteat!(values,ind)
    end
    return nothing
end
rm_model_data(field,value) = rm_model_data_main(model_data,field,value)


#---get_urls functions------------------------------------------------------

function get_urls_main(model_data::ModelData,preparation_data::PreparationData)
    if isempty(model_data.classes)
        @error "Classes are empty."
        return nothing
    end
    remove_urls()
    url_inputs = preparation_data.Urls.url_inputs
    url_labels = preparation_data.Urls.url_labels
    if input_type()==:image
        allowed_ext = ["png","jpg","jpeg"]
    end
    if problem_type()==:classification
        classification_data = preparation_data.ClassificationData
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
            return classification_data.Urls
        end
    elseif problem_type()==:regression
        regression_data = preparation_data.RegressionData
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
            return regression_data.Urls
        end
    elseif problem_type()==:segmentation
        segmentation_data = preparation_data.SegmentationData
        input_urls_raw,label_urls_raw,_,_,_ = get_urls2(url_inputs,url_labels,allowed_ext)
        input_urls = reduce(vcat,input_urls_raw)
        label_urls = reduce(vcat,label_urls_raw)
        if isempty(input_urls)
            @warn "The folder did not have any suitable data."           
        else
            segmentation_data.Urls.input_urls = input_urls
            segmentation_data.Urls.label_urls = label_urls
            return segmentation_data.Urls
        end
    end
    return nothing
end


#---prepare_data functions-------------------------------------------------------------------

# Removes rows and columns from image sides if they are uniformly black.
function crop_background(img::Array{Float32,3},label::BitArray{3},
        threshold::Float64,closing_value::Int64)
    img_temp = mean(img,dims=3)[:,:]
    field = imfilter(img_temp.<threshold, Kernel.gaussian(4)).>0.5
    field = closing!(field,closing_value)
    row_bool = (!).(alldim(field,1))
    col_bool = (!).(alldim(field,2))
    col1 = findfirst(col_bool)
    col2 = findlast(col_bool)
    row1 = findfirst(row_bool)
    row2 = findlast(row_bool)
    col1 = isnothing(col1) ? 1 : col1
    col2 = isnothing(col2) ? size(img,1) : col2
    row1 = isnothing(row1) ? 1 : row1
    row2 = isnothing(row2) ? size(img,2) : row2
    img = img[row1:row2,col1:col2,:]
    label = label[row1:row2,col1:col2,:]
    return img,label
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

function apply_normalization(model_data::ModelData,data::Vector{Array{Float32,N}}) where N
    model_data.normalization.args = (model_data.normalization.f(data)...,)
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
            if :grayscale in model_data.input_properties
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
    # Normalize
    apply_normalization(model_data,data_input_flat)
    # Return results
    classification_data.Data.data_input = data_input_flat
    classification_data.Data.data_labels = data_label_flat
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
        if :grayscale in model_data.input_properties
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
    # Normalize
    apply_normalization(model_data,data_input_flat)
    # Return results
    regression_data.Data.data_input = data_input_flat
    regression_data.Data.data_labels = data_label_flat
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
        if :grayscale in model_data.input_properties
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
    # Normalize
    apply_normalization(model_data,data_input_flat)
    # Return results
    segmentation_data.Data.data_input = data_input_flat
    segmentation_data.Data.data_labels = data_label_flat
    # Return progress
    put!(progress, 1)
    return nothing
end

function prepare_data_main(model_data::ModelData,
        preparation_data::PreparationData,channels::Channels)
    # Initialize
    data_preparation_options = options.DataPreparationOptions
    size12 = model_data.input_size[1:2]
    if problem_type()==:classification
        data = preparation_data.ClassificationData
    elseif problem_type()==:regression
        data = preparation_data.RegressionData
    else # problem_type()==:segmentation
        data = preparation_data.SegmentationData
    end
    progress = channels.data_preparation_progress
    t = Threads.@spawn prepare_data(model_data,data,size12,data_preparation_options,progress)
    push!(preparation_data.tasks,t)
    return t
end