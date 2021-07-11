
module EasyMLValidation

# Import packages
using Base: String
using
# Interfacing
QML, Qt5QuickControls2_jll, Qt5Charts_jll, CxxWrap, CUDA,
# Data structuring
Parameters,
# Data import/export
FileIO, ImageIO, BSON, XLSX, CSVFiles,
# Data manipulation
Unicode, DataFrames,
# Image manipulation
Images, ColorTypes, ImageFiltering, ImageTransformations, 
ImageMorphology, DSP, ImageMorphology.FeatureTransform, ImageSegmentation, 
# Machine learning
Flux, Flux.Losses, FluxExtra, EasyMLClasses,
# Math functions
Random, StatsBase, LinearAlgebra,
# Other
FLoops

import Base.RefValue, CUDA.CuArray, StatsBase.std
import EasyMLClasses: num_classes, get_class_field, 
    EasyMLClasses.get_class_data, get_problem_type, get_input_type

# Include functions
include("data_structures.jl")
include("common/all.jl")
include("common/channels_functions.jl")
include("common/exported_functions.jl")
include("common/training_validation.jl")
include("common/validation_application.jl")
include("common/preparation_validation.jl")
include("common/preparation_validation_application.jl")
include("common/preparation_training_validation_application.jl")
include("image_processing.jl")
include("main.jl")
include("exported_functions.jl")

export QML, Flux, FluxExtra, CUDA, NNlib, ColorTypes

export model_data, options, validation_results_data, global_options
export make_classes, load_options, modify, save_model, load_model, get_urls_validation, validate, 
    remove_validation_data, remove_validation_results
export Join, Split, Addition, Activation, Flatten, Identity
export getproperty, setproperty!

# export all
for n in names(@__MODULE__; all=true)
    if Base.isidentifier(n) && n ∉ (Symbol(@__MODULE__), :eval, :include)
        @eval export $n
    end
end

function __init__()
    ENV["QSG_RENDER_LOOP"] = "basic" # Needed to avoid an endless loop for Julia canvas

    bind!(EasyMLClasses.model_data, model_data)
    bind!(EasyMLClasses.all_data, all_data)
    bind!(EasyMLClasses.graphics, graphics)
    bind!(EasyMLClasses.unit_test, unit_test)

    load_options()
end

end
