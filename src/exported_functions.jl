
function load_model()
    name_filters = ["*.model"]
    url_out = String[""]
    observe(url) = url_out[1] = url
    # Launches GUI
    @qmlfunction(observe)
    loadqml("GUI/UniversalFileDialog.qml",
        nameFilters = name_filters)
    exec()
    # Load model
    load_model(url_out[1])
end

function save_model()
    filename = string(training.name,".model")
    url_out = String[""]
    observe(url) = url_out[1] = url
    # Launches GUI
    @qmlfunction(observe)
    loadqml("GUI/UniversalSaveFileDialog.qml",
        nameFilters = name_filters,
        filename = filename)
    exec()
    # Load model
    save_model(url_out[1])
end

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
function get_urls(some_settings::Union{Training,Testing},some_data::Union{TrainingData,TestingData},input_url::String,label_url::String)
    some_settings.input_url = input_url
    some_settings.label_url = label_url
    if !isdir(input_url)
        @error string(input_url," does not exist.")
        return nothing
    end
    if settings.problem_type==:Classification || settings.problem_type==:Segmentation
        if !isdir(label_url)
            @error string(label_url," does not exist.")
            return nothing
        end
    elseif settings.problem_type==:Regression
        if !isfile(label_url)
            @error string(label_url," does not exist.")
            return nothing
        end
    end
    get_urls_main(some_settings,some_data,model_data)
    return nothing
end
get_urls_training(input_url,label_url) = get_urls(training,training_data,input_url,label_url)
get_urls_testing(input_url,label_url) = get_urls(testing,testing_data,input_url,label_url)

function get_urls(some_settings::Union{Training,Testing},some_data::Union{TrainingData,TestingData},input_url::String)
    if settings.problem_type!=:Classification
        @error "Label data directory URL was not given."
        return nothing
    end
    some_settings.input_url = input_url
    if !isdir(input_url)
        @error string(input_url," does not exist.")
        return nothing
    end
    get_urls_main(some_settings,some_data,model_data)
    return nothing
end

get_urls_training(input_url) = get_urls(training,training_data,input_url)

function get_train_test_inds(num::Int64,fraction::Float64)
    inds = randperm(num)  # Get shuffled indices
    ind_last_test = convert(Int64,round(fraction*num))
    inds_train = inds[ind_last_test+1:end]
    inds_test = inds[1:ind_last_test]
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
            training_labels = typed_training_data.data_labels
            testing_labels = typed_testing_data.data_labels
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
get_urls_testing() = get_urls_testing_main(training,training_data,testing,testing_data)

function get_urls(some_settings::Union{Training,Testing},some_data::Union{TrainingData,TestingData})
    url_out = String[""]
    observe(url) = url_out[1] = url
    dir = pwd()

    @info "Select a directory with input data."
    @qmlfunction(observe)
    loadqml("GUI/UniversalFolderDialog.qml",currentfolder = dir)
    exec()
    some_settings.input_url = url_out[1]
    if some_settings.input_url==""
        @error "Input data directory URL is empty."
        return nothing
    else
        @info string(some_settings.input_url, " was selected.")
    end
    problem_type = settings.problem_type
    if problem_type==:Classification
    
    elseif problem_type==:Regression
        name_filters = ["*.csv","*.xlsx"]
        @qmlfunction(observe)
        loadqml("GUI/UniversalFileDialog.qml",
            nameFilters = name_filters)
        exec()
        some_settings.label_url = url_out[1]
        if some_settings.label_url==""
            @error "Label data file URL is empty."
            return nothing
        else
            @info string(some_settings.label_url, " was selected.")
        end
    elseif problem_type==:Segmentation
        @info "Select a directory with label data."
        @qmlfunction(observe)
        loadqml("GUI/UniversalFolderDialog.qml",currentfolder = dir)
        exec()
        some_settings.label_url = url_out[1]
        if some_settings.label_url==""
            @error "Label data directory URL is empty."
            return nothing
        else
            @info string(some_settings.label_url, " was selected.")
        end
    end
    get_urls_main(some_settings,some_data,model_data)
    return nothing
