
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
..Common, ..Common.Classes, ..Common.DataPreparation

import ..Classes
import ..Classes: change_classes
import ..Common.dilate!

# Include functions
include(string(common_dir(),"/common/preparation_validation.jl"))
include(string(common_dir(),"/common/preparation_validation_application.jl"))
include("main.jl")
include("exported_functions.jl")

export data_preparation_options
export get_urls, prepare_data

end
