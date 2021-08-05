
"""
change(validation_options::ValidationOptions) 

Allows to change `validation_options` in a GUI.
"""
function Common.change(data::ValidationOptions)
    @qmlfunction(
        get_data,
        get_options,
        set_options,
        save_options,
        unit_test
    )
    path_qml = string(@__DIR__,"/gui/ValidationOptions.qml")
    gui_dir = string("file:///",replace(@__DIR__, "\\" => "/"),"/gui/")
    text = add_templates(path_qml)
    loadqml(QByteArray(text), gui_dir = gui_dir)
    exec()
    return nothing
end

function get_urls_validation_main2(url_inputs::String,url_labels::String,validation_data::ValidationData)
    if !isdir(url_inputs)
        @error string(url_inputs," does not exist.")
        return nothing
    end
    if problem_type()==:classification || problem_type()==:segmentation
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
    validation_urls = validation_data.Urls
    validation_urls.url_inputs = url_inputs
    validation_urls.url_labels = url_labels
    validation_data.PlotData.use_labels = true
    get_urls_validation_main(model_data,validation_urls,validation_data)
    return nothing
end
"""
    get_urls_validation(url_inputs::String,url_labels::String)

Gets URLs to all files present in both folders (or a folder and a file) 
specified by `url_inputs` and `url_labels` for validation. URLs are automatically 
saved to `EasyMLValidation.validation_data`.
"""
get_urls_validation(url_inputs,url_labels) = get_urls_validation_main2(url_inputs,url_labels,validation_data)


function get_urls_validation_main2(url_inputs::String,validation_data)
    if !isdir(url_inputs)
        @error string(url_inputs," does not exist.")
        return nothing
    end
    validation_urls = validation_data.Urls
    validation_urls.url_inputs = url_inputs
    validation_data.PlotData.use_labels = false
    get_urls_validation_main(model_data,validation_urls,validation_data)
    return nothing
end
"""
    get_urls_validation(url_inputs::String)

Gets URLs to all files present in a folders specified by `url_inputs` 
for validation. URLs are automatically saved to `EasyMLValidation.validation_data`.
"""
get_urls_validation(url_inputs) = get_urls_validation_main2(url_inputs,validation_data)

function get_urls_validation_main2(validation_data::ValidationData)
    validation_urls = validation_data.Urls
    validation_urls.url_inputs = ""
    validation_urls.url_labels = ""
    dir = pwd()
    @info "Select a directory with input data."
    path = get_folder(dir)
    if !isempty(path)
        validation_urls.url_inputs = path
        @info string(validation_urls.url_inputs, " was selected.")
    else
        @error "Input data directory URL is empty. Aborted"
        return nothing
    end
    if problem_type()==:classification
    
    elseif problem_type()==:regression
        @info "Select a file with label data if labels are available."
        name_filters = ["*.csv","*.xlsx"]
        path = get_file(dir,name_filters)
        if !isempty(path)
            validation_urls.url_labels = path
            @info string(validation_urls.url_labels, " was selected.")
        else
            @warn "Label data URL is empty. Continuing without labels."
        end
    elseif problem_type()==:segmentation
        @info "Select a directory with label data if labels are available."
        path = get_folder(dir)
        if !isempty(path)
            validation_urls.url_labels = path
            @info string(validation_urls.url_labels, " was selected.")
        else
            @warn "Label data directory URL is empty. Continuing without labels."
        end
    end
    
    if validation_urls.url_labels!="" && problem_type()!=:classification
        validation_data.PlotData.use_labels = true
    else
        validation_data.PlotData.use_labels = false
    end

    get_urls_validation_main(model_data,validation_urls,validation_data)
    return nothing
end
"""
    get_urls_validation()

Opens a folder/file dialog or dialogs to choose folders or folder and a file containing inputs 
and labels. Folder/file dialog for labels can be skipped if there are no labels available. 
URLs are automatically saved to `EasyMLValidation.validation_data`.
"""
get_urls_validation() = get_urls_validation_main2(validation_data)


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
    if isempty(validation_data.Urls.input_urls)
        @error "No input urls. Run 'get_urls_validation'."
        return nothing
    end
    empty_channel(:validation_start)
    empty_channel(:validation_progress)
    empty_channel(:validation_modifiers)
    t = validate_main2(model_data,validation_data,options,channels)
    # Launches GUI
    @qmlfunction(
        # Handle classes
        num_classes,
        get_class_field,
        # Data handling
        get_problem_type,
        get_input_type,
        get_options,
        get_progress,
        put_channel,
        get_image_size,
        get_image_validation,
        get_data,
        # Other
        yield,
        unit_test
    )
    f1 = CxxWrap.@safe_cfunction(display_original_image_validation, Cvoid,(Array{UInt32,1}, Int32, Int32))
    f2 = CxxWrap.@safe_cfunction(display_label_image_validation, Cvoid,(Array{UInt32,1}, Int32, Int32))
    path_qml = string(@__DIR__,"/gui/ValidationPlot.qml")
    gui_dir = string("file:///",replace(@__DIR__, "\\" => "/"),"/gui/")
    text = add_templates(path_qml)
    loadqml(QByteArray(text), 
        gui_dir = gui_dir,
        display_original_image_validation = f1,
        display_label_image_validation = f2
    )
    exec()
    state,error = check_task(t)
    if state==:error
        @warn string("Validation aborted due to the following error: ",error)
    end
    # Clean up
    validation_data.PlotData.original_image = Array{RGB{N0f8},2}(undef,0,0)
    validation_data.PlotData.label_image = Array{RGB{N0f8},2}(undef,0,0)
    # Return results
    if input_type()==:image
        if problem_type()==:classification
            return validation_image_classification_results
        elseif problem_type()==:regression
            return validation_image_regression_results
        else # problem_type()==:segmentation
            return validation_image_segmentation_results
        end
    end
end

"""
    remove_validation_data()

Removes all validation data except for result.
"""
function remove_validation_data()
    fields = fieldnames(ValidationUrls)
    for field in fields
        val = getproperty(validation_data.Urls, field)
        if val isa Array
            empty!(val)
        elseif val isa String
            setproperty!(validation_data.Urls, field, "")
        end
    end
end

"""
    remove_validation_results()

Removes validation results.
"""
function remove_validation_results()
    data = validation_data.ImageClassificationResults
    fields = fieldnames(ValidationImageClassificationResults)
    for field in fields
        empty!(getfield(data, field))
    end
    data = validation_data.ImageRegressionResults
    fields = fieldnames(ValidationImageRegressionResults)
    for field in fields
        empty!(getfield(data, field))
    end
    data = validation_data.ImageSegmentationResults
    fields = fieldnames(ValidationImageSegmentationResults)
    for field in fields
        empty!(getfield(data, field))
    end
end