
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
    elseif problem_type()==:Regression
        training_data.RegressionData.data_input = data_input
        training_data.RegressionData.data_labels = data_labels
    else # Segmentation
        training_data.SegmentationData.data_input = data_input
        training_data.SegmentationData.data_labels = data_labels
    end
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
end

function set_weights(ws::Vector{Float32})
    s = sum(ws)
    if s==1
        training_data.weights = ws
    else
        training_data.weights = ws/s
    end
end

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
    empty_results_channel("Training")
    empty_progress_channel("Training modifiers")
    t = train_main2(model_data,all_data,options,channels)
    # Launches GUI
    @qmlfunction(
        # Data handling
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

    while true
        data = get_results("Training")
        if data==true
            return training_results_data
        end
        state,error = check_task(t)
        if state==:error
            @warn string("Training aborted due to the following error: ",error)
            return nothing
        end
        sleep(1)
    end
    return nothing
end