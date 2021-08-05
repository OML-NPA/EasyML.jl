
EasyML is easy enough to figure out by yourself! Just run the following lines. 

## Add the package
```julia
using EasyML
```

## Set up
```julia
change(global_options)
```

## Design
```julia
change_classes()
change_output_options()
design_model()
```

## Train
```julia
change(data_preparation_options)
change(training_options)
get_urls_training()
get_urls_testing()
prepare_training_data()
prepare_testing_data()
results = train()
remove_training_data()
remove_testing_data()
remove_training_results()
```

## Validate
```julia
change(validation_options)
get_urls_validation()
results = validate()
remove_validation_data()
remove_validation_results()
```

## Apply
```julia
change(application_options)
get_urls_application()
apply()
remove_application_data()
```

## On reopening
```julia
load_model()
load_options()
```