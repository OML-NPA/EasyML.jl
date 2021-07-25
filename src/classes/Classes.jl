
module Classes

# Import packages
using 
# EasyML ecosystem
..Core, ..Core.Classes

# Include functions
include(string(core_dir(),"/common/classes_design.jl"))
include("main.jl")
include("exported_functions.jl")

export make_classes

end
