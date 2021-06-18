
# Design
function design_network()
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
    loadqml("GUI/Design.qml")
    exec()

    return nothing
end

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
    loadqml("GUI/ClassDialog.qml",JindTree = JindTree, ids = ids)
    exec()
    return nothing
end

function modify_output()
    if isempty(model_data.classes)
        @error "There are no classes. Add classes using 'modify_classes()'."
        return nothing
    end
    if settings.problem_type==:Classification
        @info "Classification has no output to modify."
    elseif settings.problem_type==:Regression
        @info "Regression has no output to modify."
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
        loadqml("GUI/OutputDialog.qml",indTree = 0)
        exec()
    end
    return nothing
end

# Training
function get_urls_training(input_dir::String,label_dir::String)
    training.input_dir = input_dir
    training.label_dir = label_dir
    if !isdir(input_dir)
        @error string(input_dir," does not exist.")
        return nothing
    end
    if settings.problem_type==:Classification || settings.problem_type==:Segmentation
        if !isdir(label_dir)
            @error string(label_dir," does not exist.")
            return nothing
        end
    else
        if !isfile(label_dir)
            @error string(label_dir," does not exist.")
            return nothing
        end
    end
    get_urls_training_main(training,training_data,model_data)
    return nothing
end

function get_urls_training(input_dir::String)
    if eltype(model_data.classes)!=ImageClassificationClass
        @error "Label data directory URL was not given."
        return nothing
    end
    training.input_dir = input_dir
    if !isdir(input_dir)
        @error string(input_dir," does not exist.")
        return nothing
    end
    get_urls_training_main(training,training_data,model_data)
    return nothing
end

function get_urls_training()
    dir = pwd()
    @info "Select a directory with input data."
    @qmlfunction(
        set_settings
    )
    loadqml("GUI/universalFolderDialog.qml",currentfolder = dir,
        target = "Training",type = "input_dir")
    exec()
    sleep(0.1)
    if training.input_dir==""
        @error "Input data directory URL is empty."
        return nothing
    else
        @info string(training.input_dir, " was selected.")
    end

    @info "Select a directory with label data."
    @qmlfunction(
        set_settings
    )
    loadqml("GUI/universalFolderDialog.qml",currentfolder = dir,
        target = "Training",type = "label_dir")
    exec()
    sleep(0.1)
    if training.label_dir==""
        @error "Label data directory URL is empty."
        return nothing
    else
        @info string(training.label_dir, " was selected.")
    end
    
    get_urls_training_main(training,training_data,model_data)
    return nothing
end

function prepare_training_data()
    fields = [:data_input,:data_labels]
    for i in fields
        empty!(getfield(classification_data,i))
    end
    for i in fields
        empty!(getfield(segmentation_data,i))
    end
    
    empty_progress_channel("Training data preparation")
    empty_results_channel("Training data preparation")

    if isempty(model_data.classes)
        @error "Empty classes."
        return nothing
    end
    if settings.input_type==:Image
        if settings.problem_type==:Classification 
            empty!(training_data.ClassificationData.data_input)
            empty!(training_data.ClassificationData.data_labels)
            empty!(training_data.SegmentationData.input_urls)
            empty!(training_data.SegmentationData.label_urls)
            empty!(training_data.RegressionData.input_urls)
            if isempty(training_data.ClassificationData.input_urls)
                @error "No input urls. Run 'get_urls_training'."
                return nothing
            end
        elseif settings.problem_type==:Regression
            empty!(training_data.RegressionData.data_input)
            empty!(training_data.RegressionData.data_labels)
            empty!(training_data.ClassificationData.input_urls)
            empty!(training_data.ClassificationData.labels)
            empty!(training_data.SegmentationData.input_urls)
            empty!(training_data.SegmentationData.label_urls)
            if isempty(training_data.RegressionData.input_urls)
                @error "No input urls. Run 'get_urls_training'."
                return nothing
            end
        elseif settings.problem_type==:Segmentation
            empty!(training_data.SegmentationData.data_input)
            empty!(training_data.SegmentationData.data_labels)
            empty!(training_data.ClassificationData.input_urls)
            empty!(training_data.ClassificationData.labels)
            empty!(training_data.RegressionData.input_urls)
            if isempty(training_data.SegmentationData.input_urls)
                @error "No input urls. Run 'get_urls_training'."
                return nothing
            end
        end
    end

    prepare_training_data_main(training,training_data,model_data,channels)
    max_value = 0
    value = 0
    p = Progress(0)
    while true
        if max_value!=0
            temp_value = get_progress("Training data preparation")
            if temp_value!=false
                value += temp_value
                # handle progress here
                next!(p)
            elseif value==max_value
                state = get_results("Training data preparation")
                if state==true
                    # reset progress here
                    break
                end
            else
                sleep(0.1)
            end
        else
            temp_value = get_progress("Training data preparation")
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

function remove_training_data()
    fields = [:data_input,:data_labels]
    for i in fields
        empty!(getfield(classification_data,i))
    end
    for i in fields
        empty!(getfield(segmentation_data,i))
    end
    for i in fields
        empty!(getfield(regression_data,i))
    end
    return nothing
