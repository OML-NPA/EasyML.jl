
## Model data

A struct named `model_data` is exported and holds all information about your model.

```julia
mutable struct ModelData
    model::Chain                                       # Flux.jl model.
    loss::Function                                     # holds loss that is used during training and validation.
    input_size::NTuple{3,Int64}                        # model input size.
    output_size::Union{Tuple{Int64},NTuple{3,Int64}}   # model output size.
end
```

## Options

All options are located in `EasyMLTraining.options`.

```julia
mutable struct Options
    GlobalOptions::GlobalOptions
    TrainingOptions::TrainingOptions
end
```

```julia
mutable struct GlobalOptions
    Graphics::Graphics
    HardwareResources::HardwareResources
end
```
Can be accessed as `global_options`.

```julia
mutable struct HardwareResources
    allow_GPU::Bool      # allows to use a GPU if a compatible one is installed.
end
```
Can be accessed as `EasyMLTraining.hardware_resources`.

```julia
mutable struct Graphics
    scaling_factor::Float64   # scales GUI by a given factor.
end
```
Can be accessed as `EasyMLTraining.graphics`.

```julia
mutable struct TrainingOptions
    Accuracy::AccuracyOptions
    Testing::TestingOptions
    Hyperparameters::HyperparametersOptions
end
```
Can be accessed as `EasyMLTraining.training_options`.

```julia
mutable struct AccuracyOptions 
    weight_accuracy::Bool   # uses weight accuracy where applicable.
    accuracy_mode::Symbol   # either :Auto or :Manual. :Manual allows to specify weights manually for each class.
end
```
Can be accessed as `EasyMLTraining.accuracy_options`.

```julia
mutable struct TestingOptions
    test_data_fraction::Float64     # a fraction of data from training data to be used for testing if data preparation mode is set to :Auto.
    num_tests::Float64              # a number of tests to be done each epoch at equal intervals.
    data_preparation_mode::Symbol   # Either :Auto or :Manual. Auto takes a specified fraction of training data to be used for testing. Manual allows to use other data as testing data.
end
```
Can be accessed as `EasyMLTraining.testing_options`.

```julia
mutable struct HyperparametersOptions
    optimiser::Symbol                   # an optimiser that should be used during training. ADAM usually works well for all cases.
    optimiser_params::Vector{Float64}   # parameters specific for each optimiser. Default ones can be found in EasyMLTraining.training_options_data
    learning_rate::Float64              # pecifies how fast a model should train. Lower values - more stable, but slower. Higher values - less stable, but faster. Should be decreased as training progresses.
    epochs::Int64                       # a number of rounds for which a model should be trained.
    batch_size::Int64                   # a number of data that should be batched together during training.
end
```
Can be accessed as `EasyMLTraining.hyperparameters_options`.



