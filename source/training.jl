
# Set training starting time
function set_training_starting_time_main(training_plot_data::Training_plot_data)
    training_plot_data.starting_time = now()
    return nothing
end
set_training_starting_time() =
    set_training_starting_time_main(training_plot_data)

# Calculates the time elapsed from the begining of training
function training_elapsed_time_main(training_plot_data::Training_plot_data)
    dif = (now() - training_plot_data.starting_time).value
    hours = string(Int64(round(dif/3600000)))
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
# Augments images using rotation and mirroring
function augment(k::Int64,img::Array{Float32,2},label::BitArray{3},
        num_angles::Int64,pix_num::Tuple{Int64,Int64},min_fr_pix::Float64)
    lim = prod(pix_num)*min_fr_pix
    angles = range(0,stop=2*pi,length=num_angles+1)
    angles = angles[1:end-1]
    num = length(angles)
    imgs_out = Vector{Vector{Array{Float32,3}}}(undef,num)
    labels_out = Vector{Vector{BitArray{3}}}(undef,num)
    Threads.@threads for g = 1:num
        angle_val = angles[g]
        img2 = rotate_img(img,angle_val)
        label2 = rotate_img(label,angle_val)
        num1 = Int64(floor(size(label2,1)/(pix_num[1]*0.9)))
        num2 = Int64(floor(size(label2,2)/(pix_num[2]*0.9)))
        step1 = Int64(floor(size(label2,1)/num1))
        step2 = Int64(floor(size(label2,2)/num2))
        num_batch = 2*(num1-1)*(num2-1)
        img_temp = Vector{Array{Float32}}(undef,0)
        label_temp = Vector{BitArray{3}}(undef,0)
        Threads.@threads for h = 1:2
            if h==1
                img3 = img2
                label3 = label2
            elseif h==2
                img3 = reverse(img2, dims = 2)
                label3 = reverse(label2, dims = 2)
            end
            for i = 1:num1-1
                for j = 1:num2-1
                    ymin = (i-1)*step1+1;
                    xmin = (j-1)*step2+1;
                    I1 = label3[ymin:ymin+pix_num[1]-1,xmin:xmin+pix_num[2]-1,:]
                    if sum(I1)<lim
                        continue
                    end
                    I2 = img3[ymin:ymin+pix_num[1]-1,xmin:xmin+pix_num[2]-1,:]
                    push!(label_temp,I1)
                    push!(img_temp,I2)
                end
            end
        end
        imgs_out[g] = img_temp
        labels_out[g] = label_temp
    end
    imgs_out_flat = reduce(vcat,imgs_out)
    labels_out_flat = convert(Vector{Array{Float32,3}},reduce(vcat,labels_out))
    data_out = (imgs_out_flat,labels_out_flat)
    return data_out
end

# Prepare data for training
function prepare_training_data_main(url_imgs::Vector{String},url_labels::Vector{String},
        training::Training,model_data::Model_data)
    # Return of features are empty
    if isempty(model_data.features)
        @info "Empty features"
        return nothing,nothing
    elseif isempty(url_imgs)
        @info "Empty urls"
        return nothing,nothing
    end
    # Initialize
    features = model_data.features
    type = training.type
    options = training.Options
    min_fr_pix = options.Processing.min_fr_pix
    num_angles = options.Processing.num_angles
    # Get output image size for dimensions 1 and 2
    pix_num = model_data.input_size[1:2]
    # Get feature data
    labels_color,labels_incl,border = get_feature_data(features)
    # Load images and labels
    imgs = load_images(url_imgs)
    labels = load_images(url_labels)
    # Get number of images
    num = length(imgs)
    # Initialize accumulators
    data_input = Vector{Vector{Array{Float32,3}}}(undef,num)
    data_labels = Vector{Vector{BitArray{3}}}(undef,num)
    # Make imput images
    Threads.@threads for k = 1:num
        # Get current image and label
        img = imgs[k]
        label = labels[k]
        # Convert to grayscale
        img = image_to_gray_float(img)
        # Crope to remove black background
        # img,label = correct_view(img,label)
        # Convert BitArray labels to Array{Float32}
        label = label_to_bool(label,labels_color,labels_incl,border)
        # Augment images
        data_input[k],data_labels[k] = augment(k,img,label,num_angles,pix_num,min_fr_pix)
    end
    # Flatten input images and labels array
    data_out_input = reduce(vcat,data_input)
    data_out_labels = convert(Vector{Array{Float32,3}},reduce(vcat,data_labels))
    return data_out_input, data_out_labels
