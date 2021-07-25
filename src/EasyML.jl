
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
Random, StatsBase, LinearAlgebra, Combinatorics,
# Other
ProgressMeter, FLoops

import CUDA.CuArray, Flux.outdims, StatsBase.std

# Include functions
include("core/Core.jl")
include("classes/Classes.jl")
include("design/Design.jl")
include("datapreparation/DataPreparation.jl")
include("training/Training.jl")
include("validation/Validation.jl")
include("application/Application.jl")

using .Core, .Classes, .Design, .Training, .Validation, .Application

export QML, CUDA, Flux, FluxExtra, Normalizations, NNlib, ColorTypes

export Join, Split, Addition, Activation, Flatten, Identity
export model_data, global_options, data_preparation_options, training_options, validation_options, application_options
export set_savepath, save_options, load_options, modify, save_model, load_model
export make_classes, prepare_training_data, get_urls_training, get_urls_testing, prepare_testing_data, train, 
    remove_training_data, remove_testing_data, remove_training_results, validation_results_data, get_urls_validation, 
    validate, remove_validation_data, remove_validation_results, get_urls_application, apply, remove_application_data

function __init__()
    load_options()
    # Needed to avoid an endless loop for Julia canvas
    ENV["QSG_RENDER_LOOP"] = "basic"
end

end
