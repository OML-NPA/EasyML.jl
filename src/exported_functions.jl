
"""
    modify(global_options::EasyML.GlobalOptions) 

Allows to modify `global_options` in a GUI.
"""
function modify(data::GlobalOptions)
    @qmlfunction(
        max_num_threads,
        get_options,
        set_options,
        save_options
    )
    path_qml = string(@__DIR__,"/GUI/GlobalOptions.qml")
    loadqml(path_qml)
    exec()
    return nothing
end

"""
    modify_classes()

Opens a GUI for addition or modification of classes.
"""
function modify_classes()
    classes = model_data.classes
    if length(classes)==0
        ids = [0]
        JindTree = -1
    else
        ids = 1:length(classes)
        JindTree = 0
    end
    @qmlfunction(
        get_class_field,
        num_classes,
        append_classes,
        reset_classes,
        reset_output_options,
        backup_options,
        get_problem_type,
        set_problem_type,
        get_options,
        set_options,
        save_options
    )
    path_qml = string(@__DIR__,"/GUI/ClassDialog.qml")
    loadqml(path_qml,JindTree = JindTree, ids = ids)
    exec()
    return nothing
end

"""
    modify_output()

Opens a GUI for addition or modification of output options for classes.
"""
function modify_output()
    if isempty(model_data.classes)
        @error "There are no classes. Add classes using 'modify_classes()'."
        return nothing
    end
    if problem_type()==:Classification
        @info "Classification has no output options to modify."
    elseif problem_type()==:Regression
        @info "Regression has no output options to modify."
    elseif problem_type()==:Segmentation
        @qmlfunction(
            save_model,
            get_class_field,
            get_data,
            get_options,
            get_output,
            set_output,
            get_class_field,
            get_problem_type,
            num_classes
        )
        path_qml = string(@__DIR__,"/GUI/OutputDialog.qml")
        loadqml(path_qml,indTree = 0)
        exec()
    end
    return nothing
end

# Design
"""
    design_model()

Opens a GUI for creation of a model.
"""
function design_model()
    # Launches GUI
    @qmlfunction(
        # Handle classes
        model_count,
        model_get_layer_property,
        model_properties,
        # Model functions
        get_max_id,
        reset_layers,
        update_layers,
        make_model,
        check_model,
        move_model,
        save_model,
        load_model,
        # Model design
        arrange,
        # Data handling
        get_data,
        set_data,
        get_options,
        set_options,
        save_options,
        # Other
        source_dir
    )
    path_qml = string(@__DIR__,"/GUI/Design.qml")
    loadqml(path_qml)
    exec()

    return nothing
end

"""
    save_model()

Opens a file dialog where you can select where to save a model and how it should be called.
"""
function save_model()
    name_filters = ["*.model"]
    filename = string(all_data.model_name,".model")
    url_out = String[""]
    observe(url) = url_out[1] = url
    # Launches GUI
    @qmlfunction(observe)
    path_qml = string(@__DIR__,"/GUI/UniversalSaveFileDialog.qml")
    loadqml(path_qml,
        name_filters = name_filters,
        filename = filename)
    exec()
    if !isempty(url_out)
        save_model(url_out[1])
    end
    return nothing
end

# Training
function get_urls(url_inputs::String,url_labels::String,some_data::Union{TrainingData,TestingData})
    some_data.url_inputs = url_inputs
    some_data.url_labels = url_labels
    if !isdir(url_inputs)
        @error string(url_inputs," does not exist.")
        return nothing
    end
    if problem_type()==:Classification || problem_type()==:Segmentation
        if !isdir(url_labels)
            @error string(url_labels," does not exist.")
            return nothing
        end
    elseif problem_type()==:Regression
        if !isfile(url_labels)
            @error string(url_labels," does not exist.")
            return nothing
        end
    end
    get_urls_main(model_data,some_data)
    return nothing
end

