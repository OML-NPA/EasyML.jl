
module EasyMLClasses

# Import packages
using 
# EasyML ecosystem
EasyMLCore, EasyMLCore.Classes

# Include functions
include("common/design_classes.jl")
include("main.jl")
include("exported_functions.jl")

export QML, Flux, Losses, FluxExtra, Normalizations, NNlib

export model_data, Classification, Regression, Segmentation, Image, 
    ImageClassificationClass, ImageRegressionClass, ImageSegmentationClass
export set_savepath, set_problem_type, set_input_type, save_options, load_options, save_model, load_model
export make_classes

end
