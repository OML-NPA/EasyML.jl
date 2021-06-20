
# Get urls of files in selected folders
function get_urls_main(local_settings::Union{Training,Testing},local_data::Union{TrainingData,TestingData},model_data::ModelData)
    input_url = local_settings.input_url
    label_url = local_settings.label_url
    if settings.input_type==:Image
        allowed_ext = ["png","jpg","jpeg"]
    end
    if settings.problem_type==:Classification
        input_urls,dirs,_ = get_urls1(input_url,allowed_ext)
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
        local_data.ClassificationData.input_urls = input_urls
        local_data.ClassificationData.label_urls = dirs
    elseif settings.problem_type==:Regression
        input_urls,_,filenames = get_urls1(input_url,allowed_ext)
        local_data.RegressionData.input_urls = reduce(vcat,input_urls)
        local_data.RegressionData.labels_url = label_url
        local_data.RegressionData.filenames = reduce(vcat,filenames)
    elseif settings.problem_type==:Segmentation
        input_urls,label_urls,_,filenames,fileindices = get_urls2(input_url,label_url,allowed_ext)
        local_data.SegmentationData.input_urls = reduce(vcat,input_urls)
        local_data.SegmentationData.label_urls = reduce(vcat,label_urls)
        local_data.SegmentationData.filenames = filenames
        local_data.SegmentationData.fileindices = fileindices
    end
    return nothing
end

# Set training starting time
function set_training_starting_time_main(training_plot_data::TrainingPlotData)
    training_plot_data.starting_time = now()
    return nothing
end
set_training_starting_time() =
    set_training_starting_time_main(training_plot_data)

# Calculates the time elapsed from the begining of training
function training_elapsed_time_main(training_plot_data::TrainingPlotData)
    dif = (now() - training_plot_data.starting_time).value
    hours = string(Int64(floor(dif/3600000)))
    minutes_num = floor(dif/60000)
    minutes = string(Int64(minutes_num - floor(minutes_num/60)*60))
    if length(minutes)<2
        minutes = string("0",minutes)
    end
    seconds_num = round(dif/1000)
    seconds = string(Int64(seconds_num - floor(seconds_num/60)*60))
    if length(seconds)<2
        seconds = string("0",seconds)
    end
    return string(hours,":",minutes,":",seconds)
end
training_elapsed_time() = training_elapsed_time_main(training_plot_data)

#---

# Augments images and labels using rotation and mirroring
function augment(float_img::Array{Float32,3},size12::Tuple{Int64,Int64},num_angles::Int64)
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
                    for h = 1:2
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
        num_angles::Int64,min_fr_pix::Float64)
    data = Vector{Tuple{Array{Float32,3},BitArray{3}}}(undef,0)
    lim = prod(size12)*min_fr_pix
    angles_range = range(0,stop=2*pi,length=num_angles+1)
    angles = collect(angles_range[1:end-1])
    num = length(angles)
    @floop ThreadedEx() for g = 1:num
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
                    for h = 1:2
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

