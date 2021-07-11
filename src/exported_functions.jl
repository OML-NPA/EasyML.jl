
"""
modify(validation_options::ValidationOptions) 

Allows to modify `validation_options` in a GUI.
"""
function modify(data::ValidationOptions)
@qmlfunction(
    get_data,
    get_options,
    set_options,
    save_options,
    unit_test
)
path_qml = string(@__DIR__,"/gui/ValidationOptions.qml")
loadqml(path_qml)
exec()
return nothing
end

function get_urls_validation_main2(url_inputs::String,url_labels::String,validation_data::ValidationData)
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
    url_out = String[""]
    observe(url) = url_out[1]
    dir = pwd()
    @info "Select a directory with input data."
    @qmlfunction(observe,unit_test)
    path_qml = string(@__DIR__,"/common/gui/UniversalFolderDialog.qml")
    loadqml(path_qml,currentfolder = dir)
    exec()
    if unit_test()
        url_out[1] = unit_test.url_pusher()
    end
    if !isempty(url_out[1])
        validation_urls.url_inputs = url_out[1]
        @info string(validation_urls.url_inputs, " was selected.")
    else
        @error "Input data directory URL is empty. Aborted"
        return nothing
    end
    if problem_type()==:Classification
    
    elseif problem_type()==:Regression
        @info "Select a file with label data if labels are available."
        name_filters = ["*.csv","*.xlsx"]
        @qmlfunction(observe,unit_test)
        path_qml = string(@__DIR__,"/common/gui/UniversalFileDialog.qml")
        loadqml(path_qml,
            name_filters = name_filters)
        exec()
        if unit_test()
            url_out[1] = unit_test.url_pusher()
        end
        if !isempty(url_out[1])
            validation_urls.url_labels = url_out[1]
            @info string(validation_urls.url_labels, " was selected.")
        else
            @warn "Label data URL is empty. Continuing without labels."
        end
    elseif problem_type()==:Segmentation
        @info "Select a directory with label data if labels are available."
        @qmlfunction(observe,unit_test)
        path_qml = string(@__DIR__,"/common/gui/UniversalFolderDialog.qml")
        loadqml(path_qml,currentfolder = dir)
        exec()
        if unit_test()
            url_out[1] = unit_test.url_pusher()
        end
        if !isempty(url_out[1])
            validation_urls.url_labels = url_out[1]
            @info string(validation_urls.url_labels, " was selected.")
        else
            @warn "Label data directory URL is empty. Continuing without labels."
        end
    end
    
    if validation_urls.url_labels!="" && problem_type()!=:Classification
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
    loadqml(path_qml,
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