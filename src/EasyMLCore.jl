
module EasyMLCore

# Include dependencies
using Parameters, Flux, BSON, QML, Qt5QuickControls2_jll, Dates, ColorTypes, FixedPointNumbers

# Include modules
include("modules/Classes.jl")
include("modules/Layers.jl")
using .Classes, .Layers

# Include functions
include("data_structures.jl")
include("functions.jl")

# Problem types
export AbstractProblemType, Classification, Regression, Segmentation
# Input types
export AbstractInputType, Image
# Input properties
export AbstractInputProperty, Grayscale
# Struct to Dict interconversion
export struct_to_dict!, dict_to_struct!, to_struct!
# Model saving/loading
export ModelData, set_savepath, save_model, load_model
# Options saving/loading
export save_options, load_options
# GUI data handling
export fix_QML_types, get_data, get_options, set_data, set_options, get_file, get_folder
# Handling channels
export check_progress, get_progress, empty_channel, put_channel
# Options
export modify, global_options
# Other
export set_problem_type, set_input_type, problem_type, input_type, model_data, check_task, 
    unit_test

end