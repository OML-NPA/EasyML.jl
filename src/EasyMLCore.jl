
module EasyMLCore

using Parameters, Flux, BSON, QML

import Base.getproperty, Base.setproperty!, Base.RefValue

# Include functions
include("data_structures.jl")
include("functions.jl")

# Functions
export  getproperty, setproperty!, bind!
# Abstract types
export AbstractEasyML, AbstractProblemType, AbstractInputType, AbstractInputProperty
# Problem types
export Classification, Regression, Segmentation
# Input types
export Image
# Input properties
export Grayscale
# Struct to Dict interconversion
export struct_to_dict!, dict_to_struct!, to_struct!
# Model saving/loading
export save_model_main, load_model_main
# Options saving/loading
export save_options_main, load_options_main
# GUI data handling
export fix_QML_types, get_data_main, set_data_main
# Handling channels
export check_progress_main, get_progress_main, empty_progress_channel_main, put_channel_main
# Other
export RefValue

end
