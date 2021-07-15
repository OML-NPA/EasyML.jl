
module EasyMLClasses

# Import packages
using
# Interfacing
QML, Qt5QuickControls2_jll,
# Machine learning
Flux, FluxExtra, EasyMLCore, EasyMLCore.Classes

# Include functions
include("common/design_classes.jl")
include("main.jl")
include("exported_functions.jl")

export QML, Flux

export model_data, Classification, Regression, Segmentation, Image, 
    ImageClassificationClass, ImageRegressionClass, ImageSegmentationClass
export save_model, load_model
export make_classes

function __init__()
    # Needed to avoid an endless loop for Julia canvas
    ENV["QSG_RENDER_LOOP"] = "basic"

    EasyMLCore.add_templates(string(@__DIR__,"/gui/ClassDialog.qml"))
end

end
