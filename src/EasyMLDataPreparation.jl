
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
# Machine Learning
EasyMLCore,
# Math functions
StatsBase, Statistics, LinearAlgebra, Combinatorics,
# Other
ProgressMeter, FLoops

# Machine Learning
import EasyMLClasses
import EasyMLClasses: ImageClassificationClass, ImageRegressionClass, ImageSegmentationClass, make_classes

# Include functions
include("data_structures.jl")
include("common/all.jl")
include("common/exported_functions.jl")
include("common/preparation_validation.jl")
include("common/preparation_validation_application.jl")
include("image_processing.jl")
include("main.jl")
include("exported_functions.jl")

export QML, ColorTypes

export Classification, Regression, Segmentation, Image, model_data, ImageClassificationClass, ImageRegressionClass, 
    ImageSegmentationClass, options, prepare_data, data_preparation_options, global_options
export set_problem_type, set_savepath, load_options, make_classes, modify, save_model, load_model, get_urls, prepare_data
export setproperty!, getproperty

function __init__()
    ENV["QSG_RENDER_LOOP"] = "basic" # Needed to avoid an endless loop for Julia canvas
    
    bind!(EasyMLClasses.model_data, model_data)
    bind!(EasyMLClasses.all_data, all_data)
    bind!(EasyMLClasses.graphics, graphics)
    bind!(EasyMLClasses.unit_test, unit_test)

    load_options()
end

end
