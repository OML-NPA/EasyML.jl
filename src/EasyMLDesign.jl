
module EasyMLDesign

# Import packages
using
# Machine learning
Flux, Flux.Losses, FluxExtra,
# Math functions
Statistics

using EasyMLCore, EasyMLCore.Design, EasyMLCore.Layers

import Flux.outputsize, QML

# Include functions
include("common/design_classes.jl")
include("main.jl")
include("exported_functions.jl")

export QML, Flux, FluxExtra, NNlib

export model_data, Classification, Regression, Segmentation, Image
export set_savepath, set_problem_type, set_input_type, save_options, load_options, save_model, load_model
export design_model
export Join, Split, Addition, Activation, Flatten, Identity

function __init__()
    EasyMLCore.add_templates(string(@__DIR__,"/gui/Design.qml"))
    EasyMLCore.add_templates(string(@__DIR__,"/gui/DesignOptions.qml"))

    load_options()
end

end
