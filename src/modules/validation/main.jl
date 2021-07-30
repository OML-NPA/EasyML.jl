
#---Geting urls------------------------------------------------------------

function get_urls_validation_main(model_data::ModelData,
        validation_urls::ValidationUrls,validation_data::ValidationData)
    url_inputs = validation_urls.url_inputs
    url_labels = validation_urls.url_labels
    if input_type()==:image
        allowed_ext = ["png","jpg","jpeg"]
    end
    if problem_type()==:classification
        input_urls,dirs = get_urls1(url_inputs,allowed_ext)
        labels = map(class -> class.name,model_data.classes)
        if issubset(dirs,labels)
            validation_data.PlotData.use_labels = true
            labels_int = map((label,l) -> 
                repeat([findfirst(label.==labels)],l),dirs,length.(input_urls))
            validation_urls.labels_classification = reduce(vcat,labels_int)
        end
    elseif problem_type()==:regression
        input_urls_raw,_,filenames_inputs_raw = get_urls1(url_inputs,allowed_ext)
        input_urls = input_urls_raw[1]
        filenames_inputs = filenames_inputs_raw[1]
        if validation_data.PlotData.use_labels==true
            input_urls_copy = copy(input_urls)
            filenames_inputs_copy = copy(filenames_inputs)
            filenames_labels,loaded_labels = load_regression_data(validation_urls.url_labels)
            intersect_regression_data!(input_urls_copy,filenames_inputs_copy,
                loaded_labels,filenames_labels)
            if isempty(loaded_labels)
                validation_data.PlotData.use_labels = false
                @warn string("No file names in ",url_labels ," correspond to file names in ",
                    url_inputs," . Files were loaded without labels.")
            else
                validation_urls.labels_regression = loaded_labels
                input_urls = input_urls_copy
            end
        end
    else # problem_type()==:segmentation
        if validation_data.PlotData.use_labels==true
            input_urls,label_urls,_,_,_ = get_urls2(url_inputs,url_labels,allowed_ext)
            validation_urls.label_urls = reduce(vcat,label_urls)
        else
            input_urls,_ = get_urls1(url_inputs,allowed_ext)
        end
    end
    validation_urls.input_urls = reduce(vcat,input_urls)
    return nothing
end


#---Data preparation------------------------------------------------------------


function prepare_validation_data(classes::Vector{ImageClassificationClass},
        norm_func::Function,model_data::ModelData,ind::Int64,validation_data::ValidationData)
    local data_input_raw
    inds,labels_color,labels_incl,border,border_thickness = get_class_data(classes)
    original_image = load_image(validation_data.Urls.input_urls[ind])
    if :grayscale in model_data.input_properties
        data_input_raw = image_to_gray_float(original_image)
    else
        data_input_raw = image_to_color_float(original_image)
    end
    norm_func(data_input_raw)
    data_input = data_input_raw[:,:,:,:]
    if validation_data.PlotData.use_labels
        num = length(classes)
        labels_temp = Vector{Float32}(undef,num)
        fill!(labels_temp,0)
        label_int = validation_data.Urls.labels_classification[ind]
        labels_temp[label_int] = 1
        labels = reshape(labels_temp,:,1)
    else
        labels = Array{Float32,2}(undef,0,0)
    end
    return data_input,labels,original_image
end

function prepare_validation_data(classes::Vector{ImageRegressionClass},
        norm_func::Function,model_data::ModelData,ind::Int64,validation_data::ValidationData)
    local data_input_raw
    inds,labels_color,labels_incl,border,border_thickness = get_class_data(classes)
    original_image = load_image(validation_data.Urls.input_urls[ind])
    if :grayscale in model_data.input_properties
        data_input_raw = image_to_gray_float(original_image)
    else
        data_input_raw = image_to_color_float(original_image)
    end
    norm_func(data_input_raw)
    data_input = data_input_raw[:,:,:,:]
    if validation_data.PlotData.use_labels
        labels = reshape(validation_data.Urls.labels_regression[ind],:,1)
    else
        labels = Array{Float32,2}(undef,0,0)
    end
    return data_input,labels,original_image
end

