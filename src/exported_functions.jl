
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
        get_settings,
        set_settings,
        save_settings
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
    if settings.problem_type==:Classification
        @info "Classification has no output options to modify."
    elseif settings.problem_type==:Regression
        @info "Regression has no output options to modify."
    elseif settings.problem_type==:Segmentation
        @qmlfunction(
            save_model,
            get_class_field,
            get_settings,
            get_output,
            set_output,
            get_class_field,
            get_problem_type,
            num_classes
        )
        path_qml = string(@__DIR__,"/GUI/OutputDialog.qml")
        loadqml(ath_qml,indTree = 0)
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
        get_settings,
        set_settings,
        save_settings,
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
    filename = string(training.name,".model")
    url_out = String[""]
    observe(url) = url_out[1] = url
    # Launches GUI
    @qmlfunction(observe)
    @info @__DIR__
    path_qml = string(@__DIR__,"/GUI/UniversalSaveFileDialog.qml")
    loadqml(path_qml,
        name_filters = name_filters,
        filename = filename)
    exec()
    # Load model
    save_model(url_out[1])
end

# Training
function get_urls(some_settings::Union{Training,Testing},some_data::Union{TrainingData,TestingData},url_inputs::String,url_labels::String)
    some_settings.url_inputs = url_inputs
    some_settings.url_labels = url_labels
    if !isdir(url_inputs)
        @error string(url_inputs," does not exist.")
        return nothing
    end
    if settings.problem_type==:Classification || settings.problem_type==:Segmentation
        if !isdir(url_labels)
            @error string(url_labels," does not exist.")
            return nothing
        end
    elseif settings.problem_type==:Regression
        if !isfile(url_labels)
            @error string(url_labels," does not exist.")
            return nothing
        end
    end
    get_urls_main(some_settings,some_data,model_data)
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
    loadqml("/GUI/UniversalFileDialog.qml",
        name_filters = name_filters)
    exec()
    # Load model
    load_model(url_out[1])
end

"""
    modify(data) 

Allows to modify `training_options` or `application_options` in a GUI by passing one of 
them as an input argument.
"""
function modify(data)
    if typeof(data)==TrainingOptions
        @qmlfunction(
            get_settings,
            set_settings,
            save_settings
        )
        path_qml = string(@__DIR__,"/GUI/TrainingOptions.qml")
        loadqml(path_qml)
        exec()

    elseif typeof(data)==ApplicationOptions
        @qmlfunction(
            get_settings,
            set_settings,
            save_settings,
            pwd,
            fix_slashes
        )
        path_qml = string(@__DIR__,"/GUI/ApplicationOptions.qml")
        loadqml(path_qml)
        exec()
    end
    return nothing
end

"""
    get_urls_training(url_inputs::String,url_labels::String)

Gets URLs to all files present in both folders (or a folder and a file) 
specified by `url_inputs` and `url_labels` for training. URLs are automatically saved to `EasyML.training_data`.
"""
get_urls_training(url_inputs,url_labels) = get_urls(training,training_data,url_inputs,url_labels)
"""
    get_urls_testing(url_inputs::String,url_labels::String)

Gets URLs to all files present in both folders (or a folder and a file) 
specified by `url_inputs` and `url_labels` for testing. URLs are automatically saved to `EasyML.testing_data`.
"""
get_urls_testing(url_inputs,url_labels) = get_urls(testing,testing_data,url_inputs,url_labels)

function get_urls(some_settings::Union{Training,Testing},some_data::Union{TrainingData,TestingData},url_inputs::String)
    if settings.problem_type!=:Classification
        @error "Label data directory URL was not given."
        return nothing
    end
    some_settings.url_inputs = url_inputs
    if !isdir(url_inputs)
        @error string(url_inputs," does not exist.")
        return nothing
    end
    get_urls_main(some_settings,some_data,model_data)
    return nothing
end
"""
    get_urls_training(url_inputs::String)

Used for classification. Gets URLs to all files present in folders located at a folder specified by `url_inputs` 
for training. Folders should have names identical to the name of classes. URLs are automatically saved to `EasyML.training_data`.
"""
get_urls_training(url_inputs) = get_urls(training,training_data,url_inputs)
"""
    get_urls_testing(url_inputs::String)

Used for classification. Gets URLs to all files present in folders located at a folder specified by `url_inputs` 
for testing. Folders should have names identical to the name of classes. URLs are automatically saved to `EasyML.testing_data`.
"""
get_urls_testing(url_inputs) = get_urls(testing,testing_data,url_inputs)

