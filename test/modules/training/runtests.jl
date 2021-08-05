
using EasyML.Training
import EasyML.Training

cd(@__DIR__)

training_options.Testing.test_data_fraction = 0.1
model_data.normalization.f = EasyML.none
model_data.normalization.args = ()

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


#---Other---------------------------------------------------------

Training.get_weights(model_data,Training.training_data.RegressionData)
load_model(joinpath(models_dir,"segmentation.model"))
Training.training_data.SegmentationData.Data.data_labels = [BitArray(undef,10,10,3)]
Training.get_weights(model_data,Training.training_data.SegmentationData)

#-----------------------------------------------------------------

rm("models/",recursive=true)