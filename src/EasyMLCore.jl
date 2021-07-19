
module EasyMLCore

# Include dependencies
using
# Interfacing
QML, Qt5QuickControls2_jll,
# Data structuring
Parameters, Dates,
# Image manipulation
ColorTypes, FixedPointNumbers,
# Maths
Statistics,
# Machine learning
Flux, Flux.Losses, FluxExtra

import BSON as BSON_pkg

include("modules/Common.jl")
using .Common
# Include modules
include("modules/Classes.jl")
include("modules/Design.jl")
include("modules/DataPreparation.jl")
include("modules/Training.jl")
include("modules/Validation.jl")
include("modules/Application.jl")

using .Classes, .Design.Layers, .DataPreparation.InputProperties, .Application.Types

import .Design: DesignData, design_data, DesignOptions, design_options
import .DataPreparation: PreparationData, preparation_data, DataPreparationOptions, data_preparation_options
import .Training: TrainingData, TestingData, training_data, testing_data, TrainingOptions, training_options
import .Validation: ValidationData, validation_data, ValidationOptions, validation_options
import .Application: ApplicationData, application_data, ApplicationOptions, application_options

# Include data structures and functions
include("data_structures.jl")
include("functions.jl")

# Problem types
export AbstractProblemType, Classification, Regression, Segmentation
# Input types
export AbstractInputType, Image
# Input properties
export AbstractInputProperty, Grayscale
# Struct to Dict interconversion
export struct_to_dict!, dict_to_struct!, to_struct!
# Model data
export model_data, ModelData, AbstractModel, set_savepath, save_model, load_model
# Options
export modify, global_options, options, Options, save_options, load_options
# GUI data handling
export fix_QML_types, get_data, get_options, set_data, set_options, get_file, get_folder
# Channels
export channels, Channels, check_progress, get_progress, empty_channel, put_channel
# Other
export all_data, AllData, problem_type, input_type, check_task, unit_test, add_templates

# QML functions
export QML, @qmlfunction, QByteArray, loadqml, exec
# Machine learning
export Flux, Losses, FluxExtra, Normalizations, NNlib


function __init__()
    # Needed to avoid an endless loop for Julia canvas
    ENV["QSG_RENDER_LOOP"] = "basic"
end 

end