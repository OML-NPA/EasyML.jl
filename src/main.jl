
# Set training starting time

function time()
    date = string(now())
    date = date[1:19]
    date = replace(date,"T"=>" ")
    return date
end

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

#----------------

function make_minibatch(data_input::Vector{Array{Float32,N}},data_labels::Vector{Int32},
        max_labels::Int32,batch_size::Int64,inds_start::Vector{Int64},
        inds_all::Vector{Int64},i::Int64) where N
    ind = inds_start[i]
    # First and last minibatch indices
    ind1 = ind+1
    ind2 = ind+batch_size
    # Get inputs and labels
    current_inds = inds_all[ind1:ind2]
    l = length(current_inds)
    current_input = Vector{Array{Float32,N+1}}(undef,l)
    current_labels = Vector{Array{Float32,2}}(undef,l)
    for j = 1:l
        ind = current_inds[j]
        temp = zeros(Float32,max_labels)
        ind_temp = data_labels[ind]
        temp[ind_temp] = 1
        current_labels[j] = add_dim(temp)
        current_input[j] = add_dim(data_input[ind])
    end
    # Catenating inputs and labels
    ncat = (x,y)->cat(x,y, dims=Val(N+1))
    current_input_cat = reduce(ncat,current_input)
    current_labels_cat = reduce(hcat,current_labels)
    # Form a minibatch
    return (current_input_cat,current_labels_cat)
end

function make_minibatch(data_input::Vector{Array{Float32,N1}},data_labels::Vector{Array{Float32,N2}},
        max_labels::Int32,batch_size::Int64,inds_start::Vector{Int64},
    inds_all::Vector{Int64},i::Int64) where {N1,N2}
    ind = inds_start[i]
    # First and last minibatch indices
    ind1 = ind+1
    ind2 = ind+batch_size
    # Get inputs and labels
    current_inds = inds_all[ind1:ind2]
    l = length(current_inds)
    current_input = Vector{Array{Float32,N1+1}}(undef,l)
    current_labels = Vector{Array{Float32,N2+1}}(undef,l)
    for j = 1:l
        ind = current_inds[j]
        current_labels[j] = add_dim(data_labels[ind])
        current_input[j] = add_dim(data_input[ind])
    end
    # Catenating inputs and labels
    ncat1 = (x,y)->cat(x,y, dims=Val(N1+1))
    ncat2 = (x,y)->cat(x,y, dims=Val(N2+1))
    input_cat = reduce(ncat1,current_input)
    labels_cat = reduce(ncat2,current_labels)
    return (input_cat,labels_cat)
end

function make_minibatch(data_input::Vector{Array{Float32,N1}},data_labels_bool::Vector{BitArray{N2}},
        max_labels::Int32,batch_size::Int64,inds_start::Vector{Int64},
        inds_all::Vector{Int64},i::Int64) where {N1,N2}
    ind = inds_start[i]
    # First and last minibatch indices
    ind1 = ind+1
    ind2 = ind+batch_size
    # Get inputs and labels
    current_inds = inds_all[ind1:ind2]
    l = length(current_inds)
    current_input = Vector{Array{Float32,N1+1}}(undef,l)
    current_labels = Vector{Array{Float32,N2+1}}(undef,l)
    for j = 1:l
        ind = current_inds[j]
        data_labels_temp = convert(Array{Float32,N2},data_labels_bool[ind])
        current_labels[j] = add_dim(data_labels_temp)
        current_input[j] = add_dim(data_input[ind])
    end
    # Catenating inputs and labels
    ncat1 = (x,y)->cat(x,y, dims=Val(N1+1))
    ncat2 = (x,y)->cat(x,y, dims=Val(N2+1))
    input_cat = reduce(ncat1,current_input)
    labels_cat = reduce(ncat2,current_labels)
    # Form a minibatch
    minibatch = (input_cat,labels_cat)
    return minibatch
end

#----------------

# Reset training related data accumulators
function reset_training_data(training_data::TrainingData)
    training_data.warnings = String[]
    training_data.errors = String[]
    training_plot_data = training_data.PlotData
    training_results_data = training_data.Results
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
function get_optimiser(training_options::TrainingOptions)
    # List of possible optimisers
    optimisers = (Descent,Momentum,Nesterov,RMSProp,ADAM,
        RADAM,AdaMax,ADAGrad,ADADelta,AMSGrad,NADAM,ADAMW)
    optimiser_names = (:Descent,:Momentum,:Nesterov,:RMSProp,:ADAM,
        :RADAM,:AdaMax,:ADAGrad,:ADADelta,:AMSGrad,:NADAM,:ADAMW)
    # Get optimiser index
    optimiser_ind = findfirst(training_options.Hyperparameters.optimiser.==optimiser_names)
    # Get optimiser parameters
    parameters_in = training_options.Hyperparameters.optimiser_params
    # Get learning rate
    learning_rate = training_options.Hyperparameters.learning_rate
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

