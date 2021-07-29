
using EasyML.Application

cd(@__DIR__)

global_options.HardwareResources.num_slices = 20


#---Main functionality-----------------------------------------------

modify(application_options)
modify_output()

training_options.Testing.data_preparation_mode = :auto
training_options.Testing.test_data_fraction = 0.2
load_model(joinpath(models_dir(),"classification.model"))
url_input = joinpath(examples_dir(),"classification/test")
get_urls_application(url_input)
apply()

load_model(joinpath(models_dir(),"regression.model"))
url_input = joinpath(examples_dir(),"regression/test")
get_urls_application(url_input)
apply()

training_options.Testing.test_data_fraction = 0.5
load_model(joinpath(models_dir(),"segmentation.model"))
url_input = joinpath(examples_dir(),"segmentation/images")
get_urls_application(url_input)
apply()


#---Other QML-------------------------------------------------------

get_urls_application()
