
module Training

# Import packages
using
# Interfacing
CUDA, Qt5Charts_jll,
# Data structuring
Dates,
# Machine learning
Flux, FluxExtra,
# Math functions
Random, StatsBase, LinearAlgebra, Combinatorics, Distances,
# EasyML ecosystem
..Common, ..Common.Training

import CUDA.CuArray, StatsBase.std
import ..Common.DataPreparation: ClassificationData, RegressionData, SegmentationData

# Include functions
include(string(common_dir(),"/common/training_validation.jl"))
include("main.jl")
include("exported_functions.jl")

export training_options, TrainingOptions, training_results_data
export set_weights, set_training_data, set_testing_data, train, remove_training_data, remove_testing_data, remove_training_results

end
