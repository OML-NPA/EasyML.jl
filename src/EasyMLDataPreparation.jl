
module EasyMLDataPreparation

# Import packages
using
# Data structuring
DataFrames,
# Data import/export
FileIO, ImageIO, XLSX, CSVFiles,
# Data manipulation
Unicode,
# Image manipulation
Images, ColorTypes, ImageFiltering, ImageTransformations, 
ImageMorphology, DSP, ImageMorphology.FeatureTransform, ImageSegmentation, 
# Math functions
StatsBase, Statistics, LinearAlgebra, Combinatorics,
# Other
ProgressMeter, FLoops,
# EasyML ecosystem
EasyMLCore, EasyMLCore.Classes, EasyMLCore.DataPreparation

import EasyMLClasses
import EasyMLClasses: make_classes

# Include functions
include("common/preparation_validation.jl")
include("common/preparation_validation_application.jl")
include("image_processing.jl")
include("main.jl")
include("exported_functions.jl")

export QML, Flux, Losses, FluxExtra, Normalizations, NNlib

export Join, Split, Addition, Activation, Flatten, Identity
export model_data, Classification, Regression, Segmentation, Image
export set_savepath, modify, save_options, load_options, save_model, load_model
export make_classes, get_urls, prepare_data, data_preparation_options
 
function __init__()
    load_options()
end

end
