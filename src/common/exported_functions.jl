
"""
set_problem_type(type::EasyMLDataPreparation.AbstractProblemType)

Sets the problem type. Either `Classification`, `Regression` or `Segmentation`.
"""
function set_problem_type(type::Type{<:AbstractProblemType})
    model_data.problem_type = type
    return nothing
end

"""
set_input_type(type::EasyMLDataPreparation.AbstractInputType)

Sets the problem type. Currently only `Image`.
"""
function set_input_type(type::Type{<:AbstractInputType})
    model_data.input_type = type
    return nothing
end


#---Model saving/loading--------------------------------------------

"""
save_model()

Opens a file dialog where you can select where to save a model and how it should be called.
"""
function save_model()
    name_filters = ["*.model"]
    if isempty(all_data.Urls.model_name)
        all_data.Urls.model_name = "new_model"
    end
    filename = string(all_data.Urls.model_name,".model")
    url_out = String[""]
    observe(url) = url_out[1] = url
    # Launches GUI
    @qmlfunction(observe,unit_test)
    path_qml = string(@__DIR__,"/gui/UniversalSaveFileDialog.qml")
    loadqml(path_qml,
        name_filters = name_filters,
        filename = filename)
    exec()
    if !isempty(url_out[1])
        save_model(url_out[1])
    end
    return nothing
end

"""
    save_model(url::String)

Saves a model to a specified URL. The URL can be absolute or relative. 
Use '.model' extension.
"""
save_model(url) = save_model_main(model_data,url)

"""
load_model()

Opens a file dialog where you can select a model to be loaded and loads it.
"""
function load_model()
    name_filters = ["*.model"]
    url_out = String[""]
    observe(url) = url_out[1] = url
    # Launches GUI
    @qmlfunction(observe,unit_test)
    path_qml = string(@__DIR__,"/gui/UniversalFileDialog.qml")
    loadqml(path_qml,name_filters = name_filters)
    exec()
    if unit_test()
        url_out[1] = unit_test.url_pusher()
    end
    # Load model
    if !isempty(url_out[1])
        load_model(url_out[1])
    end
    return nothing
end

"""
    load_model(url::String)

Loads a model from a specified URL. The URL can be absolute or relative.
"""
load_model(url) = load_model_main(model_data,url,all_data.Urls)


#---Options saving/loading--------------------------------------------------

"""
    save_options()

Saves options to `options.bson`. Uses present working directory. 
It is run automatically after changing options in a GUI window.
"""
save_options() = save_options_main(options)

"""
    load_options()

Loads options from your previous run which are located in `options.bson`. 
Uses present working directory. It is run automatically after `using EasyML`.
"""
load_options() = load_options_main(options)