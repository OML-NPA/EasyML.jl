
#---Data preparation
function prepare_validation_data_main(url_imgs::Vector{String},url_labels::Vector{String},
        features::Vector{Feature})
    images = load_images(url_imgs)
    labels = load_images(url_labels)
    if isempty(features)
        @info "empty features"
        return false
    end
    labels_color,labels_incl,border = get_feature_data(features)
    data_input = map(x->image_to_gray_float(x),images)
    data_labels = map(x->label_to_bool(x,labels_color,labels_incl,border),labels)
    data = (images,labels,data_input,data_labels)
    return data
end
prepare_validation_data(url_imgs,url_labels) =
    prepare_validation_data_main(url_imgs,url_labels,model_data.features)


function get_validation_set(data_input_raw::Vector{Array{Float32,2}},
    data_labels_in::Vector{BitArray{3}},training::Training)
    data_labels_raw = convert(Vector{Array{Float32,3}},data_labels_in)
    data_input = map(x->x[:,:,:,:],data_input_raw)
    data_labels = map(x->x[:,:,:,:],data_labels_raw)
    set = (data_input,data_labels)
    return set
end

function reset_validation_data(validation_results_data::Validation_results_data,
    validation_plot_data::Validation_plot_data)
    validation_results_data.accuracy = Vector{Float32}(undef,0)
    validation_results_data.loss = Vector{Float32}(undef,0)
    validation_results_data.loss_std = NaN
    validation_results_data.accuracy_std = NaN
    validation_plot_data.data_error =
        Vector{Vector{Array{RGB{Float32},2}}}(undef,1)
    validation_plot_data.data_target =
        Vector{Vector{Array{RGB{Float32},2}}}(undef,1)
    validation_plot_data.data_predicted =
        Vector{Vector{Array{RGB{Float32},2}}}(undef,1)
    return nothing
end

#---Analysing images in slices
function prepare_data(input_data::Union{Array{Float32,4},CuArray{Float32,4}},ind_max::Int64,
        max_value::Int64,offset::Int64,ind_split::Int64,j::Int64)
    start_ind = 1 + (j-1)*ind_split-1
    end_ind = start_ind + ind_split-1
    correct_size = end_ind-start_ind+1
    start_ind = start_ind - offset
    end_ind = end_ind + offset
    start_ind = start_ind<1 ? 1 : start_ind
    end_ind = end_ind>max_value ? max_value : end_ind
    temp_data = input_data[:,start_ind:end_ind,:,:]
    max_dim_size = size(temp_data,ind_max)
    offset_add = Int64(ceil(max_dim_size/16)*16) - max_dim_size
    temp_data = pad(temp_data,[0,offset_add],same)
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
        temp_predicted = pad(temp_predicted,[0,-offset_temp])
    end
end

function accum_parts(model::Chain,input_data::Array{Float32,4},
        num_parts::Int64,offset::Int64)
    input_size = size(input_data)
    max_value = maximum(input_size)
    ind_max = findfirst(max_value.==input_size)
    ind_split = convert(Int64,floor(max_value/num_parts))
    predicted = Vector{Array{Float32,4}}(undef,0)
    for j = 1:num_parts
        if j==num_parts
            ind_split = ind_split+rem(max_value,num_parts)
        end
        temp_data,correct_size,offset_add =
            prepare_data(input_data,ind_max,max_value,offset,ind_split,j)
        temp_predicted = model(temp_data)
        temp_predicted =
            fix_size(temp_predicted,num_parts,correct_size,ind_max,offset_add,j)
        push!(predicted,temp_predicted)
    end
    predicted_out = reduce(vcat,predicted)
    return predicted_out
end

function accum_parts(model::Chain,input_data::CuArray{Float32,4},
        num_parts::Int64,offset::Int64)
    input_size = size(input_data)
    max_value = maximum(input_size)
    ind_max = findfirst(max_value.==input_size)
    ind_split = convert(Int64,floor(max_value/num_parts))
    predicted = Vector{CuArray{Float32,4}}(undef,0)
    for j = 1:num_parts
        if j==num_parts
            ind_split = ind_split+rem(max_value,num_parts)
        end
        temp_data,correct_size,offset_add =
            prepare_data(input_data,ind_max,max_value,offset,ind_split,j)
        temp_predicted::CuArray{Float32,4} = model(temp_data)
        temp_predicted =
            fix_size(temp_predicted,num_parts,correct_size,ind_max,offset_add,j)
        push!(predicted,collect(temp_predicted))
        CUDA.unsafe_free!(temp_predicted)
    end
    predicted_out::CuArray{Float32,4} = hcat(predicted...)
    return predicted_out