function get_urls(some_settings::Union{Training,Testing},some_data::Union{TrainingData,TestingData})
    url_channel = Channel{String}(1)
    observe(url) = put!(url_channel,fix_QML_types(url))
    dir = pwd()

    @info "Select a directory with input data."
    @qmlfunction(observe)
    path_qml = string(@__DIR__,"/GUI/UniversalFolderDialog.qml")
    loadqml(path_qml,currentfolder = dir)
    exec()
    if isready(url_channel)
        some_settings.url_inputs =take!(url_channel)
        @info string(some_settings.url_inputs, " was selected.")
    else
        @error "Input data directory URL is empty."
        return nothing
    end
    problem_type = settings.problem_type
    if problem_type==:Classification
    
    elseif problem_type==:Regression
        name_filters = ["*.csv","*.xlsx"]
        @qmlfunction(observe)
        path_qml = string(@__DIR__,"/GUI/UniversalFileDialog.qml")
        loadqml(path_qml,
            name_filters = name_filters)
        exec()
        if isready(url_channel)
            some_settings.url_labels =take!(url_channel)
            @info string(some_settings.url_labels, " was selected.")
        else
            @error "Label data file URL is empty."
            return nothing
        end
    elseif problem_type==:Segmentation
        @info "Select a directory with label data."
        @qmlfunction(observe)
        path_qml = string(@__DIR__,"/GUI/UniversalFolderDialog.qml")
        loadqml(path_qml,currentfolder = dir)
        exec()
        if isready(url_channel)
            some_settings.url_labels =take!(url_channel)
            @info string(some_settings.url_labels, " was selected.")
        else
            @error "Label data directory URL is empty."
            return nothing
        end
    end
    get_urls_main(some_settings,some_data,model_data)
    return nothing
end
"""
    get_urls_training()

Opens a folder/file dialog or dialogs to choose folders or folder and a file containing inputs 
and labels. URLs are automatically saved to `EasyML.training_data`.
"""
get_urls_training() = get_urls(training,training_data)


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

function get_urls_testing_main(training::Training,training_data::TrainingData,testing::Testing,testing_data::TestingData)
    if training.Options.Testing.manual_testing_data
        get_urls(testing,testing_data)
    else
        problem_type = settings.problem_type
        if problem_type==:Classification
            typed_training_data = training_data.ClassificationData
            typed_testing_data = testing_data.ClassificationData
            training_inputs = typed_training_data.input_urls
            testing_inputs = typed_testing_data.input_urls
            training_labels = typed_training_data.label_urls
            testing_labels = typed_testing_data.label_urls
        elseif problem_type==:Regression
            typed_training_data = training_data.RegressionData
            typed_testing_data = testing_data.RegressionData
            training_inputs = typed_training_data.input_urls
            testing_inputs = typed_testing_data.input_urls
            training_labels = typed_training_data.initial_data_labels
            testing_labels = typed_testing_data.initial_data_labels
        elseif problem_type==:Segmentation
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
        fraction = training.Options.Testing.test_data_fraction
        if problem_type==:Classification
            nums = length.(training_inputs_copy) # Get the number of elements
            for i = 1:length(nums)
                num = nums[i]
                inds_train,inds_test = get_train_test_inds(num,fraction)
                push!(training_inputs,training_inputs_copy[i][inds_train])
                push!(testing_inputs,training_inputs_copy[i][inds_test])
            end
            append!(training_labels,training_labels_copy)
            append!(testing_labels,training_labels_copy)
        elseif problem_type==:Regression || problem_type==:Segmentation
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
get_urls_testing() = get_urls_testing_main(training,training_data,testing,testing_data)

function prepare_data(some_settings::Union{Training,Testing},some_data::Union{TrainingData,TestingData})
    if isempty(model_data.classes)
        @error "Empty classes."
        return nothing
    end
    processing = settings.Training.Options.Processing
    if processing.grayscale && model_data.input_size[3]==3
        processing.grayscale = false
        @warn "Using RGB images because color channel has size 3."
    elseif !processing.grayscale && model_data.input_size[3]==1
        processing.grayscale = false
        @warn "Using grayscale images because color channel has size 1."
    end

    if some_settings isa Training
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
    if settings.input_type==:Image
        if settings.problem_type==:Classification 
            empty!(some_data.SegmentationData.input_urls)
            empty!(some_data.SegmentationData.label_urls)
            empty!(some_data.RegressionData.input_urls)
            if isempty(some_data.ClassificationData.input_urls)
                @error error_message
                return nothing
            end
        elseif settings.problem_type==:Regression
            empty!(some_data.ClassificationData.input_urls)
            empty!(some_data.ClassificationData.label_urls)
            empty!(some_data.SegmentationData.input_urls)
            empty!(some_data.SegmentationData.label_urls)
            if isempty(some_data.RegressionData.input_urls)
                @error error_message
                return nothing
            end
        elseif settings.problem_type==:Segmentation
            empty!(some_data.ClassificationData.input_urls)
            empty!(some_data.ClassificationData.label_urls)
            empty!(some_data.RegressionData.input_urls)
            if isempty(some_data.SegmentationData.input_urls)
                @error error_message
                return nothing
            end
        end
    end

    prepare_data_main(some_settings,some_data,model_data,channels)
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
prepare_training_data() = prepare_data(training,training_data)
"""
    prepare_testing_data() 

Prepares images and corresponding labels for testing using URLs loaded previously using 
`get_urls_testing`. Saves data to `EasyML.testing_data`.
"""
prepare_testing_data() = prepare_data(testing,testing_data)

