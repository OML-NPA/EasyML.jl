
#---Data preparation

# Get urls of files in selected folders

function get_urls_validation_main(validation::Validation,validation_data::ValidationData,model_data::ModelData)
    if settings.input_type == :Image
        allowed_ext = ["png","jpg","jpeg"]
    end
    if settings.problem_type == :Classification
        input_urls,dirs = get_urls1(validation,allowed_ext)
        labels = map(class -> class.name,model_data.classes)
        if issubset(dirs,labels)
            validation.use_labels = true
            labels_int = map((label,l) -> repeat([findfirst(label.==labels)],l),dirs,length.(input_urls))
            validation_data.labels_classification = reduce(vcat,labels_int)
        end
    elseif settings.problem_type == :Regression
        input_urls_raw,_,filenames_inputs_raw = get_urls1(validation,allowed_ext)
        input_urls = input_urls_raw[1]
        filenames_inputs = filenames_inputs_raw[1]
        if validation.use_labels==true
            filenames_labels,loaded_labels = load_regression_data(regression_data.labels_url)
            intersect_regression_data!(input_urls,filenames_inputs,
                loaded_labels,filenames_labels)
            validation_data.labels_regression = loaded_labels
        end
    elseif settings.problem_type == :Segmentation
        if validation.use_labels==true
            input_urls,label_urls,_,_,_ = get_urls2(validation,allowed_ext)
            validation_data.label_urls = reduce(vcat,label_urls)
        else
            input_urls,_ = get_urls1(validation,allowed_ext)
        end
    end
    validation_data.input_urls = reduce(vcat,input_urls)
    return nothing
end
#get_urls_validation() = get_urls_validation_main(validation,model_data)

function reset_validation_results(validation_data::ValidationData)
    results_classification = validation_data.ImageClassificationResults
    fields = fieldnames(ValidationImageClassificationResults)
    for field in fields
        empty_field!(results_classification,field)
    end
    results_segmentation = validation_data.ImageSegmentationResults
    fields = fieldnames(ValidationImageSegmentationResults)
    for field in fields
        empty_field!(results_segmentation,field)
    end
    return nothing
end

function prepare_validation_data(model_data::ModelData,validation::Validation,validation_data::ValidationData,
        options::ProcessingTraining, classes::Vector{ImageClassificationClass},ind::Int64)
    original = load_image(validation_data.input_urls[ind])
    if options.grayscale
        data_input = image_to_gray_float(original)[:,:,:,:]
    else
        data_input = image_to_color_float(original)[:,:,:,:]
    end
    if validation.use_labels
        num = length(classes)
        labels_temp = Vector{Float32}(undef,num)
        fill!(labels_temp,0)
        label_int = validation_data.labels_classification[ind]
        labels_temp[label_int] = 1
        labels = reshape(labels_temp,:,1)
    else
        labels = Array{Float32,2}(undef,0,0)
    end
    return data_input,labels,original
end

function prepare_validation_data(model_data::ModelData,validation::Validation,validation_data::ValidationData,
        options::ProcessingTraining, classes::Vector{ImageRegressionClass},ind::Int64)
    original = load_image(validation_data.input_urls[ind])
    original = imresize(original,model_data.input_size[1:2])
    if options.grayscale
        data_input = image_to_gray_float(original)[:,:,:,:]
    else
        data_input = image_to_color_float(original)[:,:,:,:]
    end
    
    if validation.use_labels
        labels = reshape(validation_data.labels_regression[ind],:,1)
    else
        labels = Array{Float32,2}(undef,0,0)
    end
    return data_input,labels,original
end

function prepare_validation_data(model_data::ModelData,validation::Validation,validation_data::ValidationData,
        options::ProcessingTraining, classes::Vector{ImageSegmentationClass},ind::Int64)
    inds,labels_color,labels_incl,border,border_thickness = get_class_data(classes)
    original = load_image(validation_data.input_urls[ind])
    if options.grayscale
        data_input = image_to_gray_float(original)[:,:,:,:]
    else
        data_input = image_to_color_float(original)[:,:,:,:]
    end
    if validation.use_labels
        label = load_image(validation_data.label_urls[ind])
        label_bool = label_to_bool(label,inds,labels_color,
            labels_incl,border,border_thickness)
        data_label = convert(Array{Float32,3},label_bool)[:,:,:,:]
    else
        data_label = Array{Float32,4}(undef,1,1,1,1)
    end
    return data_input,data_label,original
end

#---Makes output images
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

