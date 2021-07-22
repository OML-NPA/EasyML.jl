
module EasyMLValidation

# Import packages
using Base: String
using
# Interfacing
CxxWrap, CUDA,
# Data import/export
FileIO, ImageIO, XLSX, CSVFiles,
# Data manipulation
Unicode, DataFrames,
# Image manipulation
Images, ColorTypes, ImageFiltering, ImageTransformations, 
ImageMorphology, DSP, ImageMorphology.FeatureTransform, ImageSegmentation, 
# Machine learning
Flux, Flux.Losses, FluxExtra, 
# Math functions
Random, StatsBase, LinearAlgebra,
# Other
FLoops,
# EasyML ecosystem
EasyMLCore, EasyMLCore.Classes, EasyMLCore.Validation

import CUDA.CuArray, StatsBase.std
import EasyMLClasses
import EasyMLClasses: make_classes, num_classes, get_class_field, get_class_data, 
    get_problem_type, get_input_type

# Include functions
include("common/training_validation.jl")
include("common/validation_application.jl")
include("common/preparation_validation.jl")
include("common/preparation_validation_application.jl")
include("image_processing.jl")
include("main.jl")
include("exported_functions.jl")

export QML, CUDA, Flux, FluxExtra, Normalizations, NNlib, ColorTypes

export Join, Split, Addition, Activation, Flatten, Identity
export model_data
export global_options, load_options, modify, save_model, load_model
export make_classes, validation_options, validation_results_data, get_urls_validation, 
    validate, remove_validation_data, remove_validation_results

    
function __init__()
    load_options()
end

end
