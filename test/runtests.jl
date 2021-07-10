
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

EasyMLTraining.set_data(["TrainingData","errors"],[])

EasyMLTraining.set_options(["TrainingOptions","Hyperparameters","epochs"],1)

EasyMLTraining.set_options(["TrainingOptions","Hyperparameters","optimiser_params"],1,0.9)

function url_pusher()
    url  = popfirst!(EasyMLTraining.unit_test.urls)
    return url
end
EasyMLTraining.unit_test.url_pusher = url_pusher

EasyMLTraining.unit_test.urls = ["models/test.model"]
load_model()
EasyMLTraining.unit_test.urls = ["models/test.model"]
save_model()

#---Other

load_options()

load_model("models/test.model")

set_savepath("models/new_model.model")

modify(training_options)

try 
    set_problem_type(:Segmentatio)
catch
end