"""
    load_model()

Opens a file dialog where you can select a model to be loaded and loads it.
"""
function load_model()
    name_filters = ["*.model"]
    url_out = String[""]
    observe(url) = url_out[1] = url
    # Launches GUI
    @qmlfunction(observe)
    path_qml = string(@__DIR__,"/GUI/UniversalFileDialog.qml")
    loadqml(path_qml, name_filters = name_filters)
    exec()
    # Load model
    load_model(url_out[1])
    return nothing
end

"""
    modify(training_options::TrainingOptions) 

Allows to modify `training_options` in a GUI.
"""
function modify(data::EasyML.TrainingOptions)
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
    get_urls_training(url_inputs::String,url_labels::String)

Gets URLs to all files present in both folders (or a folder and a file) 
specified by `url_inputs` and `url_labels` for training. URLs are automatically saved to `EasyML.training_data`.
"""
get_urls_training(url_inputs,url_labels) = get_urls(url_inputs,url_labels,training_data)
"""
    get_urls_testing(url_inputs::String,url_labels::String)

Gets URLs to all files present in both folders (or a folder and a file) 
specified by `url_inputs` and `url_labels` for testing. URLs are automatically saved to `EasyML.testing_data`.
"""
get_urls_testing(url_inputs,url_labels) = get_urls(url_inputs,url_labels,testing_data)

function get_urls(url_inputs::String,some_data::Union{TrainingData,TestingData})
    if problem_type()!=:Classification
        @error "Label data directory URL was not given."
        return nothing
    end
    some_data.url_inputs = url_inputs
    if !isdir(url_inputs)
        @error string(url_inputs," does not exist.")
        return nothing
    end
    get_urls_main(model_data,some_data)
    return nothing
end
"""
    get_urls_training(url_inputs::String)

Used for classification. Gets URLs to all files present in folders located at a folder specified by `url_inputs` 
for training. Folders should have names identical to the name of classes. URLs are automatically saved to `EasyML.training_data`.
"""
get_urls_training(url_inputs) = get_urls(url_inputs,training_data)
"""
    get_urls_testing(url_inputs::String)

Used for classification. Gets URLs to all files present in folders located at a folder specified by `url_inputs` 
for testing. Folders should have names identical to the name of classes. URLs are automatically saved to `EasyML.testing_data`.
"""
get_urls_testing(url_inputs) = get_urls(url_inputs,testing_data)

function get_urls(some_data::Union{TrainingData,TestingData})
    url_channel = Channel{String}(1)
    observe(url) = put!(url_channel,fix_QML_types(url))
    dir = pwd()

    @info "Select a directory with input data."
    @qmlfunction(observe)
    path_qml = string(@__DIR__,"/GUI/UniversalFolderDialog.qml")
    loadqml(path_qml,currentfolder = dir)
    exec()
    if isready(url_channel)
        some_data.url_inputs =take!(url_channel)
        @info string(some_data.url_inputs, " was selected.")
    else
        @error "Input data directory URL is empty."
        return nothing
    end
    if problem_type()==:Classification
    
    elseif problem_type()==:Regression
        @info "Select a file with label data."
        name_filters = ["*.csv","*.xlsx"]
        @qmlfunction(observe)
        path_qml = string(@__DIR__,"/GUI/UniversalFileDialog.qml")
        loadqml(path_qml,
            name_filters = name_filters)
        exec()
        if isready(url_channel)
            some_data.url_labels =take!(url_channel)
            @info string(some_data.url_labels, " was selected.")
        else
            @error "Label data file URL is empty."
            return nothing
        end
    elseif problem_type()==:Segmentation
        @info "Select a directory with label data."
        @qmlfunction(observe)
        path_qml = string(@__DIR__,"/GUI/UniversalFolderDialog.qml")
        loadqml(path_qml,currentfolder = dir)
        exec()
        if isready(url_channel)
            some_data.url_labels =take!(url_channel)
            @info string(some_data.url_labels, " was selected.")
        else
            @error "Label data directory URL is empty."
            return nothing
        end
    end
    get_urls_main(model_data,some_data)
    return nothing
end
"""
    get_urls_training()