end

#---Makes output images
function do_target!(target_temp::Vector{Array{RGB{Float32},2}},
        target::Array{Float32,2},color::Array{Float32,3},j::Int64)
    target_img = target.*color
    target_img2 = permutedims(target_img,[3,1,2])
    target_img3 = colorview(RGB,target_img2)
    target_img3 = collect(target_img3)
    target_temp[j] = target_img3
end

function do_predicted_error!(predicted_error_temp::Vector{Array{RGB{Float32},2}},
        truth::BitArray{2},predicted_bool::BitArray{2},j::Int64)
    correct = predicted_bool .& truth
    false_pos = copy(predicted_bool)
    false_pos[truth] .= false
    false_neg = copy(truth)
    false_neg[predicted_bool] .= false
    error_img = zeros(Bool,(size(predicted_bool)...,3))
    error_img[:,:,1:2] .= false_pos
    error_img[:,:,1] = error_img[:,:,1] .| false_neg
    error_img[:,:,2] = error_img[:,:,2] .| correct
    error_img = permutedims(error_img,[3,1,2])
    error_img2 = convert(Array{Float32,3},error_img)
    error_img3 = colorview(RGB,error_img2)
    error_img3 = collect(error_img3)
    predicted_error_temp[j] = error_img3
    return
end

function do_predicted_color!(predicted_color_temp::Vector{Array{RGB{Float32},2}},
        predicted_bool::BitArray{2},color::Array{Float32,3},j::Int64)
    temp = Float32.(predicted_bool)
    temp = cat3(temp,temp,temp)
    temp = temp.*color
    temp = permutedims(temp,[3,1,2])
    temp2 = convert(Array{Float32,3},temp)
    temp3 = colorview(RGB,temp2)
    temp3 = collect(temp3)
    predicted_color_temp[j] = temp3
    return
end

function compute(set_part::Array{Float32,4},data_array_part::BitArray{3},
    perm_labels_color::Vector{Array{Float32,3}},num2::Int64,num_feat::Int64)
    target_temp = Vector{Array{RGB{Float32},2}}(undef,num2)
    predicted_color_temp = Vector{Array{RGB{Float32},2}}(undef,num2)
    predicted_error_temp = Vector{Array{RGB{Float32},2}}(undef,num2)
    Threads.@threads for j = 1:num2
        if j>num_feat
            target = set_part[:,:,j-num_feat]
        else
            target = set_part[:,:,j]
        end
        color = perm_labels_color[j]
        do_target!(target_temp,target,color,j)
        truth = target.>0
        predicted_bool = data_array_part[:,:,j]
        do_predicted_error!(predicted_error_temp,truth,predicted_bool,j)
        do_predicted_color!(predicted_color_temp,predicted_bool,color,j)
        @everywhere GC.safepoint()
    end
    return target_temp,predicted_color_temp,predicted_error_temp
end

function output_and_error_images(predicted_array::Vector{BitArray{3}},
        actual_array::Array{Array{Float32,4},1},
        model_data::Model_data,channels::Channels)
    labels_color,labels_incl,border = get_feature_data(model_data.features)
    border_colors = labels_color[findall(border)]
    labels_color = vcat(labels_color,border_colors,border_colors)
    array_size = size(predicted_array[1])
    array_size12 = array_size[1:2]
    num_feat = array_size[3]
    num = length(predicted_array)
    num2 = length(labels_color)
    perm_labels_color = Vector{Array{Float32,3}}(undef,num2)
    for i=1:num2
        perm_labels_color[i] = permutedims(labels_color[i][:,:,:]/255,[3,2,1])
    end
    num_border = sum(border)
    data_array = Vector{BitArray{3}}(undef,num)
    if num_border>0
        border_array = map(x->apply_border_data_main(x,model_data),predicted_array)
        data_array .= cat3.(predicted_array,border_array)
    else
        data_array .= predicted_array
    end
    predicted_color = Vector{Vector{Array{RGB{Float32},2}}}(undef,num)
    predicted_error = Vector{Vector{Array{RGB{Float32},2}}}(undef,num)
    target_color = Vector{Vector{Array{RGB{Float32},2}}}(undef,num)
    Threads.@threads for i = 1:num
        set_part = actual_array[i]
        data_array_part = data_array[i]
        target_temp,predicted_color_temp,predicted_error_temp =
            compute(set_part,data_array_part,perm_labels_color,num2,num_feat)
        predicted_color[i] = predicted_color_temp
        predicted_error[i] = predicted_error_temp
        target_color[i] = target_temp
        put!(channels.validation_progress,1)
        @everywhere GC.safepoint()
    end
    return predicted_color,predicted_error,target_color
