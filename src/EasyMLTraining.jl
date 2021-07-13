
module EasyMLTraining

# Import packages
using
# Interfacing
QML, Qt5QuickControls2_jll, Qt5Charts_jll, CxxWrap, CUDA,
# Data structuring
Parameters, Dates,
# Data import/export
BSON,
# Machine learning
Flux, Flux.Losses, FluxExtra, EasyMLCore,
# Math functions
Random, StatsBase, LinearAlgebra, Combinatorics, Distances

import CUDA.CuArray, Flux.outdims, StatsBase.std

# Include functions
include("data_structures.jl")
include("common/all.jl")
include("common/exported_functions.jl")
include("common/training_validation.jl")
include("main.jl")
include("exported_functions.jl")

export QML, Flux, FluxExtra, CUDA, NNlib, ColorTypes

export Classification, Regression, Segmentation, Image, model_data, global_options, training_options, training_results_data
export load_options, modify, set_savepath, save_model, load_model, set_problem_type, set_weights, set_training_data, set_testing_data, train,
    remove_training_data, remove_testing_data, remove_training_results
export Join, Split, Addition, Activation, Flatten, Identity

function __init__()
    # Needed to avoid an endless loop for Julia canvas
    ENV["QSG_RENDER_LOOP"] = "basic"
    load_options()
end

end