end

function modify(data)
    if typeof(data)==TrainingOptions
        @qmlfunction(
            get_settings,
            set_settings,
            save_settings
        )
        loadqml("GUI/TrainingOptions.qml")
        exec()

    elseif typeof(data)==ApplicationOptions
        @qmlfunction(
            get_settings,
            set_settings,
            save_settings,
            pwd,
            fix_slashes
        )
        loadqml("GUI/ApplicationOptions.qml")
        exec()
    end
    return nothing
end

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
    if settings.problem_type==:Classification
        @warn "Weighted accuracy cannot be used for classification. Using regular accuracy."
        training.Options.General.weight_accuracy = false
    elseif settings.problem_type==:Regression
        @warn "Weighted accuracy cannot be used for regression. Using regular accuracy."
        training.Options.General.weight_accuracy = false
    end
    #train_main2(settings,training_data,model_data,channels)
    train_main2(settings,training_data,model_data,channels)
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
    loadqml("GUI/TrainingPlot.qml")
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

function get_urls_validation(input_dir::String,label_dir::String)
    if !isdir(input_dir)
        @error string(input_dir," does not exist.")
        return nothing
    end
    if settings.problem_type==:Classification || settings.problem_type==:Segmentation
        if !isdir(label_dir)
            @error string(label_dir," does not exist.")
            return nothing
        end
        validation.label_dir = label_dir
    else
        if !isfile(label_dir)
            @error string(label_dir," does not exist.")
            return nothing
        end
        regression_data.labels_url = label_dir
    end
    validation.input_dir = input_dir
    validation.use_labels = true
    get_urls_validation_main(validation,validation_data,model_data)
    return nothing
end

function get_urls_validation(input_dir::String)
    if !isdir(input_dir)
        @error string(input_dir," does not exist.")
        return nothing
    end
    validation.input_dir = input_dir
    validation.use_labels = false
    get_urls_validation_main(validation,validation_data,model_data)
    return nothing
end

function get_urls_validation()
    dir = pwd()
    @info "Select a directory with input data."
    @qmlfunction(
        set_settings
    )
    loadqml("GUI/universalFolderDialog.qml",currentfolder = dir,
        target = "Validation",type = "input_dir")
    exec()
    sleep(0.1)
    if validation.input_dir==""
        @error "Input data directory URL is empty. Aborted"
        return nothing
    else
        @info string(training.input_dir, " was selected.")
    end

    @info "Select a directory with label data if labels are available."
    @qmlfunction(
        set_settings
    )
    loadqml("GUI/universalFolderDialog.qml",currentfolder = dir,
        target = "Validation",type = "label_dir")
    exec()
    if validation.input_dir==""
        @info string(training.label_dir, " was selected.")
        validation.use_labels = true
    else
        validation.use_labels = false
    end

    get_urls_validation_main(validation,validation_data,model_data)
    return nothing
end

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
    if settings.problem_type==:Classification && training.Options.General.weight_accuracy
        @warn "Weighted accuracy cannot be used for classification. Using regular accuracy."
        training.Options.General.weight_accuracy = false
    end
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
    loadqml("GUI/ValidationPlot.qml",
        display_original_image = f1,
        display_result_image = f2
    )
    exec()
    if settings.input_type==:Image
        if settings.problem_type==:Classification
            return validation_image_classification_results
        elseif settings.problem_type==:Segmentation
            return validation_image_segmentation_results
        end
    end
    # Clean up
    validation_data.original_image = Array{RGB{N0f8},2}(undef,0,0)
    validation_data.result_image = Array{RGB{N0f8},2}(undef,0,0)
end

function remove_validation_data()
    if settings.input_type==:Image
        if settings.problem_type==:Classification
            data = validation_data.ImageClassificationResults
            fields = fieldnames(ValidationImageRegressionResults)[1:end-1]
        elseif settings.problem_type==:Regression
            data = validation_data.ImageRegressionResults
            fields = fieldnames(ValidationImageRegressionResults)[1:end-1]
        elseif settings.problem_type==:Segmentation
            data = validation_data.ImageSegmentationResults
            fields = fieldnames(ValidationImageSegmentationResults)[1:end-1]
        end
    end
    for field in fields
        empty!(getfield(data, field))
    end
end

# Application
function get_urls_application(input_dir::String)
    if !isdir(input_dir)
        @error string(input_dir," does not exist.")
        return nothing
    end
    application.input_dir = input_dir
    get_urls_application_main(application,application_data,model_data)
    application.checked_folders = application_data.folders
    return nothing
end

function get_urls_application()
    dir = pwd()
    @info "Select a directory with input data."
    @qmlfunction(
        set_settings
    )
    loadqml("GUI/universalFolderDialog.qml",currentfolder = dir,
        target = "Application",type = "input_dir")
    exec()
    sleep(0.1)
    if application.input_dir==""
        @error "Input data directory URL is empty."
        return nothing
    else
        @info string(application.input_dir, " was selected.")
    end

    get_urls_application_main(application,application_data,model_data)
    return nothing
end

function apply()
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