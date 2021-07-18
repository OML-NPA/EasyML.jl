
module EasyMLTraining

# Import packages
using
# Interfacing
CUDA, Qt5Charts_jll,
# Data structuring
Dates,
# Machine learning
Flux, FluxExtra,
# Math functions
Random, StatsBase, LinearAlgebra, Combinatorics, Distances,
# EasyML ecosystem
EasyMLCore, EasyMLCore.Training

import CUDA.CuArray, StatsBase.std

# Include functions
include("common/training_validation.jl")
include("main.jl")
include("exported_functions.jl")

export QML, CUDA, Flux, FluxExtra, Normalizations, NNlib, ColorTypes

export Join, Split, Addition, Activation, Flatten, Identity
export model_data, Classification, Regression, Segmentation, Image, Grayscale
export global_options, training_options, load_options, modify, set_savepath, save_model, load_model
export set_weights, set_training_data, set_testing_data, train, remove_training_data, remove_testing_data, remove_training_results


function __init__()
    load_options()
end

end