Opens a folder/file dialog or dialogs to choose folders or folder and a file containing inputs 
and labels. URLs are automatically saved to `EasyML.training_data`.
"""
get_urls_training() = get_urls(training_data)


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

function get_urls_testing_main(training_data::TrainingData,testing_data::TestingData,training_options::TrainingOptions)
    if training_options.Testing.data_preparation_mode==:Manual
        get_urls(testing_data)
    else
        if problem_type()==:Classification
            typed_training_data = training_data.ClassificationData
            typed_testing_data = testing_data.ClassificationData
            training_inputs = typed_training_data.input_urls
            testing_inputs = typed_testing_data.input_urls
            training_labels = typed_training_data.label_urls
            testing_labels = typed_testing_data.label_urls
        elseif problem_type()==:Regression
            typed_training_data = training_data.RegressionData
            typed_testing_data = testing_data.RegressionData
            training_inputs = typed_training_data.input_urls
            testing_inputs = typed_testing_data.input_urls
            training_labels = typed_training_data.initial_data_labels
            testing_labels = typed_testing_data.initial_data_labels
        elseif problem_type()==:Segmentation
            typed_training_data = training_data.SegmentationData
            typed_testing_data = testing_data.SegmentationData
            training_inputs = typed_training_data.input_urls
            testing_inputs = typed_testing_data.input_urls
            training_labels = typed_training_data.label_urls
            testing_labels = typed_testing_data.label_urls
        end
        if isempty(training_inputs) || isempty(training_labels)
            @warn "Training data should be loaded first. Run 'get_urls_training'"
            return nothing
        end
        training_inputs_copy = copy(training_inputs)
        training_labels_copy = copy(training_labels)
        empty!(training_inputs)
        empty!(testing_inputs)
        empty!(training_labels)
        empty!(testing_labels)
        fraction = training_options.Testing.test_data_fraction
        if problem_type()==:Classification
            nums = length.(training_inputs_copy) # Get the number of elements
            for i = 1:length(nums)
                num = nums[i]
                inds_train,inds_test = get_train_test_inds(num,fraction)
                push!(training_inputs,training_inputs_copy[i][inds_train])
                push!(testing_inputs,training_inputs_copy[i][inds_test])
            end
            append!(training_labels,training_labels_copy)
            append!(testing_labels,training_labels_copy)
        elseif problem_type()==:Regression || problem_type()==:Segmentation
            num = length(training_inputs_copy) # Get the number of elements
            inds_train,inds_test = get_train_test_inds(num,fraction)
            append!(training_inputs,training_inputs_copy[inds_train])
            append!(testing_inputs,training_inputs_copy[inds_test])
            append!(training_labels,training_labels_copy[inds_train])
            append!(testing_labels,training_labels_copy[inds_test])
        end
    end
    return nothing
end
"""
    get_urls_testing()