end

#---Main analysis funtions
# Runs data thorugh a neural network
function forward(model::Chain,input_data::Array{Float32};
        num_parts::Int64=1,offset::Int64=0,use_GPU::Bool=true)
    if num_parts!==0 && offset==0
        offset = 20
    end
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
    return predicted::Array{Float32,4}
end

# Main validation function
function validate_main(data::Tuple{Vector{Array{Float32,2}},Vector{BitArray{3}}},
        settings::Settings,validation_data::Validation_data,model_data::Model_data,
        channels::Channels)
    training = settings.Training
    model = model_data.model
    loss = model_data.loss
    accuracy = get_accuracy_func(training)
    use_GPU = settings.Options.Hardware_resources.allow_GPU && has_cuda()
    validation_results_data = validation_data.Validation_results_data
    validation_plot_data = validation_data.Validation_plot_data
    reset_validation_data(validation_results_data,validation_plot_data)
    # Preparing set
    set = get_validation_set(data[1],data[2],training)
    num = length(set[1])
    accuracy_array = Vector{Float32}(undef,0)
    predicted_array = Vector{BitArray{3}}(undef,0)
    loss_array = Vector{Float32}(undef,0)
    put!(channels.validation_progress,[2*num])
    num_parts = 10
    offset = 20
    @everywhere GC.gc()
    for i = 1:num
        if isready(channels.validation_modifiers)
            stop_cond::String = fetch(channels.validation_modifiers)[1]
            if stop_cond=="stop"
                take!(channels.validation_modifiers)
                break
            end
        end
        input_data = set[1][i]
        actual = set[2][i]
        predicted = forward(model,input_data,num_parts=num_parts,
            offset=offset,use_GPU=use_GPU)
        predicted_bool = predicted.>0.5
        size_dim4 = size(predicted_bool,4)
        accuracy_array_temp = Vector{Float32}(undef,size_dim4)
        predicted_array_temp = Vector{BitArray{3}}(undef,size_dim4)
        loss_array_temp = Vector{Float32}(undef,size_dim4)
        for j = 1:size_dim4
            predicted_temp = predicted[:,:,:,j:j]
            actual_temp = actual[:,:,:,j:j]
            accuracy_array_temp[j] = accuracy(predicted_temp,actual_temp)
            loss_array_temp[j] = loss(predicted_temp,actual_temp)
            predicted_array_temp[j] = predicted_bool[:,:,:,j]
        end
        push!(accuracy_array,accuracy_array_temp...)
        push!(loss_array,loss_array_temp...)
        push!(predicted_array,predicted_array_temp...)
        temp_accuracy = accuracy_array[1:i]
        temp_loss = loss_array[1:i]
        mean_accuracy = mean(temp_accuracy)
        mean_loss = mean(temp_loss)
        accuracy_std = std(temp_accuracy)
        loss_std = std(temp_loss)
        data_out = [mean_accuracy,mean_loss,accuracy_std,loss_std]
        put!(channels.validation_progress,data_out)
        @everywhere GC.safepoint()
    end
    actual_array = set[2]
    data_predicted,data_error,target = output_and_error_images(predicted_array,
        actual_array,model_data,channels)
    data = (data_predicted,data_error,target,
        accuracy_array,loss_array,std(accuracy_array),std(loss_array))
    put!(channels.validation_results,data)
    return nothing
end
function validate(data)
    empty_progress_channel("Validation")
    empty_results_channel("Validation")
    empty_progress_channel("Validation modifiers")
    validation_plot_data.data_input_orig = data[1]
    validation_plot_data.data_labels_orig = data[2]
    worker = workers()[end]
    @everywhere settings,model_data
    remote_do(validate_main,worker,data[3:4],settings,validation_data,model_data,channels)
    # Launches GUI
    @qmlfunction(
        # Handle features
        num_features,
        get_feature_field,
        # Data handling
        get_settings,
        get_results,
        get_progress,
        put_channel,
        get_image,
        # Other
        yield
    )
    f = CxxWrap.@safe_cfunction(display_image, Cvoid,
                                        (Array{UInt32,1}, Int32, Int32))
    load("GUI/ValidationPlot.qml",
        display_image = f)
    exec()
    return validation_results_data
end
