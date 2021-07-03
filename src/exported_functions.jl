
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

function set_training_data(data_input,data_labels)
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

function set_testing_data(data_input,data_labels)
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

function set_weights_main(ws_in::T,training_data::TrainingData) where T<:Vector
    if isempty(ws_in)
        training_data.weights = Vector{Float32}(undef,0)
        return nothing
    end
    if T<:Vector{<:Real}
        ws = convert(Vector{Float32},ws_in)
        s = sum(ws)
        if s==1
            training_data.weights =  ws
        else
            training_data.weights =  ws/s
        end
    else
        @error "Input must be an empty vector or a vector of numbers."
    end
    return nothing
end
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
    empty_progress_channel("Training")
    empty_progress_channel("Training modifiers")
    t = train_main2(model_data,all_data,options,channels)
    # Launches GUI
    @qmlfunction(
        # Data handling
        set_data,
        get_data,
        get_options,
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
    path_qml = string(@__DIR__,"/GUI/TrainingPlot.qml")
    loadqml(path_qml)
    exec()

    state,error = check_task(t)
    if state==:error
        @warn string("Training aborted due to the following error: ",error)
    end
    return training_data.Results
end