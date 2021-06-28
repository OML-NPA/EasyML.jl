
module EasyML

# Import packages
using
# Interfacing
QML, Qt5QuickControls2_jll, Qt5Charts_jll, CxxWrap, CUDA,
# Data structuring
Parameters, DataFrames, Dates,
# Data import/export
FileIO, ImageIO, JSON, BSON, XLSX, CSVFiles,
# Data manipulation
Unicode,
# Image manipulation
Images, ColorTypes, ImageFiltering, ImageTransformations, 
ImageMorphology, DSP, ImageMorphology.FeatureTransform, ImageSegmentation, 
# Machine learning
Flux, Flux.Losses, FluxExtra,
# Math functions
Random, StatsBase, LinearAlgebra, Combinatorics, Distances,
# Other
ProgressMeter, FLoops

import CUDA.CuArray, Flux.outdims, StatsBase.std

# Include functions
include("data_structures.jl")
include("handling_channels.jl")
include("handling_data.jl")
include("helper_functions.jl")
include("image_processing.jl")
include("design.jl")
include("training.jl")
include("common.jl")
include("validation.jl")
include("application.jl")
include("exported_functions.jl")

export QML, Flux, FluxExtra, CUDA, NNlib, ColorTypes

export model_data, ImageClassificationClass, ImageRegressionClass, ImageSegmentationClass, training, options, training_data, 
    training_plot_data, training_results_data, training_options, validation_data, validation_results_data,
    application_data, application_options, global_options
export load_options, design_network, modify_classes, modify_output, modify, save_model, load_model, 
    get_urls_training, get_urls_testing, prepare_training_data, prepare_testing_data, remove_training_data, remove_testing_data, 
    remove_training_results, train, get_urls_validation, validate, remove_validation_data, remove_validation_results, 
    get_urls_application, apply, remove_application_data, forward, apply_border_data
export Join, Split, Addition, Activation, Identity

function __init__()
    # Needed to avoid an endless loop for Julia canvas
    ENV["QSG_RENDER_LOOP"] = "basic"
    load_options()
end

end
