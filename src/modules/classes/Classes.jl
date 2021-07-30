
module Classes

# Import packages
using 
# EasyML ecosystem
..Common, ..Common.Classes

# Include functions
include(string(common_dir(),"/common/classes_design.jl"))
include("main.jl")
include("exported_functions.jl")

export change_classes

end
