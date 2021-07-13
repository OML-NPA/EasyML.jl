
using EasyMLTraining, Test

EasyMLTraining.unit_test.state = true

training_options.Testing.test_data_fraction = 0.1

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


#---Other QML-----------------------------------------------------
@testset "Other QML" begin
    @test begin
        EasyMLTraining.set_data(["TrainingData","errors"],[])

        EasyMLTraining.set_options(["TrainingOptions","Hyperparameters","epochs"],1)

        EasyMLTraining.set_options(["TrainingOptions","Hyperparameters","optimiser_params"],1,0.9)

        EasyMLTraining.unit_test.urls = ["models/test.model"]
        load_model()
        EasyMLTraining.unit_test.urls = ["models/test.model"]
        save_model()
        true
    end
end

#---Other----------------------------------------------------------
@testset "Other" begin
    @test begin
        load_options()

        load_model("models/test.model")

        set_savepath("models/new_model.model")

        modify(training_options)
        true
    end
end

