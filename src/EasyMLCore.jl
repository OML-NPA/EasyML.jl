
module EasyMLCore

# Include dependencies
using
# Interfacing
QML, Qt5QuickControls2_jll,
# Data structuring
Parameters, Dates,
# Data import/export
BSON,
# Image manipulation
ColorTypes, FixedPointNumbers,
# Maths
Statistics,
# Machine learning
Flux, Flux.Losses, FluxExtra

# Include modules
include("modules/CoreTypes.jl")
using .CoreTypes
include("modules/Classes.jl")
include("modules/Design.jl")
include("modules/DataPreparation.jl")
include("modules/Training.jl")
include("modules/Validation.jl")
include("modules/Application.jl")

import .Design, .DataPreparation, .Training, .Validation, .Application
using .Classes, .Design.Layers, .DataPreparation.InputProperties

import .DataPreparation: PreparationData, preparation_data, none, Normalization
import .Design: DesignData, design_data, DesignOptions, design_options
import .DataPreparation: PreparationData, preparation_data, DataPreparationOptions, data_preparation_options
import .Training: TrainingData, TestingData, training_data, testing_data, TrainingOptions, training_options
import .Validation: ValidationData, validation_data
import .Application: ApplicationData, application_data, ApplicationOptions, application_options

# Include functions
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
# Model
export ModelData, AbstractModel, set_savepath, save_model, load_model
# Options
export modify, global_options, options, Options, save_options, load_options
# GUI data handling
export fix_QML_types, get_data, get_options, set_data, set_options, get_file, get_folder
# Channels
export channels, Channels, check_progress, get_progress, empty_channel, put_channel
# Other
export all_data, AllData, set_problem_type, set_input_type, problem_type, input_type, 
    model_data, check_task, unit_test, add_templates

# QML functions
export QML, @qmlfunction, QByteArray, loadqml, exec
# Machine learning
export Flux, Losses, FluxExtra, Normalizations, NNlib


function __init__()
    # Needed to avoid an endless loop for Julia canvas
    ENV["QSG_RENDER_LOOP"] = "basic"
end 

end