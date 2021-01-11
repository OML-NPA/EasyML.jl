
module MLGUI
# Needed to avoid an endless loop for Julia canvas
ENV["QSG_RENDER_LOOP"] = "basic"
# Import packages
using
# Interfacing
QML, CxxWrap, CUDAapi,
# Data structuring
Parameters, DataFrames, StaticArrays, Dates,
# Data import/export
FileIO, ImageIO, JSON, BSON, XLSX,
# Image manipulation
Images, ImageFiltering, ImageTransformations, ImageMorphology, DSP,
ImageMorphology.FeatureTransform, ImageSegmentation,
# Machine learning
Flux, Flux.Losses,
# Math functions
Random, StatsBase, Statistics, LinearAlgebra, Combinatorics, Distances,
# Other
Plots, Distributed, ParallelDataTransfer
import Base.any
import CUDA, CUDA.CuArray, Flux.outdims
# Other
CUDA.allowscalar(false)

# Import functions

include("data_structures.jl")
include("handling_channels.jl")
include("handling_data.jl")
include("helper_functions.jl")
include("image_processing.jl")
include("layers.jl")
include("design.jl")
include("training.jl")
include("training_common.jl")
include("validation.jl")
include("analysis.jl")

export model_data, training, settings, training_data, training_plot_data,
    training_results_data, validation_results_data, Model_data, Feature,
    Output_options, Output_volume, Output_area, Output_mask
export design_network, load_model, get_urls, prepare_training_data, train,
    prepare_validation_data, validate, prepare_analysis_data, forward, apply_border_data
export Parallel, Catenation, Decatenation, Addition, Upscaling, Activation, Identity

@everywhere using QML, Flux

end