#---Weights---------------------------------------------------------------------

function calculate_weights(counts::Vector{Int64})
    frequencies = counts./sum(counts)
    inv_frequencies = 1 ./frequencies
    weights64 = inv_frequencies./sum(inv_frequencies)
    weights = convert(Vector{Float32},weights64)
    return weights
end

function get_weights(classification_data::ClassificationData)
    data_labels = classification_data.data_labels
    num = classification_data.max_labels
    counts = zeros(Int64,num)
    for data in data_labels
        counts[data] += 1
    end
    weights = calculate_weights(counts)
    return weights
end

function get_weights(regression_data::RegressionData)
    weights = Vector{Float32}(undef,0)
    return weights
end

function get_weights(segmentation_data::SegmentationData)
    data_labels = segmentation_data.data_labels
    num = size(data_labels[1],3)
    counts = zeros(Int64,num)
    for data in data_labels
        counts .+= collect(Iterators.flatten(sum(data,dims = [1,2])))
    end
    weights = calculate_weights(counts)
    return weights
end

#---
function minibatch_part(data_input,data_labels,max_labels,epochs,num,inds_start,inds_all,
        counter,run_test,data_input_test,data_labels_test,inds_start_test,inds_all_test,counter_test,
        num_test,batch_size,minibatch_channel,minibatch_test_channel,testing_mode,abort)
    epoch_idx = 1
    iteration_local = 0
    iteration_test_local = 0
    # Data preparation
    while true
        # Shuffle indices
        inds_start_sh = shuffle!(inds_start)
        inds_all_sh = shuffle!(inds_all)
        if run_test
            inds_start_test_sh = shuffle!(inds_start_test)
            inds_all_test_sh = shuffle!(inds_all_test)
        end
        cnt = 0
        while true
            while epoch_idx<=epochs[]
                numel_channel = (iteration_local-counter.iteration)
                if numel_channel<10
                    iteration_local += 1
                    cnt += 1
                    minibatch = make_minibatch(data_input,data_labels,max_labels,batch_size,
                        inds_start_sh,inds_all_sh,cnt)
                    put!(minibatch_channel,minibatch)
                    break
                elseif run_test && testing_mode[]
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
            sleep(0.01)
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
        loss_vector,allow_lr_change,composite,opt,i,num,epochs,max_iterations,
        num_tests,global_iteration_test,modifiers_channel,abort;gpu=false)
    while isready(modifiers_channel)
        modifs = take!(modifiers_channel)
        modif1 = modifs[1]
        if modif1==0 # stop
            Threads.atomic_xchg!(abort, true)
            # Save model
            if gpu==true
                model_data.model = cpu(model)
            else
                model_data.model = model
            end
            save_model_main(model_data,model_name)
            break
        elseif modif1==1 # learning rate
            if allow_lr_change
                if composite
                    opt[1].eta = convert(Float64,modifs[2])
                else
                    opt.eta = convert(Float64,modifs[2])
                end
            end
        elseif modif1==2 # epochs
            new_epochs::Int64 = convert(Int64,modifs[2])
            new_max_iterations::Int64 = convert(Int64,new_epochs*num)
            Threads.atomic_xchg!(epochs, new_epochs)
            Threads.atomic_xchg!(max_iterations, new_max_iterations)
            resize!(accuracy_vector,max_iterations[])
            resize!(loss_vector,max_iterations[])
        elseif modif1==3 # number of tests
            num_tests::Float64 = modifs[2]
            frequency = num/num_tests
            global_iteration_test = floor(i/frequency)
        end
    end
    return num_tests,global_iteration_test
end