# Prepare data for training
function prepare_data(classification_data::ClassificationData,
        model_data::ModelData,options::TrainingOptions,size12::Tuple{Int64,Int64},
        progress::Channel,results::Channel)
    num_angles = options.Processing.num_angles
    input_urls = classification_data.input_urls
    label_urls = classification_data.label_urls
    labels = map(class -> class.name, model_data.classes)
    labels_int = map((label,l) -> repeat([findfirst(label.==labels)],l),label_urls,length.(input_urls))
    data_labels_initial = reduce(vcat,labels_int)
    num = length(input_urls)
    # Get number of images
    num_all = sum(length.(input_urls))
    # Return progress target value
    put!(progress, num_all + 2)
    # Load images
    imgs = load_images.(input_urls)
    put!(progress, 1)
    # Initialize accumulators
    data_input = Vector{Vector{Array{Float32,3}}}(undef,num)
    data_label = Vector{Vector{Int32}}(undef,num)
    @floop ThreadedEx() for k = 1:num
        current_imgs = imgs[k]
        num2 = length(current_imgs)
        label = data_labels_initial[k]
        data_input_temp = Vector{Vector{Array{Float32,3}}}(undef,num2)
        data_label_temp = Vector{Vector{Int32}}(undef,num2)
        for l = 1:num2
            # Abort if requested
            if isready(channels.training_data_modifiers)
                if fetch(channels.training_data_modifiers)[1]=="stop"
                    return nothing
                end
            end
            # Get a current image
            img_raw = current_imgs[l]
            # Convert to float
            if options.Processing.grayscale
                img = image_to_gray_float(img_raw)
            else
                img = image_to_color_float(img_raw)
            end
            # Augment images
            data = augment(img,size12,num_angles)
            data_input_temp[l] = data
            data_label_temp[l] = repeat([label],length(data))
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
    inds = collect(1:length(data_input_flat))
    shuffle!(inds)
    data_input_flat = data_input_flat[inds]
    data_label_flat = data_label_flat[inds]
    # Return results
    put!(results, (data_input_flat,data_label_flat))
    # Return progress
    put!(progress, 1)
    return nothing
end

function prepare_data(regression_data::RegressionData,
        model_data::ModelData,options::TrainingOptions,
        size12::Tuple{Int64,Int64},progress::Channel,results::Channel)
    input_size = model_data.input_size
    num_angles = options.Processing.num_angles
    input_urls = regression_data.input_urls
    filenames_inputs = regression_data.filenames
    # Get number of images
    num = length(input_urls)
    # Return progress target value
    put!(progress, num+2)
    # Load labels
    filenames_labels,loaded_labels = load_regression_data(regression_data.labels_url)
    intersect_regression_data!(input_urls,filenames_inputs,loaded_labels,filenames_labels)
    num = length(input_urls)
    # Load images
    imgs = load_images(input_urls)
    put!(progress, 1)
    # Initialize accumulators
    data_input = Vector{Vector{Array{Float32,3}}}(undef,num)
    data_label = Vector{Vector{Vector{Float32}}}(undef,num)
    @floop ThreadedEx() for k = 1:num
        # Abort if requested
        if isready(channels.training_data_modifiers)
            if fetch(channels.training_data_modifiers)[1]=="stop"
                return nothing
            end
        end
        # Get a current image
        img_raw = imgs[k]
        img_raw = imresize(img_raw,input_size[1:2])
        # Get current label
        label = loaded_labels[k]
        # Convert to float
        if options.Processing.grayscale
            img = image_to_gray_float(img_raw)
        else
            img = image_to_color_float(img_raw)
        end
        # Augment images
        temp_input = augment(img,size12,num_angles)
        temp_label = repeat([label],length(temp_input))
        data_input[k] = temp_input
        data_label[k] = temp_label
        # Return progress
        put!(progress, 1)
    end
    # Flatten input images and labels array
    data_input_flat = reduce(vcat,data_input)
    data_label_flat = reduce(vcat,data_label)
    inds = collect(1:length(data_input_flat))
    shuffle!(inds)
    data_input_flat = data_input_flat[inds]
    data_label_flat = data_label_flat[inds]
    # Return results
    put!(results, (data_input_flat,data_label_flat))
    # Return progress
    put!(progress, 1)
    return nothing
end

