
"""
set_savepath(url::String)

Sets a path where a trained model will be saved.
"""
function set_savepath(url::String)
    url_split = split(url,('/','.'))
    if url_split[end]!="model"
        @error "The model name should end with a '.model' extension."
        return nothing
    end
    all_data.model_url = url
    all_data.model_name = url_split[end-1]
    return nothing
end

"""
set_problem_type(type::Symbol)

Sets the problem type. Either `:Classification`, `:Regression` or `:Segmentation`.
"""
function set_problem_type(type::Symbol)
    all_data.problem_type = type
    return nothing
end

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

function save_options_main(options::Options)
    dict = Dict{Symbol,Any}()
    struct_to_dict!(dict,options)
    BSON.@save("options.bson",dict)
    return nothing
end
"""
    save_options()

Saves options to `options.bson`. Uses present working directory. 
It is run automatically after changing options in a GUI window.
"""
save_options() = save_options_main(options)

function load_options!(options::Options)
    # Import the configutation file
    if isfile("options.bson")
        try
            data = BSON.load("options.bson")
            dict_to_struct!(options,data[:dict])
        catch e
            @error string("Options were not loaded. Error: ",e)
            save_options()
        end 
    else
        save_options()
    end
    
    return nothing
end
"""
    load_options()

Loads options from your previous run which are located in `options.bson`. 
Uses present working directory. It is run automatically after `using EasyML`.
"""
load_options() = load_options!(options)