
#__precompile__(false)

module MLGUI
# Needed to avoid an endless loop for Julia canvas
ENV["QSG_RENDER_LOOP"] = "basic"
# Import packages
using
# Interfacing
QML, Qt5QuickControls2_jll, Qt5Charts_jll, CxxWrap, CUDA,
# Data structuring
Parameters, DataFrames, StaticArrays, Dates,
# Data import/export
FileIO, ImageIO, JSON, BSON, XLSX,
# Image manipulation
Images, ImageFiltering, ImageTransformations, ImageMorphology, DSP,
ImageMorphology.FeatureTransform, ImageSegmentation,
# Machine learning
Flux, Flux.Losses, FluxExtra,
# Math functions
Random, StatsBase, Statistics, LinearAlgebra, Combinatorics, Distances,
# Other
ProgressMeter

import CUDA.CuArray, Flux.outdims, .Threads.@threads

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
include("extra_functions.jl")

export QML, Flux, FluxExtra, CUDA, NNlib

export model_data, Segmentation_feature, training, settings, training_data, training_plot_data,
    training_results_data, training_options, validation_data, validation_results_data,
    application_data, application_options
export design_network, modify, modify_output, save_model, load_model, get_urls_training, prepare_training_data, train,
    get_urls_validation, validate, get_urls_application, apply, forward, apply_border_data
export Join, Split, Addition, Activation, Identity


function __init__()
    # Import the configutation file
    if isfile("config.bson")
        try
            load_settings()
        catch
            save_settings()
        end 
    else
        save_settings()
    end
end

end
