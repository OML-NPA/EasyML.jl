
module EasyMLCore

using Parameters, Flux, BSON, QML

import Base.getproperty, Base.setproperty!, Base.RefValue

# Include functions
include("data_structures.jl")
include("functions.jl")

export 
# Functions
getproperty, setproperty!, bind!,
# Abstract types
AbstractEasyML, AbstractProblemType, AbstractInputType, AbstractInputProperty,
# Problem types
Classification, Regression, Segmentation,
# Input types
Image,
# Input properties
Grayscale,
# Struct to Dict interconversion
struct_to_dict!, dict_to_struct!, to_struct!,
# Model saving/loading
save_model, load_model, 
# Options saving/loading
save_options, load_options,
# GUI data handling
fix_QML_types, get_data, get_options, set_options,
# Other
RefValue

end