function prepare_data(segmentation_data::SegmentationData,
        model_data::ModelData,options::TrainingOptions,
        size12::Tuple{Int64,Int64},progress::Channel,results::Channel)
    classes = model_data.classes
    min_fr_pix = options.Processing.min_fr_pix
    num_angles = options.Processing.num_angles
    input_urls = segmentation_data.input_urls
    # Get number of images
    num = length(input_urls)
    # Return progress target value
    put!(progress, num+2)
    # Get class data
    class_inds,labels_color,labels_incl,border,border_thickness = get_class_data(classes)
    # Load images
    imgs = load_images(input_urls)
    labels = load_images(segmentation_data.label_urls)
    put!(progress, 1)
    # Initialize accumulators
    data_input = Vector{Vector{Array{Float32,3}}}(undef,num)
    data_label = Vector{Vector{Array{Float32,3}}}(undef,num)
    # Make input images
    @floop ThreadedEx() for k = 1:num
        # Abort if requested
        if isready(channels.training_data_modifiers)
            if fetch(channels.training_data_modifiers)[1]=="stop"
                return nothing
            end
        end
        # Get current images
        img_raw = imgs[k]
        labelimg = labels[k]
        # Convert to float
        if options.Processing.grayscale
            img = image_to_gray_float(img_raw)
        else
            img = image_to_color_float(img_raw)
        end
        # Crope to remove black background
        # img,label = correct_view(img,label)
        # Convert BitArray labels to Array{Float32}
        label = label_to_bool(labelimg,class_inds,labels_color,labels_incl,border,border_thickness)
        # Augment images
        data = augment(img,label,size12,num_angles,min_fr_pix)
        data_input[k] = getfield.(data, 1)
        data_label[k] = getfield.(data, 2)
        # Return progress
        put!(progress, 1)
    end
    # Flatten input images and labels array
    data_input_flat = reduce(vcat,data_input)
    data_label_flat = reduce(vcat,data_label)
    inds = collect(1:length(data_input_flat))
    shuffle!(inds)
    data_input_flat = data_input_flat[inds]
    data_label_flat = data_label_flat[inds]
    # Return results
    put!(results, (data_input_flat,data_label_flat))
    # Return progress
    put!(progress, 1)
    return nothing
end

# Wrapper allowing for remote execution
function prepare_data_main(local_settings::Union{Training,Testing},local_data::Union{TrainingData,TestingData},
        model_data::ModelData,channels::Channels)
    # Initialize
    options = settings.Training.Options
    size12 = model_data.input_size[1:2]
    problem_type = settings.problem_type
    if problem_type==:Classification
        data = local_data.ClassificationData
    elseif problem_type==:Regression
        data = local_data.RegressionData
    elseif problem_type==:Segmentation
        data = local_data.SegmentationData
    end
    if local_settings isa Training
        progress = channels.training_data_progress
        results = channels.training_data_results
    else
        progress = channels.testing_data_progress
        results = channels.testing_data_results
    end
    t = Threads.@spawn prepare_data(data,model_data,options,size12,progress,results)
    return nothing
end
#prepare_data() = prepare_data_main2(training,training_data,
#    model_data,channels.training_data_progress,channels.training_data_results)

# Creates data sets for training and testing
function get_sets(typed_training_data::T,typed_testing_data::T) where T<:Union{ClassificationData,RegressionData,SegmentationData}
    train_set = (typed_training_data.data_input,typed_training_data.data_labels)
    test_set = (typed_testing_data.data_input,typed_testing_data.data_labels)
    return train_set, test_set
end

# Creates a minibatch
function make_minibatch_inds(num_data::Int64,batch_size::Int64)
    # Calculate final index
    num = num_data - batch_size
    val = Int64(max(0.0,floor(num/batch_size)))
    finish = val*batch_size
    # Get indices
    inds_start = collect(0:batch_size:finish)
    inds_all = collect(1:num_data)
    # Number of indices
    num = length(inds_start)
    return inds_start,inds_all,num
end

