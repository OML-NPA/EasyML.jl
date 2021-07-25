
module DataPreparation

# Import packages
using
# Data structuring
DataFrames,
# Data import/export
FileIO, ImageIO, XLSX, CSVFiles,
# Data manipulation
Unicode,
# Image manipulation
Images, ColorTypes, ImageFiltering, ImageTransformations, 
ImageMorphology, DSP, ImageMorphology.FeatureTransform, ImageSegmentation, 
# Math functions
StatsBase, Statistics, LinearAlgebra, Combinatorics,
# Other
ProgressMeter, FLoops,
# EasyML ecosystem
..Core, ..Core.Classes, ..Core.DataPreparation

import ..Classes
import ..Classes: make_classes

# Include functions
include(string(core_dir(),"/common/preparation_validation.jl"))
include(string(core_dir(),"/common/preparation_validation_application.jl"))
include("image_processing.jl")
include("main.jl")
include("exported_functions.jl")

export get_urls, prepare_data, data_preparation_options

end
