
using EasyMLTraining

EasyMLTraining.unit_test.state = true

training_options.Testing.test_data_fraction = 0.1

#---CPU

global_options.HardwareResources.allow_GPU = false

include("classification.jl")
include("regression.jl")
include("segmentation.jl")

#---GPU

global_options.HardwareResources.allow_GPU = true

include("classification.jl")
include("regression.jl")
include("segmentation.jl")


#---Other QML

set_data(["TrainingData","errors"],[])

set_options(["TrainingOptions","Hyperparameters","epochs"],value)

set_options(["TrainingOptions","Hyperparameters","optimiser_params"],1,0.9)

#---Other

load_options()

load_model("models/classification.model")

set_savepath("models/new_model.model")

modify(training_options)
