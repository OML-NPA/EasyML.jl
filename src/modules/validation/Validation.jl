
module Validation

# Import packages
using
# Interfacing
CxxWrap, CUDA,
# Data import/export
FileIO, ImageIO, XLSX, CSVFiles,
# Data manipulation
Unicode, DataFrames,
# Image manipulation
Images, ColorTypes,
# Machine learning
Flux, Flux.Losses, FluxExtra, 
# Math functions
Random, StatsBase, LinearAlgebra,
# Other
FLoops,
# EasyML ecosystem
..Common, ..Common.Classes, ..Common.Validation

import CUDA.CuArray, StatsBase.std
import ..Classes
import ..Classes: change_classes, num_classes, get_class_field, get_class_data, 
    get_problem_type, get_input_type

# Include functions
include(string(common_dir(),"/common/training_validation.jl"))
include(string(common_dir(),"/common/validation_application.jl"))
include(string(common_dir(),"/common/preparation_validation.jl"))
include(string(common_dir(),"/common/preparation_validation_application.jl"))
include("main.jl")
include("exported_functions.jl")

export validation_options, ValidationOptions, validation_results_data
export get_urls_validation, validate, remove_validation_data, remove_validation_results

end