function prepare_validation_data(classes::Vector{ImageSegmentationClass},
        norm_func::Function,model_data::ModelData,ind::Int64,validation_data::ValidationData)
    local data_input_raw
    inds,labels_color,labels_incl,border,border_thickness = get_class_data(classes)
    original_image = load_image(validation_data.Urls.input_urls[ind])
    if :grayscale in model_data.input_properties
        data_input_raw = image_to_gray_float(original_image)
    else
        data_input_raw = image_to_color_float(original_image)
    end
    norm_func(data_input_raw)
    data_input = data_input_raw[:,:,:,:]
    if validation_data.PlotData.use_labels
        label = load_image(validation_data.Urls.label_urls[ind])
        label_bool = label_to_bool(label,inds,labels_color,
            labels_incl,border,border_thickness)
        data_label = convert(Array{Float32,3},label_bool)[:,:,:,:]
    else
        data_label = Array{Float32,4}(undef,1,1,1,1)
    end
    return data_input,data_label,original_image
end


#---Validation output processing---------------------------------------------

function get_error_image(predicted_bool_feat::BitArray{2},truth::BitArray{2})
    correct = predicted_bool_feat .& truth
    false_pos = copy(predicted_bool_feat)
    false_pos[truth] .= false
    false_neg = copy(truth)
    false_neg[predicted_bool_feat] .= false
    s = (3,size(predicted_bool_feat)...)
    error_bool = BitArray{3}(undef,s)
    error_bool[1,:,:] .= false_pos
    error_bool[2,:,:] .= false_pos
    error_bool[1,:,:] = error_bool[1,:,:] .| false_neg
    error_bool[2,:,:] = error_bool[2,:,:] .| correct
    return error_bool
end

function compute(predicted_bool::BitArray{3},
        label_bool::BitArray{3},labels_color::Vector{Vector{N0f8}},
        num_feat::Int64,use_labels::Bool)
    num = size(predicted_bool,3)
    predicted_data = Vector{Tuple{BitArray{2},Vector{N0f8}}}(undef,num)
    target_data = Vector{Tuple{BitArray{2},Vector{N0f8}}}(undef,num)
    error_data = Vector{Tuple{BitArray{3},Vector{N0f8}}}(undef,num)
    color_error = ones(N0f8,3)
    for i = 1:num
        color = labels_color[i]
        predicted_bool_feat = predicted_bool[:,:,i]
        predicted_data[i] = (predicted_bool_feat,color)
        if validation_data.PlotData.use_labels
            if i>num_feat
                target_bool = label_bool[:,:,i-num_feat]
            else
                target_bool = label_bool[:,:,i]
            end
            target_data[i] = (target_bool,color)
            error_bool = get_error_image(predicted_bool_feat,target_bool)
            error_data[i] = (error_bool,color_error)
        end
    end
    return predicted_data,target_data,error_data
end

function output_images(predicted_bool::BitArray{3},label_bool::BitArray{3},
        classes::Vector{<:AbstractClass},use_labels::Bool)
    class_inds,labels_color, _ ,border = get_class_data(classes)
    labels_color = labels_color[class_inds]
    labels_color_uint = convert(Vector{Vector{N0f8}},labels_color/255)
    inds_border = findall(border)
    border_colors = labels_color_uint[findall(border)]
    labels_color_uint = vcat(labels_color_uint,border_colors,border_colors)
    array_size = size(predicted_bool)
    num_feat = array_size[3]
    num_border = sum(border)
    if num_border>0
        border_bool = apply_border_data(predicted_bool,classes)
        predicted_bool = cat(predicted_bool,border_bool,dims=Val(3))
    end
    for i=1:num_border 
        min_area = classes[inds_border[i]].min_area
        ind = num_feat + i
        if min_area>1
            temp_array = predicted_bool[:,:,ind]
            areaopen!(temp_array,min_area)
            predicted_bool[:,:,ind] .= temp_array
        end
    end
    predicted_data,target_data,error_data = compute(predicted_bool,label_bool,
        labels_color_uint,num_feat,use_labels)
    return predicted_data,target_data,error_data
end