end
prepare_training_data(url_imgs,url_labels) =
    prepare_training_data_main(url_imgs,url_labels,training,model_data)

# Creates data sets for training and testing
function get_train_test(data_inputs::Vector{Array{Float32,3}},
        data_labels::Vector{Array{Float32,3}},training::Training)
    # Get the number of elements
    num = length(data_inputs)
    # Get shuffle indices
    inds = randperm(num)
    # Shuffle using randomized indices
    data_inputs = data_inputs[inds]
    data_labels = data_labels[inds]
    # Get fraction of data used for testing
    test_fraction = training.Options.General.test_data_fraction
    # Get index after which all data is for testing
    ind = Int64(round((1-test_fraction)*num))
    # Separate data into training and testing data
    train_set = (data_inputs[1:ind],data_labels[1:ind])
    test_set = (data_inputs[ind+1:end],data_labels[ind+1:end])
    return train_set, test_set
end

# Creates a minibatch
function make_minibatch(set::Tuple{Vector{Array{Float32,3}},Vector{Array{Float32,3}}},
        batch_size::Int64)
    # Calculate final index
    num = length(set[1]) - batch_size
    val = max(0.0,floor(num/batch_size))
    finish = Int64(val*batch_size)
    # Get a vector of initial-1 indices
    range_array = Vector(0:batch_size:finish)
    # Shuffle indices
    inds = shuffle!(range_array)
    # Separate set into inputs and labels
    data_input = set[1]
    data_labels = set[2]
    # Initialize accumulator for minibatches
    num = length(inds)
    set_minibatch = Vector{Tuple{Array{Float32,4},
        Array{Float32,4}}}(undef,num)
    Threads.@threads for i=1:num
        ind = inds[i]
        # First and last minibatch indices
        ind1 = ind+1
        ind2 = ind+batch_size
        # Get inputs and labels
        current_input = data_input[ind1:ind2]
        current_labels = data_labels[ind1:ind2]
        # Catenating inputs and labels
        current_input_cat = reduce(cat4,current_input)
        current_labels_cat = reduce(cat4,current_labels)
        # Form a minibatch
        minibatch = (current_input_cat,current_labels_cat)
        set_minibatch[i] = minibatch
    end
    return set_minibatch
end

#---

# Reset training related data accumulators
function reset_training_data(training_plot_data::Training_plot_data)
    training_plot_data.accuracy = Float32[]
    training_plot_data.loss = Float32[]
    training_plot_data.test_accuracy = Float32[]
    training_plot_data.test_loss = Float32[]
    training_plot_data.iteration = 0
    training_plot_data.epoch = 0
    training_plot_data.iterations_per_epoch = 0
    training_plot_data.starting_time = now()
    return nothing
end