"""
    train()

Opens a GUI where training progress can be observed. Training parameters 
such as a number of epochs, learning rate and a number of tests per epoch 
can be changed during training.
"""
function train()
    if settings.problem_type==:Classification && settings.input_type==:Image
        if isempty(training_data.ClassificationData.data_input)
            @error "No training data. Run 'prepare_training_data()'."
            return nothing
        end
    elseif settings.problem_type==:Segmentation && settings.input_type==:Image
        if isempty(training_data.SegmentationData.data_input)
            @error "No training data. Run 'prepare_training_data()'."
            return nothing
        end
    end
    empty_progress_channel("Training")
    empty_results_channel("Training")
    empty_progress_channel("Training modifiers")
    train_main2(settings,training_data,testing_data,model_data,channels)
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
    path_qml = string(@__DIR__,"/GUI/TrainingPlot.qml")
    loadqml(path_qml)
    exec()

    while true
        data = get_results("Training")
        if data==true
            return training_results_data
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
    if settings.problem_type==:Classification || settings.problem_type==:Segmentation
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
    validation.url_inputs = url_inputs
    validation.url_labels = url_labels
    validation.use_labels = true
    get_urls_validation_main(validation,validation_data,model_data)
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
    validation.url_inputs = url_inputs
    validation.use_labels = false
    get_urls_validation_main(validation,validation_data,model_data)
    return nothing
end

"""
    get_urls_validation()

Opens a folder/file dialog or dialogs to choose folders or folder and a file containing inputs 
and labels. Folder/file dialog for labels can be skipped if there are no labels available. 
URLs are automatically saved to `EasyML.validation_data`.
"""
function get_urls_validation()
    url_channel = Channel{String}(1)
    observe(url) = put!(url_channel,fix_QML_types(url))
    dir = pwd()
    @info "Select a directory with input data."
    @qmlfunction(observe)
    path_qml = string(@__DIR__,"/GUI/UniversalFolderDialog.qml")
    loadqml(path_qml,currentfolder = dir)
    exec()
    if isready(url_channel)
        validation.url_inputs = take!(url_channel)
        @info string(validation.url_inputs, " was selected.")
    else
        @error "Input data directory URL is empty. Aborted"
        return nothing
    end
    if settings.problem_type==:Classification
    
    elseif settings.problem_type==:Regression
        name_filters = ["*.csv","*.xlsx"]
        @qmlfunction(observe)
        path_qml = string(@__DIR__,"/GUI/UniversalFileDialog.qml")
        loadqml(path_qml,
            name_filters = name_filters)
        exec()
        if isready(url_channel)
            validation.url_labels = take!(url_channel)
            @info string(training.url_labels, " was selected.")
        else
            @error "Label data directory URL is empty."
            return nothing
        end
    elseif settings.problem_type==:Segmentation
        @info "Select a directory with label data if labels are available."
        @qmlfunction(observe)
        path_qml = string(@__DIR__,"/GUI/UniversalFolderDialog.qml")
        loadqml(path_qml,currentfolder = dir)
        exec()
        if isready(url_channel)
            validation.url_labels = take!(url_channel)
            @info string(training.url_labels, " was selected.")
        else
            @error "Label data directory URL is empty."
            return nothing
        end
    end
    
    if validation.url_labels!="" && settings.problem_type!=:Classification
        validation.use_labels = true
    else
        validation.use_labels = false
    end

    get_urls_validation_main(validation,validation_data,model_data)
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
    validate_main2(settings,validation_data,model_data,channels)
    # Launches GUI
    @qmlfunction(
        # Handle classes
        num_classes,
        get_class_field,
        # Data handling
        get_settings,
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
    # Clean up
    validation_data.original_image = Array{RGB{N0f8},2}(undef,0,0)
    validation_data.result_image = Array{RGB{N0f8},2}(undef,0,0)
    if settings.input_type==:Image
        if settings.problem_type==:Classification
            return validation_image_classification_results
        elseif settings.problem_type==:Segmentation
            return validation_image_segmentation_results
        elseif settings.problem_type==:Regression
            return validation_image_regression_results
        end
    end
end

# Application
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
    application.url_inputs = url_inputs
    get_urls_application_main(application,application_data,model_data)
    application.checked_folders = application_data.folders
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
    application.url_inputs = url_out[1]
    if application.url_inputs==""
        @error "Input data directory URL is empty."
        return nothing
    else
        @info string(application.url_inputs, " was selected.")
    end

    get_urls_application_main(application,application_data,model_data)
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
    apply_main2(settings,training,application_data,model_data,channels)
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
                sleep(0.1)
            end
        end
    end
    return nothing
end