function process_output(predicted::AbstractArray{Float32,2},label::AbstractArray{Float32,2},
        original_image::Array{RGB{N0f8},2},other_data::NTuple{2, Float32},classes::Vector{ImageClassificationClass},
        validation_data::ValidationData,channels::Channels)
    class_names = map(x-> x.name,classes)
    predicted_vec = Iterators.flatten(predicted)
    predicted_int = findfirst(predicted_vec .== maximum(predicted_vec))
    predicted_string = class_names[predicted_int]
    if validation_data.PlotData.use_labels
        label_vec = Iterators.flatten(label)
        label_int = findfirst(label_vec .== maximum(label_vec))
        label_string = class_names[label_int]
    else
        label_string = ""
    end
    # Return data
    validation_results = validation_data.ImageClassificationResults
    push!(validation_results.original_images,original_image)
    push!(validation_results.predicted_labels,predicted_string)
    push!(validation_results.target_labels,label_string)
    push!(validation_results.accuracy,other_data[1])
    push!(validation_results.loss,other_data[2])
    # Update progress
    put!(channels.validation_progress,other_data)
    return nothing
end

function process_output(predicted::AbstractArray{Float32,2},label::AbstractArray{Float32,2},
        original_image::Array{RGB{N0f8},2},other_data::NTuple{2, Float32},classes::Vector{ImageRegressionClass},
        validation_data::ValidationData,channels::Channels)
    # Return data
    validation_results = validation_data.ImageRegressionResults
    push!(validation_results.original_images,original_image)
    push!(validation_results.predicted_labels,predicted[:])
    push!(validation_results.target_labels,label[:])
    push!(validation_results.accuracy,other_data[1])
    push!(validation_results.loss,other_data[2])
    # Update progress
    put!(channels.validation_progress,other_data)
    return nothing
end

function process_output(predicted::AbstractArray{Float32,4},data_label::AbstractArray{Float32,4},
        original_image::Array{RGB{N0f8},2},other_data::NTuple{2, Float32},classes::Vector{ImageSegmentationClass},
        validation_data::ValidationData,channels::Channels)
    predicted_bool = predicted[:,:,:].>0.5
    label_bool = data_label[:,:,:].>0.5
    # Get output data
    predicted_data,target_data,error_data = 
        output_images(predicted_bool,label_bool,classes,validation_data.PlotData.use_labels)
    # Return data
    validation_results = validation_data.ImageSegmentationResults
    push!(validation_results.original_images,original_image)
    push!(validation_results.predicted_data,predicted_data)
    push!(validation_results.target_data,target_data)
    push!(validation_results.error_data,error_data)
    push!(validation_results.accuracy,other_data[1])
    push!(validation_results.loss,other_data[2])
    # Update progress
    put!(channels.validation_progress,other_data)
    return nothing
end


#---Image handling for QML--------------------------------------------------------

function bitarray_to_image(array_bool::BitArray{2},color::Vector{Normed{UInt8,8}})
    s = size(array_bool)
    array = zeros(RGB{N0f8},s...)
    colorRGB = colorview(RGB,permutedims(color[:,:,:],(1,2,3)))[1]
    array[array_bool] .= colorRGB
    return collect(array)
end

function bitarray_to_image(array_bool::BitArray{3},color::Vector{Normed{UInt8,8}})
    s = size(array_bool)[2:3]
    array_vec = Vector{Array{RGB{N0f8},2}}(undef,0)
    for i in 1:3
        array_temp = zeros(RGB{N0f8},s...)
        color_temp = zeros(Normed{UInt8,8},3)
        color_temp[i] = color[i]
        colorRGB = colorview(RGB,permutedims(color_temp[:,:,:],(1,2,3)))[1]
        array_temp[array_bool[i,:,:]] .= colorRGB
        push!(array_vec,array_temp)
    end
    array = sum(array_vec)
    return collect(array)
end

# Saves image to the main image storage and returns its size
function get_image_validation(fields,inds)
    fields = fix_QML_types(fields)
    inds = fix_QML_types(inds)
    image_data = Common.get_data_main(validation_data,fields,inds)
    if image_data isa Array{RGB{N0f8},2}
        image = image_data
    else
        image = bitarray_to_image(image_data...)
    end
    final_field = fields[end]
    if final_field=="original_images"
        validation_data.PlotData.original_image = image
    elseif any(final_field.==("predicted_data","target_data","error_data"))
        validation_data.PlotData.label_image = image
    end
    return [size(image)...]
end

function get_image_size(fields,inds)
    fields = fix_QML_types(fields)
    inds = fix_QML_types(inds)
    image_data = get_data(fields,inds)
    if image_data isa Array{RGB{N0f8},2}
        return [size(image_data)...]
    else
        return [size(image_data[1])...]
    end