If testing data preparation in `modify(training_options)` is set to auto, then a percentage 
of training data also specified there is reserved for testing. If testing data 
preparation is set to manual, then it opens a folder/file dialog or dialogs to choose folders or folder and a file containing inputs 
and labels. URLs are automatically saved to `EasyML.testing_data`.
"""
get_urls_testing() = get_urls_testing_main(training_data,testing_data,training_options)

function prepare_data(some_data::Union{TrainingData,TestingData})
    if isempty(model_data.classes)
        @error "Empty classes."
        return nothing
    end
    processing = options.TrainingOptions.Processing
    if processing.grayscale && model_data.input_size[3]==3
        processing.grayscale = false
        @warn "Using RGB images because color channel has size 3."
    elseif !processing.grayscale && model_data.input_size[3]==1
        processing.grayscale = false
        @warn "Using grayscale images because color channel has size 1."
    end

    if some_data isa TrainingData
        println("Training data preparation:")
        channel_name = "Training data preparation"
        error_message = "No input urls. Run 'get_urls_training'."
    else
        println("Testing data preparation:")
        channel_name = "Testing data preparation"
        error_message = "No input urls. Run 'get_urls_testing'."
    end
    fields = [:data_input,:data_labels]
    for i in fields
        empty!(getfield(some_data.ClassificationData,i))
        empty!(getfield(some_data.SegmentationData,i))
    end
    empty!(some_data.RegressionData.data_input)
    empty_progress_channel(channel_name)
    empty_results_channel(channel_name)
    if all_data.input_type==:Image
        if problem_type()==:Classification 
            empty!(some_data.SegmentationData.input_urls)
            empty!(some_data.SegmentationData.label_urls)
            empty!(some_data.RegressionData.input_urls)
            if isempty(some_data.ClassificationData.input_urls)
                @error error_message
                return nothing
            end
        elseif problem_type()==:Regression
            empty!(some_data.ClassificationData.input_urls)
            empty!(some_data.ClassificationData.label_urls)
            empty!(some_data.SegmentationData.input_urls)
            empty!(some_data.SegmentationData.label_urls)
            if isempty(some_data.RegressionData.input_urls)
                @error error_message
                return nothing
            end
        elseif problem_type()==:Segmentation
            empty!(some_data.ClassificationData.input_urls)
            empty!(some_data.ClassificationData.label_urls)
            empty!(some_data.RegressionData.input_urls)
            if isempty(some_data.SegmentationData.input_urls)
                @error error_message
                return nothing
            end
        end
    end

    t = prepare_data_main(model_data,some_data,channels)
    max_value = 0
    value = 0
    p = Progress(0)
    while true
        if max_value!=0
            temp_value = get_progress(channel_name)
            if temp_value!=false
                value += temp_value
                # handle progress here
                next!(p)
            elseif value==max_value
                state = get_results(channel_name)
                if state==true
                    # reset progress here
                    break
                end
            else
                state,error = check_task(t)
                if state==:error
                    @warn string("Data preparation aborted due to the following error: ",error)
                    return nothing
                end
                sleep(0.1)
            end
        else
            temp_value = get_progress(channel_name)
            if temp_value!=false
                if temp_value!=0
                    max_value = temp_value
                    p.n = max_value
                else
                    break
                    @error "No data to process."
                end
            else
                state,error = check_task(t)
                if state==:error
                    @warn string("Validation aborted due to the following error: ",error)
                    return nothing
                end
                sleep(0.1)
            end
        end
    end
    return nothing
end
"""
    prepare_training_data() 

Prepares images and corresponding labels for training using URLs loaded previously using 
`get_urls_training`. Saves data to EasyML.training_data.
"""
prepare_training_data() = prepare_data(training_data)
"""
    prepare_testing_data() 

Prepares images and corresponding labels for testing using URLs loaded previously using 
`get_urls_testing`. Saves data to `EasyML.testing_data`.
"""
prepare_testing_data() = prepare_data(testing_data)

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
        @error "No training data. Run 'prepare_training_data()'."
        return nothing
    end
    training_data.OptionsData.run_test = !isempty(data_test) && testing_options.test_data_fraction>0
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

# Validation
"""
    get_urls_validation(url_inputs::String,url_labels::String)

Gets URLs to all files present in both folders (or a folder and a file) 
specified by `url_inputs` and `url_labels` for validation. URLs are automatically 
saved to `EasyML.validation_data`.
"""
function get_urls_validation(url_inputs::String,url_labels::String)
    if !isdir(url_inputs)
        @error string(url_inputs," does not exist.")
        return nothing
    end
    if problem_type()==:Classification || problem_type()==:Segmentation
        if !isdir(url_labels)
            @error string(url_labels," does not exist.")
            return nothing
        end
    else
        if !isfile(url_labels)
            @error string(url_labels," does not exist.")
            return nothing
        end
    end
    validation_data.url_inputs = url_inputs
    validation_data.url_labels = url_labels
    validation_data.use_labels = true
    get_urls_validation_main(model_data,validation_data)
    return nothing
end

"""
    get_urls_validation(url_inputs::String)

