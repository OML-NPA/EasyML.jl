
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
Images, ColorTypes, ImageFiltering, ImageTransformations, 
ImageMorphology, DSP, ImageMorphology.FeatureTransform, ImageSegmentation, 
# Machine learning
Flux, Flux.Losses, FluxExtra, 
# Math functions
Random, StatsBase, LinearAlgebra,
# Other
FLoops,
# EasyML ecosystem
..Core, ..Core.Classes, ..Core.Validation

import CUDA.CuArray, StatsBase.std
import ..Classes
import ..Classes: make_classes, num_classes, get_class_field, get_class_data, 
    get_problem_type, get_input_type

# Include functions
include(string(core_dir(),"/common/training_validation.jl"))
include(string(core_dir(),"/common/validation_application.jl"))
include(string(core_dir(),"/common/preparation_validation.jl"))
include(string(core_dir(),"/common/preparation_validation_application.jl"))
include(string(core_dir(),"/common/image_processing.jl"))
include("main.jl")
include("exported_functions.jl")

export validation_options, validation_results_data, get_urls_validation, 
    validate, remove_validation_data, remove_validation_results

end