function training_part(model_data,model,model_name,opt,accuracy,loss,T_out,move_f,
        accuracy_vector,loss_vector,counter,accuracy_test_vector,loss_test_vector,
        iteration_test_vector,counter_test,num_test,epochs,num,max_iterations,
        num_tests,allow_lr_change,composite,run_test,minibatch_channel,
        minibatch_test_channel,channels,use_GPU,testing_mode,abort)
    epoch_idx = 1
    while epoch_idx<=epochs[]
        global_iteration_test = 0
        for i = 1:num
            counter()
            iteration = counter.iteration
            # Prepare training data
            local minibatch_data::eltype(minibatch_channel.data)
            while true
                # Update parameters or abort if needed
                if isready(channels.training_modifiers)
                    num_tests,iteration_global_counter = check_modifiers(model_data,model,model_name,
                        accuracy_vector,loss_vector,allow_lr_change,composite,opt,i,num,epochs,
                        max_iterations,num_tests,global_iteration_test,
                        channels.training_modifiers,abort;gpu=use_GPU)
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
            put!(channels.training_progress,("Training",accuracy_val,loss_val,iteration))
            accuracy_vector[iteration] = accuracy_val
            loss_vector[iteration] = loss_val
            # Testing part
            if run_test && num_tests!=0
                training_started_cond = i==1 && epoch_idx==1
                num_tests_cond = i>global_iteration_test*ceil(num/num_tests)
                training_finished_cond = iteration==(max_iterations[])
                # Test if testing frequency reached or training is done
                if num_tests_cond ||  training_started_cond || training_finished_cond
                    global_iteration_test += 1
                    Threads.atomic_xchg!(testing_mode, true)
                    # Calculate test accuracy and loss
                    data_test = test(model,accuracy,loss,minibatch_test_channel,counter_test,num_test,move_f,abort)
                    # Return testing information
                    put!(channels.training_progress,("Testing",data_test...,iteration))
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
        counter_test,num_test::Int64,move_f,abort)
    test_accuracy = Vector{Float32}(undef,num_test)
    test_loss = Vector{Float32}(undef,num_test)
    local minibatch_test_data::eltype(minibatch_test_channel.data)
    for j=1:num_test
        local minibatch_test_data::eltype(minibatch_test_channel)
        while true
            # Abort if needed
            if abort[]==true
                return [0.f0,0.f0]
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

function train!(model_data::ModelData,train_set::Tuple{T1,T2},test_set::Tuple{T1,T2},
        opt,accuracy::Function,loss::Function,all_data::AllData,use_GPU::Bool,
        num_tests::Float64,args::HyperparametersOptions,channels::Channels,
        tasks::Vector{Task}) where {N1,N2,T1<:Vector{Array{Float32,N1}},
        T2<:Union{Array{Int32,N2},Vector{Array{Float32,N2}},Vector{BitArray{N2}}}}
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
    run_test = length(test_set[1])!=0 && num_tests!=0
    composite = hasproperty(opt, :os)
    allow_lr_change = check_lr_change(opt,composite)
    abort = Threads.Atomic{Bool}(false)
    testing_mode = Threads.Atomic{Bool}(true)
    model_name = string("models/",all_data.model_name,".model")
    # Initialize data
    data_input = train_set[1]
    data_labels = train_set[2]
    num_data = length(data_input)
    inds_start,inds_all,num = make_minibatch_inds(num_data,batch_size)
    data_input_test = test_set[1]
    data_labels_test = test_set[2]
    num_data_test = length(data_input_test)
    inds_start_test,inds_all_test,num_test = make_minibatch_inds(num_data_test,batch_size)
    Threads.atomic_xchg!(max_iterations, epochs[]*num)
    # Return epoch information
    resize!(accuracy_vector,max_iterations[])
    resize!(loss_vector,max_iterations[])
    put!(channels.training_start_progress,(epochs[],num,max_iterations[]))
    max_labels = all_data.TrainingData.ClassificationData.max_labels
    # Make channels
    output_N = N2+1
    minibatch_channel = Channel{Tuple{Array{Float32,N1+1},Array{Float32,output_N}}}(Inf)
    minibatch_test_channel = Channel{Tuple{Array{Float32,N1+1},Array{Float32,output_N}}}(Inf)
    # Data preparation thread
    t = Threads.@spawn minibatch_part(data_input,data_labels,max_labels,epochs,num,inds_start,
        inds_all,counter,run_test,data_input_test,data_labels_test,inds_start_test,
        inds_all_test,counter_test,num_test,batch_size,minibatch_channel,minibatch_test_channel,testing_mode,abort)
    push!(tasks,t)
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
    # Stop data preparation thread
    Threads.atomic_xchg!(abort, true)
    # Return training information
    resize!(accuracy_vector,counter.iteration)
    resize!(loss_vector,counter.iteration)
    data = (accuracy_vector,loss_vector,accuracy_test_vector,loss_test_vector,iteration_test_vector)
    return data
