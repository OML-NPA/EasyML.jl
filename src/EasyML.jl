
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
include("modules/common/Common.jl")
include("modules/classes/Classes.jl")
include("modules/design/Design.jl")
include("modules/datapreparation/DataPreparation.jl")
include("modules/training/Training.jl")
include("modules/validation/Validation.jl")
include("modules/application/Application.jl")

using .Common, .Classes, .Design, .DataPreparation, .Training, .Validation, .Application

import .Training: TrainingOptions, TrainingData, TestingData, training_data, testing_data
import .DataPreparation.preparation_data, .Validation.validation_data, .Application.application_data

include("exported_functions.jl")

export QML, CUDA, Flux, FluxExtra, Normalizations, NNlib, ColorTypes

export Join, Split, Addition, Activation, Flatten, Identity
export ImageClassificationClass, ImageRegressionClass, BorderClass, ImageSegmentationClass
export model_data, global_options, data_preparation_options, training_options, validation_options, application_options,
    preparation_data, training_data, validation_data, application_data
export set_savepath, save_options, load_options, change, save_model, load_model
export change_classes, design_model, prepare_training_data, get_urls_training, get_urls_testing, prepare_testing_data, train, 
    remove_training_data, remove_testing_data, remove_training_results, validation_results_data, get_urls_validation, 
    validate, remove_validation_data, remove_validation_results, get_urls_application, change_output_options, apply, remove_application_data

function __init__()
    load_options()
    # Needed to avoid an endless loop for Julia canvas
    ENV["QSG_RENDER_LOOP"] = "basic"
end

end
