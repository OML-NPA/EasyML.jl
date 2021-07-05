# EasyMLTraining.jl
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://oml-npa.github.io/EasyMLTraining.jl/stable/)
[![CI main](https://github.com/OML-NPA/EasyMLTraining.jl/actions/workflows/CI-main.yml/badge.svg)]((https://github.com/OML-NPA/EasyMLTraining.jl/actions/CI-main))
[![CI dev](https://github.com/OML-NPA/EasyMLTraining.jl/actions/workflows/CI-dev.yml/badge.svg)]((https://github.com/OML-NPA/EasyMLTraining.jl/actions/CI-dev))
[![codecov](https://codecov.io/gh/OML-NPA/EasyMLTraining.jl/branch/main/graph/badge.svg?token=TDI9EH49LI)](https://codecov.io/gh/OML-NPA/EasyMLTraining.jl)

This package is a part of [EasyML.jl](https://github.com/OML-NPA/EasyML.jl).

NB! This is a beta version. Bugs and bracking changes should be expected.

### Features

A GUI based training loop with 
 - GPU support
 - support for changing in real time
    - number of epochs
    - learning rate
    - number of tests

Classification, regression and segmentation on any data with [Flux.jl](https://github.com/FluxML/Flux.jl) models are supported.

<img src="https://github.com/OML-NPA/EasyML.jl/blob/dev/docs/src/assets/images/train.png" height="290">

### Installation

Run `] add https://github.com/OML-NPA/EasyMLTraining.jl` in REPL.