end

function cleanup!(x::Array)
    return nothing
end

function cleanup!(x::CuArray)
    CUDA.unsafe_free!(x)
    return nothing
end

function get_data_struct(some_data::Union{TrainingData,TestingData})
    if problem_type()==:Classification
        data = some_data.ClassificationData
    elseif problem_type()==:Regression
        data = some_data.RegressionData
    elseif problem_type()==:Segmentation
        data = some_data.SegmentationData
    end
    return data
end

function test_model(model_data,train_set,errors,use_GPU)
    input_data_raw = train_set[1][1]
    if problem_type()==:Classification
        max_labels = training_data.ClassificationData.max_labels
        label_data = zeros(Float32,max_labels)
        ind = train_set[2][1]
        label_data[ind] = 1
    else
        label_data = train_set[2][1]
    end
    if use_GPU
        model = gpu(model_data.model)
        input_data = CuArray(add_dim(input_data_raw))
    else
        model = model_data.model
        input_data = add_dim(input_data_raw)
    end
    output = model(input_data)
    size_label = size(label_data)
    size_output = size(output)[1:end-1]
    if size_label!=size_output
        err = string("Label data has size ",size_label," while data returned by the model has size ",size_output,".")
        push!(errors,err)
        error(err)
        return true
    else
        model_data.input_size = size(input_data)[1:end-1]
        model_data.output_size = size_label
        return false
    end
end

# Main training function
function train_main(model_data::ModelData,all_data::AllData,options::Options,channels::Channels)
    # Initialization
    GC.gc()
    training_data = all_data.TrainingData
    testing_data = all_data.TestingData
    training_options = options.TrainingOptions
    args = training_options.Hyperparameters
    use_GPU = false
    if options.GlobalOptions.HardwareResources.allow_GPU
        if has_cuda()
            use_GPU = true
        else
            warning = "No CUDA capable device was detected. Using CPU instead."
            @warn warning
            push!(training_data.warnings,warning)
        end
    end
    reset_training_data(training_data)
    # Check save directory
    if isempty(all_data.model_url)
        all_data.model_url = "models/new_model.model"
        all_data.model_name = "new_model"
    end
    # Preparing train and test sets
    typed_training_data = get_data_struct(training_data)
    typed_testing_data = get_data_struct(testing_data)
    train_set, test_set = get_sets(typed_training_data,typed_testing_data)
    # Data testing
    if args.batch_size>length(train_set[1])
        err = string("Input data size (",length(train_set[1]),") is smaller than the batch size (",args.batch_size,").")
        push!(training_data.errors,err)
        error(err)
    end
    # Model testing
    excp = test_model(model_data,train_set,training_data.errors,use_GPU)
    if excp
        return nothing
    end
    # Setting functions and parameters
    opt = get_optimiser(training_options)
    local ws::Vector{Float32}
    if options.TrainingOptions.Accuracy.weight_accuracy
        if training_options.Accuracy.accuracy_mode==:Manual
            ws = training_data.weights
            l_ws = length(ws)
            l_data = size(train_set[2][1])[end]
            if l_ws!=l_data
                error = string("The number of weights is not equal to the number of channels. ",l_ws," vs ",l_data)
                @error error
                push!(training_data.errors,error)
                return nothing
            end
        else
            ws = get_weights(typed_training_data)
        end
    else
        ws = Vector{Float32}(undef,0)
    end
    accuracy = get_accuracy_func(ws,options)
    loss = model_data.loss
    num_tests = training_options.Testing.num_tests
    # Run training
    data = train!(model_data,train_set,test_set,opt,accuracy,loss,
        all_data,use_GPU,num_tests,args,channels,training_data.tasks)
    # Clean up
    clean_up_training(training_data.PlotData)
    # Return training results
    training_results_data = training_data.Results
    training_results_data.accuracy = data[1]
    training_results_data.loss = data[2]
    training_results_data.test_accuracy = data[3]
    training_results_data.test_loss = data[4]
    training_results_data.test_iteration = data[5]
    save_model(all_data.model_url)
    return nothing
end
function train_main2(model_data::ModelData,all_data::AllData,options::Options,channels::Channels)
    t = Threads.@spawn train_main(model_data,all_data,options,channels)
    push!(all_data.TrainingData.tasks,t)
    return t
end