# Move model between CPU and GPU
function move(model,target::Union{typeof(cpu),typeof(gpu)})
    model_moved = []
    if model isa Chain
        for i = 1:length(model)
            # If model branches out, then apply function also to each branch
            if model[i] isa Parallel
                layers = model[i].layers
                new_layers = Array{Any}(undef,length(layers))
                for i = 1:length(layers)
                    new_layers[i] = move(layers[i],target)
                end
                new_layers = (new_layers...,)
                push!(model_moved,target(Parallel(new_layers)))
            else
                push!(model_moved,target(model[i]))
            end
        end
    else
        push!(model_moved,target(model))
    end
    # If model contains more than one layer, then form a chain
    if length(model_moved)==1
        model_moved = model_moved[1]
    else
        model_moved = target(Chain(model_moved...))
    end
    return model_moved
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
    if length(parameters_in)==1
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
# Training on CPU
function train_CPU!(model::Chain,accuracy::Function,loss::Function,
        args::Hyperparameters_training,testing_frequency::Float64,
        train_set::Tuple{Vector{Array{Float32,3}},Vector{Array{Float32,3}}},
        test_set::Tuple{Vector{Array{Float32,3}},Vector{Array{Float32,3}}},
        opt,channels::Channels)
    # Initialize
    epochs = args.epochs
    batch_size = args.batch_size
    accuracy_array = Vector{Float32}(undef,0)
    loss_array = Vector{Float32}(undef,0)
    test_accuracy = Vector{Float32}(undef,0)
    test_loss = Vector{Float32}(undef,0)
    test_iteration = Vector{Int64}(undef,0)
    max_iterations = 0
    iteration = 1
    epoch_idx = 1
    num_test = length(test_set[1])
    run_test = num_test!=0
    # Run training for n epochs
    while epoch_idx<epochs
        # Make minibatches
        num_test = length(test_set[1])
        run_test = num_test!=0
        train_batches = make_minibatch(train_set,batch_size)
        if run_test
            test_batches = make_minibatch(test_set,batch_size)
            num_test = length(test_batches)
        else
            test_batches = Vector{Tuple{Array{Float32,4},Array{Float32,4}}}(undef,0)
        end
        num = length(train_batches)
        # Return epoch information
        if epoch_idx==1
            testing_frequency = num/testing_frequency
            max_iterations = epochs*num
            put!(channels.training_progress,[epochs,num,max_iterations])
        end
        last_test = 0
        # Run iteration
        for i=1:num
            # Abort or update parameters if needed
            if isready(channels.training_modifiers)
                modifs::Union{Vector{String},Vector{String,Float64},
                    Vector{String,Int64}} = fix_QML_types(take!(channels.training_modifiers))
                while isready(channels.training_modifiers)
                    modifs = fix_QML_types(take!(channels.training_modifiers))
                end
                modif1::String = modifs[1]
                if modif1=="stop"
                    data = (accuracy_array,loss_array,
                        test_accuracy,test_loss,test_iteration)
                    return data
                elseif modif1=="learning rate"
                    opt.eta = convert(Float64,modifs[2])
                elseif modif1=="epochs"
                    epochs::Int64 = convert(Int64,modifs[2])
                elseif modif1=="testing frequency"
                    testing_frequency::Int64 = convert(Int64,floor(num/modifs[2]))
                end
            end
            # Prepare training data
            train_minibatch = train_batches[i]
            input_data = train_minibatch[1]
            actual = train_minibatch[2]
            # Initialize so we get them returned by the gradient function
            local loss_val::Float32
            local predicted::Array{Float32,4}

            # Calculate gradient
            ps = Flux.Params(Flux.params(model))
            gs = gradient(ps) do
              predicted = model(input_data)
              loss_val = loss(predicted,actual)
            end
            # Update weights
            Flux.Optimise.update!(opt,ps,gs)
            # Calculate accuracy
            accuracy_val::Float32 = accuracy(predicted,actual)
            # Return training information
            data_temp = [accuracy_val,loss_val]
            put!(channels.training_progress,["Training",data_temp...])
            push!(accuracy_array,data_temp[1])
            push!(loss_array,data_temp[2])
            # Testing part
            if run_test
                testing_frequency_cond = ceil(i/testing_frequency)>last_test
                training_finished_cond = iteration==(max_iterations-1)
                # Test if testing frequency reached or training is done
                if testing_frequency_cond || training_finished_cond
                    # Calculate test accuracy and loss
                    data_test = test_CPU(model,accuracy,loss,channels,
                        test_batches,length(test_batches))
                    # Return testing information
                    put!(channels.training_progress,["Testing",data_test...,iteration])
                    push!(test_accuracy,data_test[1])
                    push!(test_loss,data_test[2])
                    push!(test_iteration,iteration)
                    # Update test counter
                    last_test += 1
                end
            end
            # Update iteration counter
            iteration+=1
            # Needed to avoid out of memory issue
            @everywhere GC.safepoint()
        end
        # Update epoch counter
        epoch_idx += 1
        # Needed to avoid out of memory issue
        @everywhere GC.gc()
    end
    # Return training information
    data = (accuracy_array,loss_array,test_accuracy,test_loss,test_iteration)
    return data