function make_minibatch_classification_conv(data_input::Vector{Array{Float32,3}},data_labels::Vector{Int32},
        max_labels::Vector{Int32},batch_size::Int64,inds_start::Vector{Int64},
        inds_all::Vector{Int64},i::Int64)
    ind = inds_start[i]
    # First and last minibatch indices
    ind1 = ind+1
    ind2 = ind+batch_size
    # Get inputs and labels
    current_inds = inds_all[ind1:ind2]
    current_input = data_input[current_inds]
    l = length(current_inds)
    l_labels = max_labels[end]
    current_labels = Vector{Array{Float32,4}}(undef,l)
    for i = 1:l
        temp = zeros(Float32,l_labels)
        ind_temp = data_labels[current_inds[i]]
        temp[ind_temp] = 1
        current_labels[i] = permutedims(reshape(temp,:,1,1,1),[2,3,1,4])
    end
    # Catenating inputs and labels
    current_input_cat = reduce(cat4,current_input)[:,:,:,:]
    current_labels_cat = reduce(cat4,current_labels)
    # Form a minibatch
    minibatch = (current_input_cat,current_labels_cat)
    return minibatch
end

function make_minibatch_classification_dense(data_input::Vector{Array{Float32,3}},data_labels::Vector{Int32},
        max_labels::Vector{Int32},batch_size::Int64,inds_start::Vector{Int64},
        inds_all::Vector{Int64},i::Int64)
    ind = inds_start[i]
    # First and last minibatch indices
    ind1 = ind+1
    ind2 = ind+batch_size
    # Get inputs and labels
    current_inds = inds_all[ind1:ind2]
    current_input = data_input[current_inds]
    l = length(current_inds)
    l_labels = max_labels[end]
    current_labels = Vector{Array{Float32,2}}(undef,l)
    for i = 1:l
        temp = zeros(Float32,l_labels)
        ind_temp = data_labels[current_inds[i]]
        temp[ind_temp] = 1
        current_labels[i] = reshape(temp,:,1)
    end
    # Catenating inputs and labels
    current_input_cat = reduce(cat4,current_input)[:,:,:,:]
    current_labels_cat = reduce(hcat,current_labels)
    # Form a minibatch
    minibatch = (current_input_cat,current_labels_cat)
    return minibatch
end

function make_minibatch_generic(data_input::Vector{Array{Float32,3}},data_labels::Vector{Vector{Float32}},
        max_labels::Vector{Int32},batch_size::Int64,inds_start::Vector{Int64},
        inds_all::Vector{Int64},i::Int64)
    ind = inds_start[i]
    # First and last minibatch indices
    ind1 = ind+1
    ind2 = ind+batch_size
    # Get inputs and labels
    current_inds = inds_all[ind1:ind2]
    current_input = data_input[current_inds]
    current_labels = data_labels[current_inds]
    # Catenating inputs and labels
    input_cat = reduce(cat4,current_input)[:,:,:,:]
    labels_cat = reduce(hcat,current_labels)
    # Form a minibatch
    minibatch = (input_cat,labels_cat)
    return minibatch
end

function make_minibatch_generic(data_input::Vector{Array{Float32,3}},data_labels_bool::Vector{BitArray{3}},
        max_labels::Vector{Int32},batch_size::Int64,inds_start::Vector{Int64},
        inds_all::Vector{Int64},i::Int64)
    ind = inds_start[i]
    # First and last minibatch indices
    ind1 = ind+1
    ind2 = ind+batch_size
    # Get inputs and labels
    current_inds = inds_all[ind1:ind2]
    current_input = data_input[current_inds]
    current_labels_bool = data_labels_bool[current_inds]
    current_labels = convert(Vector{Array{Float32,3}},current_labels_bool)
    # Catenating inputs and labels
    input_cat = reduce(cat4,current_input)[:,:,:,:]
    labels_cat = reduce(cat4,current_labels)[:,:,:,:]
    # Form a minibatch
    minibatch = (input_cat,labels_cat)
    return minibatch
end

#---

# Reset training related data accumulators
function reset_training_data(training_plot_data::TrainingPlotData,
        training_results_data::TrainingResultsData)
    training_results_data.accuracy = Float32[]
    training_results_data.loss = Float32[]
    training_results_data.test_accuracy = Float32[]
    training_results_data.test_loss = Float32[]
    training_plot_data.iteration = 0
    training_plot_data.epoch = 0
    training_plot_data.iterations_per_epoch = 0
    training_plot_data.starting_time = now()
    training_plot_data.max_iterations = 0
    training_plot_data.learning_rate_changed = false
    return nothing