end

function display_original_image_validation(buffer::Array{UInt32, 1},width::Int32,height::Int32)
    buffer = reshape(buffer, convert(Int64,width), convert(Int64,height))
    buffer = reinterpret(ARGB32, buffer)
    image = validation_data.PlotData.original_image
    s = size(image)
    if size(buffer)==reverse(size(image)) || (s[1]==s[2] && size(buffer)==size(image))
        buffer .= transpose(image)
    elseif size(buffer)==s
        buffer .= image
    end
    return
end

function display_label_image_validation(buffer::Array{UInt32, 1},width::Int32,height::Int32)
    buffer = reshape(buffer, convert(Int64,width), convert(Int64,height))
    buffer = reinterpret(ARGB32, buffer)
    image = validation_data.PlotData.label_image
    if size(buffer)==reverse(size(image))
        buffer .= transpose(image)
    end
    return
end


#----------------------------------------------------------------------------------

function get_weights(classes::Vector{<:AbstractClass},validation_options::ValidationOptions)
    if validation_options.Accuracy.weight_accuracy
        if problem_type()==:classification
            return map(class -> class.weight,classes)
        elseif problem_type()==:regression
            return Vector{Float32}(undef,0)
        else # problem_type()==:segmentation
            true_classes_bool = (!).(map(class -> class.overlap, classes))
            classes = classes = classes[true_classes_bool]
            weights = map(class -> class.weight,classes)
            borders_bool = map(class -> class.BorderClass.enabled, classes)
            border_weights = weights[borders_bool]
            append!(weights,border_weights)
            return weights
        end
    else
        return Vector{Float32}(undef,0)
    end
end

function check_abort_signal(channel::Channel)
    if isready(channel)
        value = fetch(channel)[1]
        if value==0
            return true
        else
            return false
        end
    else
        return false
    end
end

function validate_inner(model::AbstractModel,norm_func::Function,classes::Vector{<:AbstractClass},model_data::ModelData,
        accuracy::Function,loss::Function,num::Int64,validation_data::ValidationData,num_slices_val::Int64,
        offset_val::Int64,use_GPU::Bool,channels::Channels)
    for i = 1:num
        if check_abort_signal(channels.validation_modifiers)
            return nothing
        end
        input_data,label,other = prepare_validation_data(classes,norm_func,model_data,i,validation_data)
        predicted = forward(model,input_data,num_slices=num_slices_val,offset=offset_val,use_GPU=use_GPU)
        if validation_data.PlotData.use_labels
            accuracy_val = accuracy(predicted,label)
            loss_val = loss(predicted,label)
            other_data = (accuracy_val,loss_val)
        else
            other_data = (0.f0,0.f0)
        end
        process_output(predicted,label,other,other_data,classes,validation_data,channels)
    end
    return nothing
end

# Main validation function
function validate_main(model_data::ModelData,validation_data::ValidationData,
        options::Options,channels::Channels)
    # Initialisation
    remove_validation_results()
    num = length(validation_data.Urls.input_urls)
    put!(channels.validation_start,num)
    classes = model_data.classes
    model = model_data.model
    loss = model_data.loss
    ws = get_weights(classes,options.ValidationOptions)
    accuracy = get_accuracy_func(ws,options.ValidationOptions)
    use_GPU = false
    if options.GlobalOptions.HardwareResources.allow_GPU
        if has_cuda()
            use_GPU = true
        else
            @warn "No CUDA capable device was detected. Using CPU instead."
        end
    end
    normalization = model_data.normalization
    norm_func(x) = model_data.normalization.f(x,normalization.args...)
    if problem_type()==:segmentation
        num_slices_val = options.GlobalOptions.HardwareResources.num_slices
        offset_val = options.GlobalOptions.HardwareResources.offset
    else
        num_slices_val = 1
        offset_val = 0
    end
    # Validation starts
    validate_inner(model,norm_func,classes,model_data,accuracy,loss,num,validation_data,
        num_slices_val,offset_val,use_GPU,channels)
    return nothing
end
function validate_main2(model_data::ModelData,validation_data::ValidationData,
        options::Options,channels::Channels)
    t = Threads.@spawn validate_main(model_data,validation_data,options,channels)
    push!(validation_data.tasks,t)
    return t
end