end

# Training on GPU
function train_GPU!(model::Chain,accuracy::Function,loss::Function,
        args::Hyperparameters_training,testing_frequency::Float64,
        train_set::Tuple{Vector{Array{Float32,3}},Vector{Array{Float32,3}}},
        test_set::Tuple{Vector{Array{Float32,3}},Vector{Array{Float32,3}}},
        opt,channels::Channels)
    # Initialize
    model = move(model,gpu)
    epochs = args.epochs
    batch_size = args.batch_size
    accuracy_array = Vector{Float32}(undef,0)
    loss_array = Vector{Float32}(undef,0)
    test_accuracy = Vector{Float32}(undef,0)
    test_loss = Vector{Float32}(undef,0)
    test_iteration = Vector{Int64}(undef,0)
    max_iterations = 0
    iteration = 1
    epoch_idx = 1
    num_test = length(test_set[1])
    run_test = num_test!=0
    # Run training for n epochs
    while epoch_idx<=epochs
        # Make minibatches
        train_batches = make_minibatch(train_set,batch_size)
        if run_test
            test_batches = make_minibatch(test_set,batch_size)
            num_test = length(test_batches)
        else
            test_batches = Vector{Tuple{Array{Float32,4},Array{Float32,4}}}(undef,0)
        end
        num = length(train_batches)
        last_test = 0
        # Return epoch information
        if epoch_idx==1
            testing_frequency = num/testing_frequency
            max_iterations = epochs*num
            put!(channels.training_progress,[epochs,num,max_iterations])
        end
        # Run iteration
        for i=1:num
            # Abort or update parameters if needed
            if isready(channels.training_modifiers)
                modifs = fix_QML_types(take!(channels.training_modifiers))
                while isready(channels.training_modifiers)
                    modifs = fix_QML_types(take!(channels.training_modifiers))
                end
                modif1::String = modifs[1]
                if modif1=="stop"
                    data = (accuracy_array,loss_array,
                        test_accuracy,test_loss,test_iteration)
                    return data
                elseif modif1=="learning rate"
                    opt.eta = convert(Float64,modifs[2])
                elseif modif1=="epochs"
                    epochs::Int64 = convert(Int64,modifs[2])
                elseif modif1=="testing frequency"
                    testing_frequency::Float64 = floor(num/modifs[2])
                end
            end
            # Prepare training data
            train_minibatch = CuArray.(train_batches[i])
            input_data = train_minibatch[1]
            actual = train_minibatch[2]
            # Initialize so we get them returned by the gradient function
            local loss_val::Float32
            local predicted::CuArray{Float32,4}
            # Calculate gradient
            ps = Flux.Params(Flux.params(model))
            gs = gradient(ps) do
              predicted = model(input_data)
              loss_val = loss(predicted,actual)
            end
            # Update weights
            Flux.Optimise.update!(opt,ps,gs)
            # Calculate accuracy
            accuracy_val::Float32 = accuracy(predicted,actual)
            # Return training information
            data_temp = [accuracy_val,loss_val]
            put!(channels.training_progress,["Training",data_temp...])
            push!(accuracy_array,data_temp[1])
            push!(loss_array,data_temp[2])
            # Needed to avoid GPU out of memory issue
            CUDA.unsafe_free!(predicted)
            # Testing part
            if run_test
                testing_frequency_cond = ceil(i/testing_frequency)>last_test
                training_finished_cond = iteration==(max_iterations-1)
                # Test if testing frequency reached or training is done
                if testing_frequency_cond || training_finished_cond
                    # Calculate test accuracy and loss
                    data_test = test_GPU(model,accuracy,loss,channels,test_batches,num_test)
                    # Return testing information
                    put!(channels.training_progress,["Testing",data_test...,iteration])
                    push!(test_accuracy,data_test[1])
                    push!(test_loss,data_test[2])
                    push!(test_iteration,iteration)
                    # Update test counter
                    last_test += 1
                end
            end
            # Update iteration counter
            iteration+=1
            # Needed to avoid GPU out of memory issue
            @everywhere GC.safepoint()
        end
        # Update epoch counter
        epoch_idx += 1
        # Needed to avoid GPU out of memory issue
        @everywhere GC.gc()
    end
    # Return training information
    data = (accuracy_array,loss_array,test_accuracy,test_loss,test_iteration)
    return data
