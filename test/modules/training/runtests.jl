
using EasyML.Training
import EasyML.Training

cd(@__DIR__)

training_options.Testing.test_data_fraction = 0.1

set_savepath("models/test.model")

change(training_options)


#---CPU-----------------------------------------------------------

@info "CPU tests started"
global_options.HardwareResources.allow_GPU = false

include("classification.jl")
include("regression.jl")
include("segmentation.jl")


#---GPU------------------------------------------------------------

@info "GPU tests started"
global_options.HardwareResources.allow_GPU = true

include("classification.jl")
include("regression.jl")
include("segmentation.jl")


#-----------------------------------------------------------------

rm("models/",recursive=true)