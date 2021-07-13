
#---Model saving/loading--------------------------------------------

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