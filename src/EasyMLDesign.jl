
module EasyMLDesign

# Import packages
using
# Interfacing
QML, Qt5QuickControls2_jll, Qt5Charts_jll, CxxWrap,
# Data structuring
Parameters, Dates,
# Data import/export
FileIO, BSON,
# Machine learning
Flux, Flux.Losses, FluxExtra,
# Math functions
StatsBase,
# Other
FLoops

import Flux.outdims

# Include functions
include("data_structures.jl")
include("Common/all.jl")
include("Common/exported_functions.jl")
include("design.jl")
include("exported_functions.jl")

export QML, Flux, FluxExtra, NNlib, ColorTypes

export ImageClassificationClass, ImageRegressionClass, ImageSegmentationClass, options, global_options
export load_options, design_model, modify_classes, save_model, load_model
export Join, Split, Addition, Activation, Identity

function __init__()
    # Needed to avoid an endless loop for Julia canvas
    ENV["QSG_RENDER_LOOP"] = "basic"
    load_options()
end

end
