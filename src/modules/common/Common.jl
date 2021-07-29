
module Common

# Include dependencies
using
# Interfacing
QML, Qt5QuickControls2_jll,
# Data structuring
Parameters, Dates,
# Data import/export
BSON,
# Image manipulation
Images, ColorTypes, ImageFiltering, ImageTransformations, 
ImageMorphology, DSP, ImageMorphology.FeatureTransform, ImageSegmentation,
# Maths
Statistics,
# Machine learning
Flux, Flux.Losses, FluxExtra,
# Other
FLoops


include("misc.jl")
# Include modules
include("data structures/Classes.jl")
include("data structures/Design.jl")
include("data structures/DataPreparation.jl")
include("data structures/Application.jl")
include("data structures/Training.jl")
include("data structures/Validation.jl")


using .Classes, .Design.Layers

import .Design: DesignData, design_data, DesignOptions, design_options
import .DataPreparation: PreparationData, preparation_data, DataPreparationOptions, data_preparation_options
import .Training: TrainingData, TestingData, training_data, testing_data, TrainingOptions, training_options
import .Validation: ValidationData, validation_data, ValidationOptions, validation_options
import .Application: AbstractOutputOptions, ImageClassificationOutputOptions, ImageRegressionOutputOptions, 
    ImageSegmentationOutputOptions, ApplicationData, application_data, ApplicationOptions, application_options

# Include data structures and functions
include("data_structures.jl")
include("functions.jl")
include("image_processing.jl")

# Struct to Dict interconversion
export struct_to_dict!, dict_to_struct!, to_struct!
# Model data
export model_data, ModelData, AbstractModel, set_savepath, save_model, load_model,
    ImageClassificationClass, ImageRegressionClass, ImageSegmentationClass, none
# Options
export modify, global_options, options, Options, save_options, load_options
# GUI data handling
export fix_QML_types, get_data, get_options, set_data, set_options, get_file, get_folder
# Channels
export channels, Channels, check_progress, get_progress, empty_channel, put_channel
# Other
export all_data, AllData, problem_type, input_type, check_task, unit_test, common_dir, add_templates, setproperty!
# Image processing
export dilate!, erode!, closing!, areaopen!, outer_perim, rotate_img, conn, conn,
    component_intensity, segment_objects, allequal, alldim


# QML functions
export QML, @qmlfunction, QByteArray, loadqml, exec
# Machine learning
export Flux, Losses, FluxExtra, Normalizations, NNlib

end