
module Application

# Import packages
using
# Interfacing
CUDA,
# Data import/export
FileIO, ImageIO, CSVFiles, XLSX, JSON, BSON,
# Data manipulation
Unicode, DataFrames,
# Image manipulation
Images, ColorTypes, ImageFiltering, ImageMorphology.FeatureTransform, ImageSegmentation, 
# Machine learning
Flux, Flux.Losses, FluxExtra, 
# Math functions
Random, StatsBase, LinearAlgebra,
# Other
FLoops, ProgressMeter,
# EasyML ecosystem
..Common, ..Common.Classes, ..Common.Application

import CUDA.CuArray, StatsBase.std
import ..Classes
import ..Classes: change_classes, num_classes, get_class_field, get_class_data, 
    get_problem_type, get_input_type

# Include functions
include(string(common_dir(),"/common/validation_application.jl"))
include(string(common_dir(),"/common/preparation_validation_application.jl"))
include("output_methods.jl")
include("main.jl")
include("exported_functions.jl")

export application_options, ApplicationOptions
export change_output_options, get_urls_application, apply, remove_application_data, forward, apply_border_data

end
