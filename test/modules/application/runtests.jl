
using EasyML.Application

cd(@__DIR__)

global_options.HardwareResources.num_slices = 1

#---Main functionality-----------------------------------------------

@info "Options"
change(application_options)
change_output_options()

@info "Classification"
load_model(joinpath(models_dir,"classification.model"))
url_input = joinpath(examples_dir,"classification/test")
get_urls_application(url_input)
apply()

@info "Regression"
load_model(joinpath(models_dir,"regression.model"))
url_input = joinpath(examples_dir,"regression/test")
get_urls_application(url_input)
apply()

@info "Segmentation"
load_model(joinpath(models_dir,"segmentation.model"))
url_input = joinpath(examples_dir,"segmentation/images")
get_urls_application(url_input)
apply()

rm("Output data",recursive=true)
rm("options.bson")


#---Other QML-------------------------------------------------------

get_urls_application()
