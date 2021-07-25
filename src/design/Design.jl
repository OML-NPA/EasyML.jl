
module Design

# Import packages
using
# Machine Learning
Flux, Flux.Losses, FluxExtra, FluxExtra.Normalizations,
# Math functions
Statistics,
# EasyML ecosystem
..Core, ..Core.Design, ..Core.Layers

import Flux.outputsize, ..Core.none

# Include functions
include(string(core_dir(),"/common/classes_design.jl"))
include("main.jl")
include("exported_functions.jl")

export design_model

end