end
function clean_up_training(training_plot_data::TrainingPlotData)
    training_plot_data.iteration = 0
    training_plot_data.epoch = 0
    training_plot_data.iterations_per_epoch = 0
    training_plot_data.starting_time = now()
    training_plot_data.max_iterations = 0
    training_plot_data.learning_rate_changed = false
end

#---

# Returns an optimiser with preset parameters
function get_optimiser(training::Training)
    # List of possible optimisers
    optimisers = (Descent,Momentum,Nesterov,RMSProp,ADAM,
        RADAM,AdaMax,ADAGrad,ADADelta,AMSGrad,NADAM,ADAMW)
    # Get optimiser index
    optimiser_ind = training.Options.Hyperparameters.optimiser[2]
    # Get optimiser parameters
    parameters_in =
        training.Options.Hyperparameters.optimiser_params[optimiser_ind]
    # Get learning rate
    learning_rate = training.Options.Hyperparameters.learning_rate
    # Collect optimiser parameters and learning rate
    if length(parameters_in)==0
        parameters = [learning_rate]
    elseif length(parameters_in)==1
        parameters = [learning_rate,parameters_in[1]]
    elseif length(parameters_in)==2
        parameters = [learning_rate,(parameters_in[1],parameters_in[2])]
    else
        parameters = [learning_rate,(parameters_in[1],parameters_in[2]),parameters_in[3]]
    end
    # Get optimiser function
    optimiser_func = optimisers[optimiser_ind]
    # Initialize optimiser with parameters
    optimiser = optimiser_func(parameters...)
    return optimiser
end

#---
function minibatch_part(make_minibatch,data_input,data_labels,max_labels,epochs,num,inds_start,inds_all,
        counter,run_test,data_input_test,data_labels_test,inds_start_test,inds_all_test,counter_test,
        num_test,batch_size,minibatch_channel,minibatch_test_channel,testing_mode,abort)
    epoch_idx = 1
    iteration_local = 0
    iteration_test_local = 0
    # Data preparation
    while epoch_idx<=epochs[]
        # Shuffle indices
        inds_start_sh = shuffle!(inds_start)
        inds_all_sh = shuffle!(inds_all)
        if run_test
            inds_start_test_sh = shuffle!(inds_start_test)
            inds_all_test_sh = shuffle!(inds_all_test)
        end
        cnt = 0
        while true
            while true
                numel_channel = (iteration_local-counter.iteration)
                if numel_channel<10
                    iteration_local += 1
                    cnt += 1
                    minibatch = make_minibatch(data_input,data_labels,max_labels,batch_size,
                        inds_start_sh,inds_all_sh,cnt)
                    put!(minibatch_channel,minibatch)
                    break
                elseif testing_mode[]
                    break
                else
                    sleep(0.01)
                end
            end
            if run_test && testing_mode[]
                cnt_test = 0
                
                while true
                    numel_test_channel = (iteration_test_local-counter_test.iteration)
                    if numel_test_channel<10
                        cnt_test += 1
                        iteration_test_local += 1
                        minibatch = make_minibatch(data_input_test,data_labels_test,max_labels,batch_size,
                            inds_start_test_sh,inds_all_test_sh,cnt_test)
                        put!(minibatch_test_channel,minibatch)
                    else
                        sleep(0.01)
                    end
                    if cnt_test==num_test
                        Threads.atomic_xchg!(testing_mode, false)
                        break
                    end
                end
            end
            if abort[]
                return nothing
            end
            if cnt==num
                break
            end
        end
        # Update epoch counter
        epoch_idx += 1
    end
    return nothing
end

