
using EasyML, Test

EasyML.Common.unit_test.state = true

examples_dir = joinpath(@__DIR__,"examples")
models_dir = joinpath(@__DIR__,"models")


#---Testing modules------------------------------------------

@info "Common"
include("modules/common/runtests.jl")
@info "Classes"
include("modules/classes/runtests.jl")
@info "Data preparation"
include("modules/datapreparation/runtests.jl")
@info "Training"
include("modules/training/runtests.jl")
@info "Validation"
include("modules/validation/runtests.jl")
@info "Application"
include("modules/application/runtests.jl")


#---Testing module glue------------------------------------------

training_options.Testing.data_preparation_mode = :auto
training_options.Testing.test_data_fraction = 0.2
load_model("models/classification.model")
get_urls_training("examples/classification/test")
get_urls_testing()
prepare_training_data()
prepare_testing_data()
train()

load_model("models/regression.model")
get_urls_training("examples/regression/test","examples/regression/test.csv")
get_urls_testing()
prepare_training_data()
prepare_testing_data()
train()

training_options.Testing.test_data_fraction = 0.5
load_model("models/segmentation.model")
get_urls_training("examples/segmentation/images", "examples/segmentation/labels")
get_urls_testing()
prepare_training_data()
prepare_testing_data()
train()