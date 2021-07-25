
module EasyMLDesign

# Import packages
using
# Machine Learning
Flux, Flux.Losses, FluxExtra, FluxExtra.Normalizations,
# Math functions
Statistics,
# EasyML ecosystem
EasyMLCore, EasyMLCore.Design, EasyMLCore.Layers

import Flux.outputsize, EasyMLCore.none

# Include functions
include("common/design_classes.jl")
include("main.jl")
include("exported_functions.jl")

export QML, Flux, Losses, FluxExtra, Normalizations, NNlib

export Join, Split, Addition, Activation, Flatten, Identity
export model_data
export set_savepath, save_options, load_options, save_model, load_model
export design_model

function __init__()
    load_options()
end

end
