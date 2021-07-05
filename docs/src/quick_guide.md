
EasyMLTraining is easy enough to figure out by yourself! Just run the following lines. 

## Add the package
```julia
using EasyMLTraining
```

## Set up
```julia
global_options.Graphics.scaling_factor = 1
global_options.HardwareResources.allow_GPU = true
modify(training_options)
set_savepath("models/my_model.model")
set_problem_type(:Classification) # or :Regression, or :Segmentation
```

# Set model and data
```julia
model_data.model = Flux.Chain()

data_input = []
data_labels = []
set_training_data(data_input,data_labels)

data_input_test = []
data_labels_test = []
set_testing_data(data_input_test,data_labels_test)
```

## Train
```julia
results = train()
remove_training_data()
remove_testing_data()
remove_training_results()
```

## On reopening
```julia
load_model("models/my_model.model")
load_options()
```