function check_modifiers(model_data,model,model_name,accuracy_vector,
        loss_vector,allow_lr_change,composite,opt,num,epochs,max_iterations,
        num_tests,modifiers_channel,abort;gpu=false)
    while isready(modifiers_channel)
        modifs = fix_QML_types(take!(modifiers_channel))
        modif1::String = modifs[1]
        if modif1=="stop"
            Threads.atomic_xchg!(abort, true)
            # Save model
            if gpu==true
                model_data.model = cpu(model)
            else
                model_data.model = model
            end
            save_model_main(model_data,model_name)
            break
        elseif modif1=="learning rate"
            if allow_lr_change
                if composite
                    opt[1].eta = convert(Float64,modifs[2])
                else
                    opt.eta = convert(Float64,modifs[2])
                end
            end
        elseif modif1=="epochs"
            new_epochs::Int64 = convert(Int64,modifs[2])
            new_max_iterations::Int64 = convert(Int64,new_epochs*num)
            Threads.atomic_xchg!(epochs, new_epochs)
            Threads.atomic_xchg!(max_iterations, new_max_iterations)
            resize!(accuracy_vector,max_iterations[])
            resize!(loss_vector,max_iterations[])
        elseif modif1=="testing frequency"
            new_frequency_times::Float64 = modifs[2]
            num_tests::Float64 = convert(Float64,floor(num/new_frequency_times))
        end
    end
    return num_tests
end

function training_part(model_data,model,model_name,opt,accuracy,loss,T_out,move_f,
        accuracy_vector,loss_vector,counter,accuracy_test_vector,loss_test_vector,
        iteration_test_vector,counter_test,num_test,epochs,num,max_iterations,
        num_tests,allow_lr_change,composite,run_test,minibatch_channel,
        minibatch_test_channel,channels,use_GPU,testing_mode,abort)
    epoch_idx = 1
    while epoch_idx<=epochs[]
        iteration_global_counter = 0
        for i = 1:num
            # Prepare training data
            local minibatch_data::eltype(minibatch_channel.data)
            while true
                # Update parameters or abort if needed
                if isready(channels.training_modifiers)
                    num_tests = check_modifiers(model_data,model,model_name,
                        accuracy_vector,loss_vector,allow_lr_change,composite,opt,num,epochs,
                        max_iterations,num_tests,channels.training_modifiers,abort;gpu=use_GPU)
                    if abort[]==true
                        return nothing
                    end
                end
                if isready(minibatch_channel)
                    minibatch_data = take!(minibatch_channel)
                    break
                else
                    sleep(0.01)
                end
            end
            counter()
            iteration = counter.iteration
            input_data = move_f(minibatch_data[1])
            actual = move_f(minibatch_data[2])
            # Calculate gradient
            local predicted::T_out
            local loss_val::Float32
            ps = Flux.Params(Flux.params(model))
            gs = gradient(ps) do
                predicted = model(input_data)
                loss_val = loss(predicted,actual)
            end
            # Update weights
            Flux.Optimise.update!(opt,ps,gs)
            # Calculate accuracy
            accuracy_val = accuracy(predicted,actual)
            # Return training information
            put!(channels.training_progress,["Training",accuracy_val,loss_val])
            accuracy_vector[iteration] = accuracy_val
            loss_vector[iteration] = loss_val
            # Testing part
            if run_test
                training_started_cond = i==1 && epoch_idx==1
                num_tests_cond = i>iteration_global_counter*ceil(num/num_tests)
                training_finished_cond = iteration==(max_iterations[]-1)
                # Test if testing frequency reached or training is done
                if num_tests_cond ||  training_started_cond || training_finished_cond
                    iteration_global_counter += 1
                    Threads.atomic_xchg!(testing_mode, true)
                    # Calculate test accuracy and loss
                    data_test = test(model,accuracy,loss,minibatch_test_channel,counter_test,num_test,move_f)
                    # Return testing information
                    put!(channels.training_progress,["Testing",data_test...,iteration])
                    push!(accuracy_test_vector,data_test[1])
                    push!(loss_test_vector,data_test[2])
                    push!(iteration_test_vector,iteration)
                end
            end
            GC.safepoint()
            cleanup!(predicted)
        end
        # Update epoch counter
        epoch_idx += 1
        # Save model
        model_data.model = cpu(model)
        save_model_main(model_data,model_name)
    end
    return nothing
