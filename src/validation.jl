
#---Data preparation

# Get urls of files in selected folders

function get_urls_validation_main(validation::Validation,validation_data::Validation_data,model_data::Model_data)
    if model_data.classes[1] isa Image_segmentation_class
        allowed_ext = ["png","jpg","jpeg"]
    end
    if validation.use_labels==true
        input_urls,label_urls,_,_,_ = get_urls2(validation,allowed_ext)
        validation_data.label_urls = reduce(vcat,label_urls)
    else
        input_urls,_ = get_urls1(validation,allowed_ext)
    end
    validation_data.input_urls = reduce(vcat,input_urls)
    
end
#get_urls_validation() = get_urls_validation_main(validation,model_data)

function reset_validation_results(validation_data::Validation_data)
    results_classification = validation_data.Results_classification
    fields = fieldnames(Validation_classification_results)
    for field in fields
        empty_field!(results_classification,field)
    end
    results_segmentation = validation_data.Results_segmentation
    fields = fieldnames(Validation_segmentation_results)
    for field in fields
        empty_field!(results_segmentation,field)
    end
    return nothing
end

function prepare_validation_data(validation::Validation,validation_data::Validation_data,
        options::Processing_training, classes::Vector{Image_segmentation_class},ind::Int64)
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
        data_label = Array{Float32,4}(undef,size(data_input))
    end
    return data_input,data_label,original
end

function prepare_validation_data(validation::Validation,validation_data::Validation_data,
        options::Processing_training, classes::Vector{Image_classification_class},ind::Int64)
    original = load_image(validation_data.input_urls[ind])
    if options.grayscale
        data_input = image_to_gray_float(original)[:,:,:,:]
    else
        data_input = image_to_color_float(original)[:,:,:,:]
    end
    if validation.use_labels
        labels = validation_data.labels
    else
        labels = Vector{Int64}(undef,0)
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
    array_size = size(label_bool)
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

function process_output(validation::Validation,predicted::AbstractArray{Float32},
        data_label::Int32,original::Array{RGB{N0f8},2},
        other_data::NTuple{2, Float32},classes::Vector{Image_classification_class},channels::Channels)
    predicted_label = findall(predicted .== maximum(predicted))
    image_data = (predicted_label,data_label)
    data = (image_data,other_data,original)
    # Return data
    put!(channels.validation_results,data)
    put!(channels.validation_progress,1)
    return nothing
end

function process_output(validation::Validation,predicted::AbstractArray{Float32},
        data_label::AbstractArray{Float32},original::Array{RGB{N0f8},2},
        other_data::NTuple{2, Float32},classes::Vector{Image_segmentation_class},channels::Channels)
    predicted_bool = predicted[:,:,:,1].>0.5
    label_bool = data_label[:,:,:,1].>0.5
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
function validate_main(settings::Settings,validation_data::Validation_data,
        model_data::Model_data,channels::Channels)
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
    accuracy = get_accuracy_func(settings.Training)
    use_GPU = settings.Options.Hardware_resources.allow_GPU && has_cuda()
    GC.gc()
    for i = 1:num
        if isready(channels.validation_modifiers)
            stop_cond::String = fetch(channels.validation_modifiers)[1]
            if stop_cond=="stop"
                take!(channels.validation_modifiers)
                break
            end
        end
        data_input,data_label,other = prepare_validation_data(validation,validation_data,
            processing,classes,i)
        predicted = forward(model,data_input,use_GPU=use_GPU)
        if use_labels
            accuracy_val = accuracy(predicted,data_label)
            loss_val = loss(predicted,data_label)
            other_data = (accuracy_val,loss_val)
        else
            other_data = (0.f0,0.f0)
        end
        process_output(validation,predicted,data_label,other,other_data,classes,channels)
    end
    return nothing
end
function validate_main2(settings::Settings,validation_data::Validation_data,
        model_data::Model_data,channels::Channels)
    Threads.@spawn validate_main(settings,validation_data,model_data,channels)
    return nothing
end
# validate() = validate_main2(settings,validation_data,model_data,channels)