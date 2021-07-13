
module EasyMLDesign

# Import packages
using
# Interfacing
QML, Qt5QuickControls2_jll,
# Data structuring
Parameters,
# Machine learning
Flux, Flux.Losses, FluxExtra, EasyMLCore, EasyMLCore.Layers,
# Math functions
Statistics

import Flux.outputsize

# Include functions
include("data_structures.jl")
include("common/all.jl")
include("common/design_classes.jl")
include("common/exported_functions.jl")
include("main.jl")
include("exported_functions.jl")

export QML, Flux, FluxExtra, NNlib

export Classification, Regression, Segmentation, options, global_options
export set_savepath, set_problem_type, save_options, load_options, design_model, save_model, load_model
export model_data, Join, Split, Addition, Activation, Flatten, Identity

function __init__()
    # Needed to avoid an endless loop for Julia canvas
    ENV["QSG_RENDER_LOOP"] = "basic"
    load_options()
end

end
