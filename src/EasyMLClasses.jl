
module EasyMLClasses

# Import packages
using
# Machine learning
Flux, FluxExtra

using EasyMLCore, EasyMLCore.Classes

# Include functions
include("common/design_classes.jl")
include("main.jl")
include("exported_functions.jl")

export QML, Flux, FluxExtra

export model_data, Classification, Regression, Segmentation, Image, 
    ImageClassificationClass, ImageRegressionClass, ImageSegmentationClass
export save_model, load_model
export make_classes

end
