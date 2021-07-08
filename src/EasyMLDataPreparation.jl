
module EasyMLDataPreparation

# Import packages
using
# Interfacing
QML, Qt5QuickControls2_jll, Qt5Charts_jll, CxxWrap,
# Data structuring
Parameters, DataFrames,
# Data import/export
FileIO, ImageIO, JSON, BSON, XLSX, CSVFiles,
# Data manipulation
Unicode,
# Image manipulation
Images, ColorTypes, ImageFiltering, ImageTransformations, 
ImageMorphology, DSP, ImageMorphology.FeatureTransform, ImageSegmentation, 
# Math functions
StatsBase, Statistics, LinearAlgebra, Combinatorics,
# Other
ProgressMeter, FLoops

# Include functions
include("data_structures.jl")
include("common/all.jl")
include("common/channels_functions.jl")
include("common/exported_functions.jl")
include("common/preparation_validation.jl")
include("common/preparation_validation_application.jl")
include("common/preparation_training_validation_application.jl")
include("image_processing.jl")
include("data_preparation.jl")
include("exported_functions.jl")

export QML, ColorTypes

export model_data, ImageClassificationClass, ImageRegressionClass, ImageSegmentationClass, options, pre_data, 
    data_preparation_options, global_options
export set_problem_type, set_savepath, load_options, make_classes, modify, save_model, load_model, get_urls, prepare_data

function __init__()
    # Needed to avoid an endless loop for Julia canvas
    ENV["QSG_RENDER_LOOP"] = "basic"
    load_options()
end

end
