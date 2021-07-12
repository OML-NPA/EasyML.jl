
module EasyMLCore

import Base.getproperty, Base.setproperty!, Base.RefValue

# Include functions
include("data_structures.jl")

export 
# Functions
getproperty, setproperty!, bind!,
# Abstract types
AbstractEasyML, AbstractProblemType, AbstractInputType,
# Problem types
Classification, Regression, Segmentation ,
# Input types
Image,
# Other
RefValue

end
