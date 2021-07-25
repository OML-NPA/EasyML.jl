
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
Images, ColorTypes, ImageFiltering, ImageTransformations, 
ImageMorphology, DSP, ImageMorphology.FeatureTransform, ImageSegmentation, 
# Machine learning
Flux, Flux.Losses, FluxExtra, 
# Math functions
Random, StatsBase, LinearAlgebra,
# Other
FLoops,
# EasyML ecosystem
EasyML.Core, EasyML.Core.Classes, EasyML.Core.Application

import CUDA.CuArray, StatsBase.std
import EasyML.Classes
import EasyML.Classes: make_classes, num_classes, get_class_field, get_class_data, 
    get_problem_type, get_input_type

# Include functions
include(string(core_dir(),"/common/validation_application.jl"))
include(string(core_dir(),"/common/preparation_validation_application.jl"))
include("output_methods.jl")
include("main.jl")
include("exported_functions.jl")

export application_options, get_urls_application, apply, remove_application_data

end