end

function test(model::Chain,accuracy::Function,loss::Function,minibatch_test_channel::Channel,
        counter_test,num_test::Int64,move_f)
    test_accuracy = Vector{Float32}(undef,num_test)
    test_loss = Vector{Float32}(undef,num_test)
    local minibatch_test_data::eltype(minibatch_test_channel.data)
    for j=1:num_test
        while true
            # Update parameters or abort if needed
            if isready(channels.training_modifiers)
                num_tests = check_modifiers(model_data,model,model_name,
                    accuracy_vector,loss_vector,allow_lr_change,composite,opt,num,epochs,
                    max_iterations,num_tests,channels.training_modifiers,abort;gpu=use_GPU)
                if abort[]==true
                    return nothing
                end
            end
            if isready(minibatch_test_channel)
                minibatch_test_data = take!(minibatch_test_channel)
                break
            else
                sleep(0.01)
            end
        end
        # Update test counter
        counter_test()
        test_minibatch = move_f.(minibatch_test_data)
        predicted = model(test_minibatch[1])
        actual = test_minibatch[2]
        test_accuracy[j] = accuracy(predicted,actual)
        test_loss[j] = loss(predicted,actual)
        cleanup!(predicted)
    end
    data = [mean(test_accuracy),mean(test_loss)]
    return data
end


function check_lr_change(opt,composite)
    if !composite
        allow_lr_change = hasproperty(opt, :eta)
    else
        allow_lr_change = hasproperty(opt2, :eta)
    end
    return convert(Bool,allow_lr_change)
end

function train!(model_data::ModelData,training_data::TrainingData,training::Training,
        args::HyperparametersTraining,opt,accuracy::Function,loss::Function,
        train_set::Tuple{T1,T2},test_set::Tuple{T1,T2},testing_times::Float64,
        use_GPU::Bool,channels::Channels) where {T1<:Vector{Array{Float32,3}},
        T2<:Union{Vector{BitArray{3}},Vector{Int32},Vector{Vector{Float32}}}}
    # Initialize constants
    epochs = Threads.Atomic{Int64}(args.epochs)
    batch_size = args.batch_size
    accuracy_vector = Vector{Float32}(undef,0)
    loss_vector = Vector{Float32}(undef,0)
    accuracy_test_vector = Vector{Float32}(undef,0)
    loss_test_vector = Vector{Float32}(undef,0)
    iteration_test_vector = Vector{Int64}(undef,0)
    max_iterations = Threads.Atomic{Int64}(0)
    counter = Counter()
    counter_test = Counter()
    run_test = length(test_set[1])!=0
    composite = hasproperty(opt, :os)
    allow_lr_change = check_lr_change(opt,composite)
    abort = Threads.Atomic{Bool}(false)
    testing_mode = Threads.Atomic{Bool}(true)
    model_name = string("models/",training.name,".model")
    output_N = length(model_data.output_size) + 1
    # Initialize data
    data_input = train_set[1]
    data_labels = train_set[2]
    num_data = length(data_input)
    inds_start,inds_all,num = make_minibatch_inds(num_data,batch_size)
    num_tests = num/testing_times
    data_input_test = test_set[1]
    data_labels_test = test_set[2]
    num_data_test = length(data_input_test)
    inds_start_test,inds_all_test,num_test = make_minibatch_inds(num_data_test,batch_size)
    Threads.atomic_xchg!(max_iterations, epochs[]*num)
    # Return epoch information
    resize!(accuracy_vector,max_iterations[])
    resize!(loss_vector,max_iterations[])
    put!(channels.training_progress,[epochs[],num,max_iterations[]])
    max_labels = Vector{Int32}(undef,0)
    if settings.problem_type==:Classification && settings.input_type==:Image
        push!(max_labels,(1:length(model_data.classes))...)
    end
    # Make channels
    minibatch_channel = Channel{Tuple{Array{Float32,4},Array{Float32,output_N}}}(Inf)
    minibatch_test_channel = Channel{Tuple{Array{Float32,4},Array{Float32,output_N}}}(Inf)
    # Data preparation thread
    if settings.problem_type==:Classification
        if output_N==2
            make_minibatch = make_minibatch_classification_dense
        else
            make_minibatch = make_minibatch_classification_conv
        end
    else
        make_minibatch = make_minibatch_generic
    end
    Threads.@spawn minibatch_part(make_minibatch,data_input,data_labels,max_labels,epochs,num,inds_start,
        inds_all,counter,run_test,data_input_test,data_labels_test,inds_start_test,
        inds_all_test,counter_test,num_test,batch_size,minibatch_channel,minibatch_test_channel,testing_mode,abort)
    # Training thread
    if use_GPU
        T_out = CuArray{Float32,output_N}
        model = Flux.gpu(model_data.model)
        move_f = CuArray
    else
        T_out = Array{Float32,output_N}
        model = model_data.model       
        move_f = Identity()
    end
    training_part(model_data,model,model_name,opt,accuracy,loss,T_out,move_f,accuracy_vector,
        loss_vector,counter,accuracy_test_vector,loss_test_vector,iteration_test_vector,
        counter_test,num_test,epochs,num,max_iterations,num_tests,allow_lr_change,composite,
        run_test,minibatch_channel,minibatch_test_channel,channels,use_GPU,testing_mode,abort)
    # Return training information
    resize!(accuracy_vector,counter.iteration)
    resize!(loss_vector,counter.iteration)
    data = (accuracy_vector,loss_vector,accuracy_test_vector,loss_test_vector,iteration_test_vector)
    return data
