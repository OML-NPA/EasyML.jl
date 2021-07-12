
module EasyMLClasses

# Import packages
using
# Interfacing
QML, Qt5QuickControls2_jll, Qt5Charts_jll,
# Data structuring
Parameters,
# Data import/export
BSON,
# Machine learning
EasyMLCore

import EasyMLCore: AbstractClass, ImageClassificationClass, ImageRegressionClass, ImageSegmentationClass


# Include functions
include("data_structures.jl")
include("common/all.jl")
include("common/exported_functions.jl")
include("main.jl")
include("exported_functions.jl")

export QML

export model_data, Classification, Regression, Segmentation, Image, 
    ImageClassificationClass, ImageRegressionClass, ImageSegmentationClass
export make_classes, save_model, load_model
export getproperty, setproperty!

end