end
get_urls_training() = get_urls(training,training_data)

function prepare_data(some_settings::Union{Training,Testing},some_data::Union{TrainingData,TestingData},channel_name::String)
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

    if channel_name=="Training data preparation"
        error_message = "No input urls. Run 'get_urls_training'."
    else
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
            empty!(some_data.ClassificationData.labels)
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
prepare_training_data() = prepare_data(training,training_data,"Training data preparation")
prepare_testing_data() = prepare_data(testing,testing_data,"Testing data preparation")

function remove_data(some_data::Union{TrainingData,TestingData})
    fields = [:data_input,:data_labels]
    for i in fields
        empty!(getfield(some_data.ClassificationData,i))
        empty!(getfield(some_data.RegressionData,i))
        empty!(getfield(some_data.SegmentationData,i))
    end
    if settings.input_type==:Image
        empty!(some_data.ClassificationData.input_urls)
        empty!(some_data.ClassificationData.label_urls)
        empty!(some_data.RegressionData.input_urls)
        empty!(some_data.SegmentationData.input_urls)
        empty!(some_data.SegmentationData.label_urls)
    end
    return nothing
end
remove_training_data() = remove_data(training_data)
remove_testing_data() = remove_data(testing_data)

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

function get_urls_validation(input_url::String,label_url::String)
    if !isdir(input_url)
        @error string(input_url," does not exist.")
        return nothing
    end
    if settings.problem_type==:Classification || settings.problem_type==:Segmentation
        if !isdir(label_url)
            @error string(label_url," does not exist.")
            return nothing
        end
    else
        if !isfile(label_url)
            @error string(label_url," does not exist.")
            return nothing
        end
    end
    validation.input_url = input_url
    validation.label_url = label_url
    validation.use_labels = true
    get_urls_validation_main(validation,validation_data,model_data)
    return nothing
end

function get_urls_validation(input_url::String)
    if !isdir(input_url)
        @error string(input_url," does not exist.")
        return nothing
    end
    validation.input_url = input_url
    validation.use_labels = false
    get_urls_validation_main(validation,validation_data,model_data)
    return nothing
end

function get_urls_validation()
    url_out = String[""]
    observe(url) = url_out[1] = url
    dir = pwd()

    @info "Select a directory with input data."
    @qmlfunction(observe)
    loadqml("GUI/UniversalFolderDialog.qml",currentfolder = dir)
    exec()
    validation.input_url = url_out[1]
    if validation.input_url==""
        @error "Input data directory URL is empty. Aborted"
        return nothing
    else
        @info string(training.input_url, " was selected.")
    end
    if settings.problem_type==:Classification
    
    elseif settings.problem_type==:Regression
        name_filters = ["*.csv","*.xlsx"]
        @qmlfunction(observe)
        loadqml("GUI/UniversalFileDialog.qml",
            nameFilters = name_filters)
        exec()
        validation.label_url = url_out[1]
    elseif settings.problem_type==:Segmentation
        @info "Select a directory with label data if labels are available."
        @qmlfunction(observe)
        loadqml("GUI/UniversalFolderDialog.qml",currentfolder = dir)
        exec()
        validation.label_url = url_out[1]
    end
    
    if validation.input_url==""
        @info string(training.label_url, " was selected.")
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
function get_urls_application(input_url::String)
    if !isdir(input_url)
        @error string(input_url," does not exist.")
        return nothing
    end
    application.input_url = input_url
    get_urls_application_main(application,application_data,model_data)
    application.checked_folders = application_data.folders
    return nothing
end

function get_urls_application()
    url_out = String[""]
    observe(url) = url_out[1] = url
    dir = pwd()
    @info "Select a directory with input data."
    @qmlfunction(observe)
    loadqml("GUI/UniversalFolderDialog.qml",currentfolder = dir,
        target = "Application",type = "input_url")
    exec()
    application.input_url = url_out[1]
    if application.input_url==""
        @error "Input data directory URL is empty."
        return nothing
    else
        @info string(application.input_url, " was selected.")
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