end

function get_data_struct(training_data::TrainingData)
    if settings.problem_type==:Classification
        data = training_data.ClassificationData
    elseif settings.problem_type==:Regression
        data = training_data.RegressionData
    elseif settings.problem_type==:Segmentation
        data = training_data.SegmentationData
    end
    return data
end

# Main training function
function train_main(settings::Settings,training_data::TrainingData,testing_data::TestingData,
        model_data::ModelData,channels::Channels)
    # Initialization
    GC.gc()
    training = settings.Training
    training_options = training.Options
    training_plot_data = training_data.PlotData
    training_results_data = training_data.Results
    args = training_options.Hyperparameters
    use_GPU = false
    if training.Options.General.allow_GPU
        if has_cuda()
            use_GPU = true
        else
            @warn "No CUDA capable device was detected. Using CPU instead."
        end
    end
    reset_training_data(training_plot_data,training_results_data)
    # Preparing train and test sets
    data = get_data_struct(training_data)
    train_set, test_set = get_sets(data,training)
    # Setting functions and parameters
    opt = get_optimiser(training)
    if training.Options.General.manual_weight_accuracy
        ws = get_weigths(training,model_data.classes)
    else
        ws = get_weigths(training,training_data,model_data.classes)
    end
    accuracy = get_accuracy_func(settings,ws)
    loss = model_data.loss
    testing_times = training_options.General.num_tests
    # Run training
    data = train!(model_data,training_data,training,args,opt,accuracy,loss,
        train_set,test_set,testing_times,use_GPU,channels)
    # Clean up
    clean_up_training(training_plot_data)
    # Return training results
    put!(channels.training_results,(model_data.model,data...))
    return nothing
end
function train_main2(settings::Settings,training_data::TrainingData,testing_data::TestingData,
        model_data::ModelData,channels::Channels)
    Threads.@spawn train_main(settings,training_data,testing_data,model_data,channels)
end