end

# Testing on CPU
function test_CPU(model::Chain,accuracy::Function,loss::Function,channels::Channels,
        test_batches::Array{Tuple{Array{Float32,4},Array{Float32,4}},1},num_test::Int64)
    test_accuracy = Vector{Float32}(undef,num_test)
    test_loss = Vector{Float32}(undef,num_test)
    for j=1:num_test
        test_minibatch = test_batches[j]
        predicted = model(test_minibatch[1])
        actual = test_minibatch[2]
        test_accuracy[j] = accuracy(predicted,actual)
        test_loss[j] = loss(predicted,actual)
    end
    data = [mean(test_accuracy),mean(test_loss)]
    return data
end

# Testing on GPU
function test_GPU(model::Chain,accuracy::Function,loss::Function,channels::Channels,
        test_batches::Array{Tuple{Array{Float32,4},Array{Float32,4}},1},num_test::Int64)
    test_accuracy = Vector{Float32}(undef,num_test)
    test_loss = Vector{Float32}(undef,num_test)
    for j=1:num_test
        test_minibatch = CuArray.(test_batches[j])
        predicted = model(test_minibatch[1])
        actual = test_minibatch[2]
        test_accuracy[j] = accuracy(predicted,actual)
        test_loss[j] = loss(predicted,actual)
    end
    data = [mean(test_accuracy),mean(test_loss)]
    return data
end

# Main training function
function train_main(data_inputs::Vector{Array{Float32,3}},data_labels::Vector{Array{Float32,3}},
        training_plot_data::Training_plot_data,settings::Settings,
        model_data::Model_data,channels::Channels)
    # Initialization
    training = settings.Training
    training_options = training.Options
    args = training_options.Hyperparameters
    use_GPU = settings.Options.Hardware_resources.allow_GPU && has_cuda()
    reset_training_data(training_plot_data)
    # Preparing train and test sets
    train_set, test_set = get_train_test(data_inputs,data_labels,training)
    # Setting functions and parameters
    opt = get_optimiser(training)
    accuracy = get_accuracy_func(training)
    loss = model_data.loss
    learning_rate = args.learning_rate
    epochs = args.epochs
    testing_frequency = training_options.General.testing_frequency
    model = model_data.model
    # Check whether user wants to abort
    if isready(channels.training_modifiers)
        stop_cond::String = fetch(channels.training_modifiers)[1]
        if stop_cond=="stop"
            take!(channels.training_modifiers)
            return nothing
        end
    end
    # Run training
    if use_GPU
        data = train_GPU!(model,accuracy,loss,args,testing_frequency,
            train_set,test_set,opt,channels)
    else
        data = train_CPU!(model,accuracy,loss,args,testing_frequency,
            train_set,test_set,opt,channels)
    end
    # Move model back to CPU if needed
    if use_GPU
        model = move(model,cpu)
    end
    # Save trained model
    model_data.model = model
    save_model_main(model_data,string("models/",training.name,".model"))
    # Return training results
    put!(channels.training_results,(model,data...))
    return nothing
end

function train(data_inputs::Vector{Array{Float32,3}},data_labels::Vector{Array{Float32,3}})
    empty_progress_channel("Training")
    empty_results_channel("Training")
    empty_progress_channel("Training modifiers")
    worker = workers()[end]
    sendto(worker, settings=settings,training_data=training_data,model_data=model_data)
    remote_do(MLGUI.train_main,worker,data_inputs,data_labels,
            MLGUI.training_plot_data,settings,model_data,MLGUI.channels)
    # Launches GUI
    @qmlfunction(
        # Data handling
        get_settings,
        get_results,
        get_progress,
        put_channel,
        # Training related
        set_training_starting_time,
        training_elapsed_time,
        # Other
        yield,
        info,
        time
    )
    load("GUI/TrainingPlot.qml")
    exec()

    while true
        data = get_results("Training")
        if data==true
            return training_results_data
        end
    end
end
