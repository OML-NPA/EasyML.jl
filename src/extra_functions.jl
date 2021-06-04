
# Design
function design_network()
    # Launches GUI
    @qmlfunction(
        # Handle classes
        model_count,
        model_get_layer_property,
        model_properties,
        # Model functions
        reset_layers,
        update_layers,
        make_model,
        save_model,
        load_model,
        # Model design
        arrange,
        # Data handling
        get_data,
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
    if isempty(classes)
        @error "Classes are empty. Add classes to the 'model_data'."
        return nothing
    end
    if !(classes isa Vector{Image_segmentation_class})
        @error string("There is nothing to change in a ",eltype(classes))
        return nothing
    end
    @qmlfunction(
        get_class_field,
        num_classes,
        append_classes,
        reset_classes,
        reset_output_options,
        backup_options,
        get_problem_type,
        get_settings,
        set_settings,
        save_settings
    )
    loadqml("GUI/ClassDialog.qml",JindTree = 0, ids = 1:length(classes))
    exec()
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
    if !isdir(label_dir)
        @error string(label_dir," does not exist.")
        return nothing
    end
    get_urls_training_main(training,training_data,model_data)
    return nothing
end

function get_urls_training(input_dir::String)
    if eltype(model_data.classes)!=Image_classification_class
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
    empty!(training_data.Image_classification_data.data_input)
    empty!(training_data.Image_classification_data.data_labels)
    empty!(training_data.Image_classification_data.input_urls)
    empty!(training_data.Image_classification_data.labels)
    empty!(training_data.Image_segmentation_data.data_input)
    empty!(training_data.Image_segmentation_data.data_labels)
    empty_progress_channel("Training data preparation")
    empty_results_channel("Training data preparation")

    if isempty(model_data.classes)
        @error "Empty classes."
        put!(progress, 0)
        return nothing
    end
    if model_data.classes isa Vector{Image_classification_class}
        if isempty(training_data.Image_classification_data.input_urls)
            @error "No input urls. Run 'get_urls_training'."
            return nothing
        end
    elseif model_data.classes isa Vector{Image_segmentation_class}
        if isempty(training_data.Image_segmentation_data.input_urls)
            @error "No input urls. Run 'get_urls_training'."
            return nothing
        end
    end

    prepare_training_data_main2(training,training_data,model_data,
        channels.training_data_progress,channels.training_data_results)
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
            end
        else
            temp_value = get_progress("Training data preparation")
            if temp_value!=false
                if temp_value!=0
                    max_value = temp_value
                    p.n = convert(Int64,max_value)
                else
                    break
                    @error "No data to process."
                end
            end
        end
        sleep(0.1)
    end
    return nothing
end

function modify(data)
    if typeof(data)==Training_options
        @qmlfunction(
            get_settings,
            set_settings,
            save_settings
        )
        loadqml("GUI/TrainingOptions.qml")
        exec()

    elseif typeof(data)==Application_options
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
    empty_progress_channel("Training")
    empty_results_channel("Training")
    empty_progress_channel("Training modifiers")
    if model_data.classes isa Vector{Image_classification_class}
        @warn "Weighted accuracy cannot be used for classification. Using regular accuracy."
        training.Options.General.weight_accuracy = false
    end
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
    if !isdir(label_dir)
        @error string(label_dir," does not exist.")
        return nothing
    end
    validation.input_dir = input_dir
    validation.label_dir = label_dir
    validation.use_labels = false
    get_urls_validation_main(validation,validation_data,model_data)
    return nothing
end

function get_urls_validation(input_dir::String)
    if !isdir(input_dir)
        @error string(input_dir," does not exist.")
        return nothing
    end
    validation.input_dir = input_dir
    validation.use_labels = true
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
    empty_progress_channel("Validation")
    empty_results_channel("Validation")
    empty_progress_channel("Validation modifiers")
    validate_main2(settings,validation_data,model_data,channels)
    if model_data.classes isa Vector{Image_segmentation_class}
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
            get_image,
            # Other
            yield
        )
        f = CxxWrap.@safe_cfunction(display_image, Cvoid,
                                        (Array{UInt32,1}, Int32, Int32))
        loadqml("GUI/ValidationPlot.qml",
            display_image = f)
        exec()
        return validation_segmentation_results
    end
end

# Application

function modify_output()
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
    return nothing
end

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
                    # No data
                end
            end
        end
        sleep(0.1)
    end
    return nothing
end