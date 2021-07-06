
"""
    modify(training_options::TrainingOptions) 

Allows to modify `training_options` in a GUI.
"""
function modify(data::TrainingOptions)
    @qmlfunction(
        get_data,
        get_options,
        set_options,
        save_options
    )
    path_qml = string(@__DIR__,"/GUI/TrainingOptions.qml")
    loadqml(path_qml)
    exec()
    return nothing
end

"""
    set_training_data(data_input::Vector,data_labels::Vector)

Sets data for training.
"""
function set_training_data(data_input::Vector,data_labels::Vector)
    l_input = length(data_input)
    l_labels = length(data_labels)
    if l_labels!=l_labels
        err = string("Input data length does not equal label data length. ",l_input," vs ",l_labels,".")
        error(err)
    end
    if problem_type()==:Classification
        training_data.ClassificationData.data_input = data_input
        training_data.ClassificationData.data_labels = data_labels
        training_data.ClassificationData.max_labels = maximum(data_labels)
    elseif problem_type()==:Regression
        training_data.RegressionData.data_input = data_input
        training_data.RegressionData.data_labels = data_labels
    else # Segmentation
        training_data.SegmentationData.data_input = data_input
        training_data.SegmentationData.data_labels = data_labels
    end
    return nothing
end
"""
    set_testing_data(data_input::Vector,data_labels::Vector)

Sets data for testing.
"""
function set_testing_data(data_input::Vector,data_labels::Vector)
    l_input = length(data_input)
    l_labels = length(data_labels)
    if l_labels!=l_labels
        err = string("Input data length does not equal label data length. ",l_input," vs ",l_labels,".")
        error(err)
    end
    if problem_type()==:Classification
        testing_data.ClassificationData.data_input = data_input
        testing_data.ClassificationData.data_labels = data_labels
    elseif problem_type()==:Regression
        testing_data.RegressionData.data_input = data_input
        testing_data.RegressionData.data_labels = data_labels
    else # Segmentation
        testing_data.SegmentationData.data_input = data_input
        testing_data.SegmentationData.data_labels = data_labels
    end
    return nothing
end

function get_train_test_inds(num::Int64,fraction::Float64)
    inds = randperm(num)  # Get shuffled indices
    ind_last_test = convert(Int64,round(fraction*num))
    inds_train = inds[ind_last_test+1:end]
    inds_test = inds[1:ind_last_test]
    if isempty(inds_test)
        @warn string("Fraction of ",fraction," from ",num,
        " files is 0. Increase the fraction of data used for testing to at least ",round(1/num,digits=2),".")
    end
    return inds_train,inds_test
end

function set_testing_data_main(training_data::TrainingData,testing_data::TestingData,training_options::TrainingOptions)
    if training_options.Testing.data_preparation_mode==:Auto
        msg = "Data preparation mode was not set to 'Manual'. Setting it to 'Manual'."
        @warn msg
    end
    if problem_type()==:Classification
        specific_training_data = training_data.ClassificationData
        specific_testing_data = testing_data.ClassificationData
    elseif problem_type()==:Regression
        specific_training_data = training_data.RegressionData
        specific_testing_data = testing_data.RegressionData
    else # Segmentation
        specific_training_data = training_data.SegmentationData
        specific_testing_data = testing_data.SegmentationData
    end
    num = length(specific_training_data.data_input)
    fraction = training_options.Testing.test_data_fraction
    inds_train,inds_test = get_train_test_inds(num,fraction)
    specific_testing_data.data_input = specific_training_data.data_input[inds_test]
    specific_testing_data.data_labels = specific_training_data.data_labels[inds_test]
    specific_training_data.data_input = specific_training_data.data_input[inds_train]
    specific_training_data.data_labels = specific_training_data.data_labels[inds_train]
    return nothing
end
"""
    set_testing_data()

A fraction of training data also specified in training options is set aside for testing.
"""
set_testing_data() = set_testing_data_main(training_data,testing_data,training_options)

function set_weights_main(ws_in::Vector{<:Real},training_data::TrainingData)
    if isempty(ws_in)
        training_data.weights = Vector{Float32}(undef,0)
        return nothing
    end
    ws = convert(Vector{Float32},ws_in)
    s = sum(ws)
    if s==1
        training_data.weights =  ws
    else
        training_data.weights =  ws/s
    end
    return nothing
end
"""
    set_weights(ws::Vector{<:Real})

Set weights for weight accuracy to `ws`. If `sum(ws) ≠ 1` then it is adjusted to be so. 
If weights are not specified then inverse frequency of labesl is used.
"""
set_weights(ws) = set_weights_main(ws,training_data)

"""
    train()

Opens a GUI where training progress can be observed. Training parameters 
such as a number of epochs, learning rate and a number of tests per epoch 
can be changed during training.
"""
function train()
    if problem_type()==:Classification
        data_train = training_data.ClassificationData.data_input
        data_test = testing_data.ClassificationData.data_input
    elseif problem_type()==:Regression
        data_train = training_data.RegressionData.data_input
        data_test = testing_data.RegressionData.data_input
    else # :Segmentation
        data_train = training_data.SegmentationData.data_input
        data_test = testing_data.SegmentationData.data_input
    end
    if isempty(data_train)
        @error "No training data."
        return nothing
    end
    training_data.OptionsData.run_test = !isempty(data_test)
    empty_progress_channel("training_start_progress")
    empty_progress_channel("training_progress")
    empty_progress_channel("training_modifiers")
    t = train_main2(model_data,all_data,options,channels)
    # Launches GUI
    @qmlfunction(
        # Data handling
        set_data,
        get_data,
        get_options,
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
    path_qml = string(@__DIR__,"/GUI/TrainingPlot.qml")
    loadqml(path_qml)
    exec()
    
    state,err = check_task(t)
    if state==:error
        @warn string("Training aborted due to the following error: ",err)
    end
    return training_data.Results
end

function remove_data(some_data::T) where T<:Union{TrainingData,TestingData}
    fields = [:data_input,:data_labels]
    for field in fields
        empty!(getfield(some_data.ClassificationData,field))
        empty!(getfield(some_data.RegressionData,field))
        empty!(getfield(some_data.SegmentationData,field))
    end
    fields = fieldnames(T)[4:end]
    for field in fields
        data = getfield(some_data,field)
        if data isa Array
            empty!(data)
        end
    end
    return nothing
end
"""
    remove_training_data()

Removes all training data except for result.
"""
remove_training_data() = remove_data(training_data)
"""
    remove_testing_data()

Removes all testing data.
"""
remove_testing_data() = remove_data(testing_data)

"""
    remove_training_results()

Removes training results.
"""
function remove_training_results()
    data = training_data.Results
    fields = fieldnames(TrainingResultsData)
    for field in fields
        empty!(getfield(data, field))
    end
end