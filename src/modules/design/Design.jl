
module Design

# Import packages
using
# Machine Learning
Flux, Flux.Losses, FluxExtra, FluxExtra.Normalizations,
# Math functions
Statistics,
# EasyML ecosystem
..Common, ..Common.Design, ..Common.Layers

import Flux.outputsize, ..Common.none

# Include functions
include(string(common_dir(),"/common/classes_design.jl"))
include("main.jl")
include("exported_functions.jl")

export design_model

end