Gets URLs to all files present in a folders specified by `url_inputs` 
for validation. URLs are automatically saved to `EasyML.validation_data`.
"""
function get_urls_validation(url_inputs::String)
    if !isdir(url_inputs)
        @error string(url_inputs," does not exist.")
        return nothing
    end
    validation_data.url_inputs = url_inputs
    validation_data.use_labels = false
    get_urls_validation_main(model_data,validation_data)
    return nothing
end

"""
    get_urls_validation()

Opens a folder/file dialog or dialogs to choose folders or folder and a file containing inputs 
and labels. Folder/file dialog for labels can be skipped if there are no labels available. 
URLs are automatically saved to `EasyML.validation_data`.
"""
function get_urls_validation()
    validation_data.url_inputs = ""
    validation_data.url_labels = ""
    url_channel = Channel{String}(1)
    observe(url) = put!(url_channel,fix_QML_types(url))
    dir = pwd()
    @info "Select a directory with input data."
    @qmlfunction(observe)
    path_qml = string(@__DIR__,"/GUI/UniversalFolderDialog.qml")
    loadqml(path_qml,currentfolder = dir)
    exec()
    if isready(url_channel)
        validation_data.url_inputs = take!(url_channel)
        @info string(validation_data.url_inputs, " was selected.")
    else
        @error "Input data directory URL is empty. Aborted"
        return nothing
    end
    if problem_type()==:Classification
    
    elseif problem_type()==:Regression
        @info "Select a file with label data if labels are available."
        name_filters = ["*.csv","*.xlsx"]
        @qmlfunction(observe)
        path_qml = string(@__DIR__,"/GUI/UniversalFileDialog.qml")
        loadqml(path_qml,
            name_filters = name_filters)
        exec()
        if isready(url_channel)
            validation_data.url_labels = take!(url_channel)
            @info string(validation_data.url_labels, " was selected.")
        else
            @warn "Label data URL is empty. Continuing without labels."
        end
    elseif problem_type()==:Segmentation
        @info "Select a directory with label data if labels are available."
        @qmlfunction(observe)
        path_qml = string(@__DIR__,"/GUI/UniversalFolderDialog.qml")
        loadqml(path_qml,currentfolder = dir)
        exec()
        if isready(url_channel)
            validation_data.url_labels = take!(url_channel)
            @info string(validation_data.url_labels, " was selected.")
        else
            @warn "Label data directory URL is empty. Continuing without labels."
        end
    end
    
    if validation_data.url_labels!="" && problem_type()!=:Classification
        validation_data.use_labels = true
    else
        validation_data.use_labels = false
    end

    get_urls_validation_main(model_data,validation_data)
    return nothing
end


"""
    validate()

