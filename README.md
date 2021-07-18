<p align="center">
  <img width=200px src=https://raw.githubusercontent.com/OML-NPA/EasyML.jl/main/docs/src/assets/logo.png></img>
</p>

<h1 align="center">EasyML.jl</h1>

[![docs stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://oml-npa.github.io/EasyML.jl/stable/)
[![docs dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://oml-npa.github.io/EasyML.jl/dev/)
[![CI main](https://github.com/OML-NPA/EasyML.jl/actions/workflows/CI-main.yml/badge.svg)](https://github.com/OML-NPA/EasyM.jl/actions/workflows/CI-main.yml)
[![CI dev](https://github.com/OML-NPA/EasyML.jl/actions/workflows/CI-dev.yml/badge.svg)](https://github.com/OML-NPA/EasyM.jl/actions/workflows/CI-dev.yml)


This package allows to use machine learning in Julia through a graphical user interface.

NB! This is a beta version. Bugs and breaking changes should be expected.

## Features
It is possible to:
  - Design a neural network
  - Train a neural network
  - Validate a neural network
  - Apply a neural network to new data
  
Classification, regression and segmentation on images are currently supported.

[Flux.jl](https://github.com/FluxML/Flux.jl) machine learning library is used under the hood.

<img src="https://github.com/OML-NPA/EasyML.jl/blob/dev/docs/src/assets/images/design_model.png" height="190"> <img src="https://github.com/OML-NPA/EasyML.jl/blob/dev/docs/src/assets/images/train.png" height="190"> <img src="https://github.com/OML-NPA/EasyML.jl/blob/dev/docs/src/assets/images/validate2.png" height="190">

## Installation

Run `] add EasyML` in REPL.

## Quick guide

EasyML is easy enough to figure out by yourself! Just run the following lines.

### Add the package
```julia
using EasyML
```

### Set up
```julia
modify(global_options)
```

### Design
```julia
modify_classes()
modify_output()
design_model()
```

### Train
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

### Validate
```julia
get_urls_validation()
results = validate()
remove_validation_data()
remove_validation_results()
```

### Apply
```julia
modify(application_options)
get_urls_application()
apply()
remove_application_data()
```

### On reopening
```julia
load_model()
load_options()
```

## Development

A plan for the project can be seen [here](https://github.com/OML-NPA/EasyML.jl/projects/2).

### Current focus

Separating EasyML into
 - [EasyMLCore](https://github.com/OML-NPA/EasyMLCore.jl)
 - [EasyMLClasses](https://github.com/OML-NPA/EasyMLClasses.jl)
 - [EasyMLDesign](https://github.com/OML-NPA/EasyMLDesign.jl)
 - [EasyMLDataPreparation](https://github.com/OML-NPA/EasyMLDataPreparation.jl)
 - [EasyMLTraining](https://github.com/OML-NPA/EasyMLTraining.jl)
 - [EasyMLValidation](https://github.com/OML-NPA/EasyMLValidation.jl)
 - [EasyMLApplication](https://github.com/OML-NPA/EasyMLApplication.jl)

EasyML will bring those packages together.