function compute(validation::Validation,predicted_bool::BitArray{3},
        label_bool::BitArray{3},labels_color::Vector{Vector{N0f8}},
        num_feat::Int64)
    num = size(predicted_bool,3)
    predicted_data = Vector{Tuple{BitArray{2},Vector{N0f8}}}(undef,num)
    target_data = Vector{Tuple{BitArray{2},Vector{N0f8}}}(undef,num)
    error_data = Vector{Tuple{BitArray{3},Vector{N0f8}}}(undef,num)
    color_error = ones(N0f8,3)
    for i = 1:num
        color = labels_color[i]
        predicted_bool_feat = predicted_bool[:,:,i]
        predicted_data[i] = (predicted_bool_feat,color)
        if validation.use_labels
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
        classes::Vector{<:AbstractClass},validation::Validation)
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
        predicted_bool = cat3(predicted_bool,border_bool)
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
    predicted_data,target_data,error_data = compute(validation,
        predicted_bool,label_bool,labels_color_uint,num_feat)
    return predicted_data,target_data,error_data
end

function process_output(predicted::AbstractArray{Float32,2},label::AbstractArray{Float32,2},
        original::Array{RGB{N0f8},2},other_data::NTuple{2, Float32},
        validation::Validation,classes::Vector{ImageClassificationClass},channels::Channels)
    class_names = map(x-> x.name,classes)
    predicted_vec = Iterators.flatten(predicted)
    predicted_int = findfirst(predicted_vec .== maximum(predicted_vec))
    predicted_string = class_names[predicted_int]
    if validation.use_labels
        label_vec = Iterators.flatten(label)
        label_int = findfirst(label_vec .== maximum(label_vec))
        label_string = class_names[label_int]
    else
        label_string = ""
    end
    image_data = (predicted_string,label_string)
    data = (image_data,other_data,original)
    # Return data
    put!(channels.validation_results,data)
    put!(channels.validation_progress,1)
    return nothing
end

function process_output(predicted::AbstractArray{Float32,2},label::AbstractArray{Float32,2},
        original::Array{RGB{N0f8},2},other_data::NTuple{2, Float32},
        validation::Validation,classes::Vector{ImageRegressionClass},channels::Channels)
    image_data = (predicted[:],label[:])
    data = (image_data,other_data,original)
    # Return data
    put!(channels.validation_results,data)
    put!(channels.validation_progress,1)
    return nothing
end

function process_output(predicted::AbstractArray{Float32,4},data_label::AbstractArray{Float32,4},
        original::Array{RGB{N0f8},2},other_data::NTuple{2, Float32},validation::Validation,
        classes::Vector{ImageSegmentationClass},channels::Channels)
    predicted_bool = predicted[:,:,:,1].>0.5
    label_bool = data_label[:,:,:,1].>0.5
    # Get output data
    predicted_data,target_data,error_data = 
        output_images(predicted_bool,label_bool,classes,validation)
    image_data = (predicted_data,target_data,error_data)
    data = (image_data,other_data,original)
    # Return data
    put!(channels.validation_results,data)
    put!(channels.validation_progress,1)
    return nothing
end

# Main validation function
function validate_main(settings::Settings,validation_data::ValidationData,
        model_data::ModelData,channels::Channels)
    # Initialisation
    validation = settings.Validation
    processing = settings.Training.Options.Processing
    reset_validation_results(validation_data)
    num = length(validation_data.input_urls)
    put!(channels.validation_progress,num)
    use_labels = validation.use_labels
    classes = model_data.classes
    model = model_data.model
    loss = model_data.loss
    accuracy::Function = get_accuracy_func(settings.Training)
    use_GPU = settings.Options.HardwareResources.allow_GPU && has_cuda()
    if settings.problem_type==:Classification || settings.problem_type==:Regression
        num_parts_current = 1
    else
        num_parts_current = 30
    end
    for i = 1:num
        if isready(channels.validation_modifiers)
            stop_cond::String = fetch(channels.validation_modifiers)[1]
            if stop_cond=="stop"
                take!(channels.validation_modifiers)
                break
            end
        end
        data_input,label,other = prepare_validation_data(model_data,validation,validation_data,
            processing,classes,i)
        predicted = forward(model,data_input,num_parts=num_parts_current,use_GPU=use_GPU)
        if use_labels
            accuracy_val = accuracy(predicted,label)
            loss_val = loss(predicted,label)
            other_data = (accuracy_val,loss_val)
        else
            other_data = (0.f0,0.f0)
        end
        process_output(predicted,label,other,other_data,validation,classes,channels)
    end
    return nothing
end
function validate_main2(settings::Settings,validation_data::ValidationData,
        model_data::ModelData,channels::Channels)
    Threads.@spawn validate_main(settings,validation_data,model_data,channels)
    return nothing
end