Opens a GUI where validation progress and results can be observed.
"""
function validate()
    if model_data.model isa Chain{Tuple{}}
        @error "Model is empty."
        return nothing
    elseif isempty(model_data.classes)
        @error "Classes are empty."
        return nothing
    end
    if isempty(validation_data.input_urls)
        @error "No input urls. Run 'get_urls_validation'."
        return nothing
    end
    empty_progress_channel("Validation")
    empty_results_channel("Validation")
    empty_progress_channel("Validation modifiers")
    t = validate_main2(model_data,validation_data,options,channels)
    # Launches GUI
    @qmlfunction(
        # Handle classes
        num_classes,
        get_class_field,
        # Data handling
        get_options,
        get_results,
        get_progress,
        put_channel,
        get_image_size,
        get_image,
        get_data,
        # Other
        yield
    )
    f1 = CxxWrap.@safe_cfunction(display_original_image, Cvoid,(Array{UInt32,1}, Int32, Int32))
    f2 = CxxWrap.@safe_cfunction(display_result_image, Cvoid,(Array{UInt32,1}, Int32, Int32))
    path_qml = string(@__DIR__,"/GUI/ValidationPlot.qml")
    loadqml(path_qml,
        display_original_image = f1,
        display_result_image = f2
    )
    exec()
    state,error = check_task(t)
    if state==:error
        @warn string("Validation aborted due to the following error: ",error)
    end
    # Clean up
    validation_data.original_image = Array{RGB{N0f8},2}(undef,0,0)
    validation_data.result_image = Array{RGB{N0f8},2}(undef,0,0)
    if input_type()==:Image
        if problem_type()==:Classification
            return validation_image_classification_results
        elseif problem_type()==:Segmentation
            return validation_image_segmentation_results
        elseif problem_type()==:Regression
            return validation_image_regression_results
        end
    end
end

# Application

"""
    modify(application_options::EasyML.ApplicationOptions) 

Allows to modify `application_options` in a GUI.
"""
function modify(application_options::ApplicationOptions)
    @qmlfunction(
        get_options,
        set_options,
        save_options,
        pwd,
        fix_slashes
    )
    path_qml = string(@__DIR__,"/GUI/ApplicationOptions.qml")
    loadqml(path_qml)
    exec()
    return nothing
end

"""
    get_urls_application(url_inputs::String)

Gets URLs to all files present in a folders specified by `url_inputs` 
for application. URLs are automatically saved to `EasyML.application_data`.
"""
function get_urls_application(url_inputs::String)
    if !isdir(url_inputs)
        @error string(url_inputs," does not exist.")
        return nothing
    end
    application_data.url_inputs = url_inputs
    get_urls_application_main(application_data)
    return nothing
end

"""
    get_urls_application()

Opens a folder dialog to choose a folder containing files to which a model should be applied. 
URLs are automatically saved to `EasyML.application_data`.
"""
function get_urls_application()
    url_out = String[""]
    observe(url) = url_out[1] = url
    dir = pwd()
    @info "Select a directory with input data."
    @qmlfunction(observe)
    path_qml = string(@__DIR__,"/GUI/UniversalFolderDialog.qml")
    loadqml(path_qml,currentfolder = dir,
        target = "Application",type = "url_inputs")
    exec()
    application_data.url_inputs = url_out[1]
    if application_data.url_inputs==""
        @error "Input data directory URL is empty."
        return nothing
    else
        @info string(application_data.url_inputs, " was selected.")
    end

    get_urls_application_main(application_data)
    return nothing
end

"""
    apply()

Starts application of a model.
"""
function apply()
    println("Application:")
    if isempty(application_data.input_urls)
        @error "No input urls. Run 'get_urls_application'."
        return nothing
    end
    empty_progress_channel("Application")
    empty_progress_channel("Application modifiers")
    t = apply_main2(model_data,all_data,options,channels)
    max_value = 0
    value = 0
    p = Progress(0)
    while true
        if max_value!=0
            temp_value = get_progress("Application")
            if temp_value!=false
                value += temp_value
                # handle progress here
                next!(p)
            elseif value==max_value
                # reset progress here
                break
            else
                state,error = check_task(t)
                if state==:error
                    @warn string("Validation aborted due to the following error: ",error)
                    return nothing
                end
                sleep(0.1)
            end
        else
            temp_value = get_progress("Application")
            if temp_value!=false
                if temp_value!=0
                    max_value = temp_value
                    p.n = convert(Int64,max_value)
                else
                    break
                    @error "No data to process."
                end
            else
                state,error = check_task(t)
                if state==:error
                    @warn string("Application aborted due to the following error: ",error)
                    return nothing
                end
                sleep(0.1)
            end
        end
    end
    return nothing
end