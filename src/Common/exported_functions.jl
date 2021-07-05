
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
    @qmlfunction(observe)
    path_qml = string(@__DIR__,"/GUI/UniversalFileDialog.qml")
    loadqml(path_qml,name_filters = name_filters)
    exec()
    # Load model
    load_model(url_out[1])
end

"""
    load_model(url::String)

Loads a model from a specified URL. The URL can be absolute or relative.
"""
load_model(url) = load_model_main(model_data,url)