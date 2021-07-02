# EasyML.jl
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://oml-npa.github.io/EasyML.jl/stable/)

<p align="center">
  <img width=250px src=https://raw.githubusercontent.com/OML-NPA/EasyML.jl/main/docs/src/assets/logo.png></img>
</p>


This package allows to use machine learning in Julia through a graphical user interface.

NB! This is a beta version. Bugs and bracking changes should be expected. Created models should not be affected and are designed to be recoverable.

### Features
It is possible to:
  - Design a neural network
  - Train a neural network
  - Validate a neural network
  - Apply a neural network to new data
  
Classification, regression and segmentation on images are currently supported.

[Flux.jl](https://github.com/FluxML/Flux.jl) machine learning library is used under the hood.

<img src="https://github.com/OML-NPA/EasyML.jl/blob/dev/docs/src/assets/images/design_model.png" height="190"> <img src="https://github.com/OML-NPA/EasyML.jl/blob/dev/docs/src/assets/images/train.png" height="190"> <img src="https://github.com/OML-NPA/EasyML.jl/blob/dev/docs/src/assets/images/validate2.png" height="190">

### Installation

Run `] add EasyML` in REPL.

### Quick guide

EasyML is easy enough to figure out by yourself! Just run the following lines.

#### Adding the package
```julia
using EasyML
```

#### Setting up
```julia
modify(global_options)
```

#### Design
```julia
modify_classes()
modify_output()
design_model()
```

#### Train
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

#### Validate
```julia
get_urls_validation()
results = validate()
remove_validation_data()
remove_validation_results()
```

#### Apply
```julia
modify(application_options)
get_urls_application()
apply()
remove_application_data()
```

#### On reopening
```julia
load_model()
load_options()
```
