
#---Problem/input types---------------------------------------------

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
set_savepath(url::String)

Sets a path where a model will be saved.
"""

function set_savepath(url::String)
    url_split = split(url,('\\','/','.'))
    if isempty(url_split) || url_split[end]!="model"|| length(url_split)<2
        @error "The model name should end with a '.model' extension."
        return nothing
    end
    all_data.Urls.model_url = url
    all_data.Urls.model_name = url_split[end-1]
    return nothing
end

"""
save_model()

Opens a file dialog where you can select where to save a model and how it should be called.
"""
save_model() = save_model_main(model_data,all_data.Urls)

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
load_model() = load_model_main(model_data,all_data.Urls)

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