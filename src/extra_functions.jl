
# Design
function design_network()
    # Launches GUI
    @qmlfunction(
        # Handle features
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

function modify_feature(ind::Int64)
    if isempty(model_data.features)
        @warn "Features are empty. Add features to the 'model_data'."
        return nothing
    end
    if typeof(model_data.features)==Vector{Segmentation_feature}
        if ind<1
            @warn "Input must be a positive integer."
            return nothing
        end
        l = length(model_data.features)
        if ind>l
            @warn "There are only ",l," features."
            return nothing
        end

        @qmlfunction(
            get_feature_field,
            num_features,
            update_features,
            get_settings,
            set_settings,
            save_settings
        )
        loadqml("GUI/FeatureDialog.qml",indTree = ind-1)
        exec()
    end
    return nothing
end

# Training
function get_urls_training(input_dir::String,label_dir::String)
    training.input_dir = input_dir
    training.label_dir = label_dir
    if !isdir(input_dir)
        @warn string(input_dir," does not exist.")
        return nothing
    end
    if !isdir(label_dir)
        @warn string(label_dir," does not exist.")
        return nothing
    end
    get_urls_training_main(training,training_data,model_data)
    return nothing
end

function get_urls_training(input_dir::String)
    training.input_dir = input_dir
    if !isdir(input_dir)
        @warn string(input_dir," does not exist.")
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
        @warn "Input data directory URL is empty. Aborted"
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
        @warn "Label data directory URL is empty. Aborted"
        return nothing
    else
        @info string(training.label_dir, " was selected.")
    end
    
    get_urls_training_main(training,training_data,model_data)
    return nothing
end

function prepare_training_data()
    empty_progress_channel("Training data preparation")
    empty_results_channel("Training data preparation")
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
                    @warn "No data to process"
                    # No training data
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

    elseif typeof(data)==Segmentation_feature
        @qmlfunction(
            get_feature_field,
            num_features,
            update_features,
            get_settings,
            set_settings,
            save_settings
        )

        indTree = -1
        for i = 1:length(model_data.features)
            if model_data.features[i]==data
                indTree = i-1
            end
        end
        if indTree==-1
            @info "Feature does not exist in 'model_data'. Add the feature to the 'model_data'."
            return nothing
        end

        loadqml("GUI/FeatureDialog.qml",indTree = indTree)
        exec()
    end
    return nothing
end

function train()
    empty_progress_channel("Training")
    empty_results_channel("Training")
    empty_progress_channel("Training modifiers")
    if model_data.features isa Vector{Classification_feature}
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
        @info string(input_dir," does not exist.")
        return nothing
    end
    if !isdir(label_dir)
        @info string(label_dir," does not exist.")
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
        @warn string(input_dir," does not exist.")
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
        @warn "Input data directory URL is empty. Aborted"
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

    # Launches GUI
    @qmlfunction(
        # Handle features
        num_features,
        get_feature_field,
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
    return validation_results
end

# Application

function modify_output(feature::Segmentation_feature)
    @qmlfunction(
        save_model,
        get_settings,
        get_output,
        set_output,
        get_feature_field
    )

    indTree = -1
    for i = 1:length(model_data.features)
        if model_data.features[i]==feature
            indTree = i-1
        end
    end
    if indTree==-1
        @info "Feature does not exist in 'model_data'. Add the feature to the 'model_data'."
        return nothing
    end

    loadqml("GUI/OutputDialog.qml",indTree = indTree)
    exec()
    return nothing
end

function get_urls_application(input_dir::String)
    if !isdir(input_dir)
        @warn string(input_dir," does not exist.")
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
        @warn "Input data directory URL is empty. Aborted"
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
    apply_main2(settings,application_data,model_data,channels)
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
                    @warn "No data to process."
                    # No data
                end
            end
        end
        sleep(0.1)
    end
    return nothing
end