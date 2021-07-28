
"""
    modify(application_options::EasyML.ApplicationOptions) 

Allows to modify `application_options` in a GUI.
"""
function Common.modify(application_options::ApplicationOptions)
    @qmlfunction(
        get_options,
        set_options,
        save_options,
        pwd,
        fix_slashes,
        unit_test
    )
    path_qml = string(@__DIR__,"/GUI/ApplicationOptions.qml")
    gui_dir = string("file:///",replace(@__DIR__, "\\" => "/"),"/gui/")
    text = add_templates(path_qml)
    loadqml(QByteArray(text), 
        gui_dir = gui_dir)
    exec()
    return nothing
end

"""
    modify_output()
Opens a GUI for addition or modification of output options for classes.
"""
function modify_output()
    local output_type
    if isempty(model_data.classes)
        @error "There are no classes. Add classes using 'modify_classes()'."
        return nothing
    end
    if problem_type()==:classification
        @info "Classification has no output options to modify."
        return nothing
    elseif problem_type()==:regression
        @info "Regression has no output options to modify."
        return nothing
    elseif problem_type()==:segmentation
        output_type = ImageSegmentationOutputOptions
    end
    if typeof(model_data.output_options)!=output_type || 
        length(model_data.output_options)!=length(model_data.classes)
        model_data.output_options = output_type[]
        for _=1:length(model_data.classes)
            push!(model_data.output_options,output_type())
        end
    end
    @qmlfunction(
        save_model,
        get_class_field,
        get_data,
        get_options,
        get_output,
        set_output,
        get_problem_type,
        num_classes
    )
    path_qml = string(@__DIR__,"/GUI/OutputDialog.qml")
    gui_dir = string("file:///",replace(@__DIR__, "\\" => "/"),"/gui/")
    text = add_templates(path_qml)
    loadqml(QByteArray(text), 
        gui_dir = gui_dir)
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
    gui_dir = string("file:///",replace(@__DIR__, "\\" => "/"),"/gui/")
    text = add_templates(path_qml)
    loadqml(QByteArray(text), 
        gui_dir = gui_dir,
        currentfolder = dir,
        target = "Application",
        type = "url_inputs")
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
    empty_channel(:application_progress)
    t = apply_main2(model_data,all_data,options,channels)
    max_value = 0
    value = 0
    p = Progress(0)
    while true
        if max_value!=0
            temp_value = get_progress(:application_progress)
            if temp_value!=false
                value += temp_value
                # handle progress here
                next!(p)
            elseif value==max_value
                break
            else
                state,error = check_task(t)
                if state==:error
                    throw(error)
                    return nothing
                end
                sleep(0.1)
            end
        else
            temp_value = get_progress(:application_progress)
            if temp_value!=false
                if temp_value!=0
                    max_value = temp_value
                    p.n = max_value
                else
                    @error "No data to process."
                    break
                end
            else
                state,error = check_task(t)
                if state==:error
                    throw(error)
                    return nothing
                end
                sleep(0.1)
            end
        end
    end
    return nothing
end

function remove_application_data_main(application_data)
    data = application_data
    fields = fieldnames(ApplicationData)
    for field in fields
        data_field = getfield(data, field)
        if data_field isa Array
            empty!(data_field)
        end
    end
end

"""
    remove_application_data()

Removes all application data.
"""
remove_application_data() = remove_application_data_main(application_data)