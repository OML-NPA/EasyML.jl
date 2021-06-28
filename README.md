# EasyML.jl
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://oml-npa.github.io/EasyML.jl/stable/) [![Donate](https://img.shields.io/badge/Donate-PayPal-blue.svg)](https://www.paypal.com/donate/?hosted_button_id=EJ2J3BVKYPJPY)

This package allows to use machine learning in Julia through a graphical user interface.

NB! This is a beta version. Bugs and bracking changes should be expected.

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

Add the package from this repository to Julia using 

`] add https://github.com/OML-NPA/EasyML.jl`

and then write

`using EasyML`


