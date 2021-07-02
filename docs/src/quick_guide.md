
EasyML is easy enough to figure out by yourself! Just run the following lines. 

## Adding the package
```julia
using EasyML
```

## Settings up
```julia
modify(global_options)
```

## Design
```julia
modify_classes()
modify_output()
design_model()
```

## Train
```julia
modify(training_options)
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
get_urls_validation()
results = validate()
remove_validation_data()
remove_validation_results()
```

## Apply
```julia
modify(application_options)
get_urls_application()
apply()
remove_application_data()
```

## On reopening
```julia
load_model()
load_options()
```