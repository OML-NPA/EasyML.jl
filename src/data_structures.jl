
#---Channels

@with_kw struct Channels
    training_data_progress::Channel = Channel{Int64}(Inf)
    training_data_results::Channel = Channel{Any}(Inf)
    training_data_modifiers::Channel = Channel{Tuple{Int64,Float64}}(Inf) # 0 - abort
    testing_data_progress::Channel = Channel{Int64}(Inf)
    testing_data_results::Channel = Channel{Any}(Inf)
    testing_data_modifiers::Channel = Channel{Int64}(Inf) # 0 - abort
    training_progress::Channel = Channel{Any}(Inf)
    training_results::Channel = Channel{Any}(Inf)
    training_modifiers::Channel = Channel{Tuple{Int64,Float64}}(Inf) # 0 - abort; 1 - learning rate; 2 - epochs; 3 - number of tests
    validation_progress::Channel = Channel{Any}(Inf)
    validation_results::Channel = Channel{Any}(Inf)
    validation_modifiers::Channel = Channel{Tuple{Int64,Float64}}(Inf) # 0 - abort
    application_progress::Channel = Channel{Int64}(Inf)
    application_modifiers::Channel = Channel{Tuple{Int64,Float64}}(Inf) # 0 - abort
end
channels = Channels()

#---Model data

abstract type AbstractClass end

@with_kw mutable struct ImageClassificationClass<:AbstractClass
    name::String = ""
    weight::Float32 = 1
end

@with_kw mutable struct ImageRegressionClass<:AbstractClass
    name::String = ""
end

@with_kw mutable struct ImageSegmentationClass<:AbstractClass
    name::String = ""
    weight::Float32 = 1
    color::Vector{Float64} = Vector{Float64}(undef,3)
    border::Bool = false
    border_thickness::Int64 = 3
    border_remove_objs::Bool = false
    min_area::Int64 = 1
    parents::Vector{String} = ["",""]
    not_class::Bool = false
end

abstract type AbstractOutputOptions end

@with_kw mutable struct OutputMask
    mask::Bool = false
    mask_border::Bool = false
    mask_applied_border::Bool = false
end

@with_kw mutable struct OutputArea
    area_distribution::Bool = false
    obj_area::Bool = false
    obj_area_sum::Bool = false
    binning::Int64 = 0
    value::Float64 = 10
    normalisation::Int64 = 0
end

@with_kw mutable struct OutputVolume
    volume_distribution::Bool = false
    obj_volume::Bool = false
    obj_volume_sum::Bool = false
    binning::Int64 = 0
    value::Float64 = 10
    normalisation::Int64 = 0
end

@with_kw mutable struct ImageClassificationOutputOptions<:AbstractOutputOptions
    temp::Bool = false
end

@with_kw mutable struct ImageRegressionOutputOptions<:AbstractOutputOptions
    temp::Bool = false
end

@with_kw mutable struct ImageSegmentationOutputOptions<:AbstractOutputOptions
    Mask::OutputMask = OutputMask()
    Area::OutputArea = OutputArea()
    Volume::OutputVolume = OutputVolume()
end

abstract type AbstractLayerInfo end

@with_kw mutable struct GenericInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    group::String = ""
    type::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
end

@with_kw mutable struct InputInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    group::String = ""
    type::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    size::NTuple{3,Int64} = (0,0,0)
    normalisation::Tuple{String,Int64} = ("",0)
end

@with_kw mutable struct OutputInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    group::String = ""
    type::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    loss::Tuple{String,Int64} = ("",0)
end

@with_kw mutable struct ConvInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    group::String = ""
    type::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    filters::Int64 = 0
    filter_size::NTuple{2,Int64} = (0,0)
    stride::Int64 = 0
    dilation_factor::Int64 = 0
end

@with_kw mutable struct TConvInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    group::String = ""
    type::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    filters::Int64 = 0
    filter_size::NTuple{2,Int64} = (0,0)
    stride::Int64 = 0
    dilation_factor::Int64 = 0
end

@with_kw mutable struct DenseInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    group::String = ""
    type::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    filters::Int64 = 0
end

@with_kw mutable struct BatchNormInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    group::String = ""
    type::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    epsilon::Float64 = 0
end

@with_kw mutable struct DropoutInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    group::String = ""
    type::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    probability::Float64 = 0
end

@with_kw mutable struct LeakyReLUInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    group::String = ""
    type::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    scale::Float64 = 0
end

@with_kw mutable struct ELUInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    group::String = ""
    type::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    alpha::Float64 = 0
end

@with_kw mutable struct PoolInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    group::String = ""
    type::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    poolsize::NTuple{2,Int64} = (0,0)
    stride::Int64 = 0
end

@with_kw mutable struct AdditionInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    group::String = ""
    type::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    inputs::Int64 = 0
end

@with_kw mutable struct JoinInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    group::String = ""
    type::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    inputs::Int64 = 0
    dimension::Int64 = 0
end

@with_kw mutable struct SplitInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    group::String = ""
    type::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    outputs::Int64 = 0
    dimension::Int64 = 0
end

@with_kw mutable struct UpsampleInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    group::String = ""
    type::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    multiplier::Int64 = 0
    dimensions::Vector{Int64} = [0]
end

@with_kw mutable struct ModelData
    model::Chain = Chain()
    layers_info::Vector{AbstractLayerInfo} = []
    loss::Function = Flux.Losses.mse
    input_size::Tuple{Int64,Int64,Int64} = (1,1,1)
    output_size::Union{Tuple{Int64},Tuple{Int64,Int64,Int64}} = (1,1,1)
    classes::Vector{<:AbstractClass} = Vector{ImageClassificationClass}(undef,0)
    OutputOptions::Vector{<:AbstractOutputOptions} = Vector{ImageClassificationOutputOptions}(undef,0)
end
model_data = ModelData()

#---Master data
@with_kw mutable struct DesignData
    ModelData::ModelData = ModelData()
    output_options_backup::Vector{AbstractOutputOptions} = Vector{ImageClassificationOutputOptions}(undef,0)
    warnings::Vector{String} = Vector{String}(undef,0)
end
design_data = DesignData()

@with_kw mutable struct TrainingPlotData
    iteration::Int64 = 0
    epoch::Int64 = 0
    iterations_per_epoch::Int64 = 0
    starting_time::DateTime = now()
    max_iterations::Int64 = 0
    learning_rate_changed::Bool = false
end
training_plot_data = TrainingPlotData()

@with_kw mutable struct TrainingResultsData
    loss::Vector{Float32} = Vector{Float32}(undef,0)
    accuracy::Vector{Float32} = Vector{Float32}(undef,0)
    test_accuracy::Vector{Float32} = Vector{Float32}(undef,0)
    test_loss::Vector{Float32} = Vector{Float32}(undef,0)
    test_iteration::Vector{Int64} = Vector{Int64}(undef,0)
end
training_results_data = TrainingResultsData()

@with_kw mutable struct ClassificationData
    data_input::Vector{Array{Float32,3}} = Vector{Array{Float32,3}}(undef,0)
    data_labels::Vector{Int32} = Vector{Int32}(undef,0)
    input_urls::Vector{Vector{String}} = Vector{Vector{String}}(undef,0)
    label_urls::Vector{String} = Vector{String}(undef,0)
    filenames::Vector{Vector{String}} = Vector{Vector{String}}(undef,0)
end

@with_kw mutable struct RegressionData
    data_input::Vector{Array{Float32,3}} = Vector{Array{Float32,3}}(undef,0)
    data_labels::Vector{Vector{Float32}} = Vector{Vector{Float32}}(undef,0)
    input_urls::Vector{String} = Vector{String}(undef,0)
    labels_url::String = ""
end

@with_kw mutable struct SegmentationData
    data_input::Vector{Array{Float32,3}} = Vector{Array{Float32,3}}(undef,0)
    data_labels::Vector{BitArray{3}} = Vector{BitArray{3}}(undef,0)
    input_urls::Vector{String} = Vector{String}(undef,0)
    label_urls::Vector{String} = Vector{String}(undef,0)
    foldernames::Vector{String} = Vector{String}(undef,0)
end

@with_kw mutable struct TrainingData
    PlotData::TrainingPlotData = training_plot_data
    Results::TrainingResultsData = training_results_data
    ClassificationData::ClassificationData = ClassificationData()
    RegressionData::RegressionData = RegressionData()
    SegmentationData::SegmentationData = SegmentationData()
    tasks::Vector{Task} = Vector{Task}(undef,0)
end
training_data = TrainingData()

@with_kw mutable struct TestingData
    ClassificationData::ClassificationData = ClassificationData()
    RegressionData::RegressionData = RegressionData()
    SegmentationData::SegmentationData = SegmentationData()
end
testing_data = TestingData()

@with_kw mutable struct ValidationImageClassificationResults
    original::Vector{Array{RGB{N0f8},2}} = Vector{Array{RGB{N0f8},2}}(undef,0)
    predicted_labels::Vector{String} = Vector{String}(undef,0)
    target_labels::Vector{String} = Vector{String}(undef,0)
    other_data::Vector{Tuple{Float32,Float32}} = Vector{Tuple{Float32,Float32}}(undef,0)
end
validation_image_classification_results = ValidationImageClassificationResults()

@with_kw mutable struct ValidationImageRegressionResults
    original::Vector{Array{RGB{N0f8},2}} = Vector{Array{RGB{N0f8},2}}(undef,0)
    predicted_labels::Vector{Vector{Float32}}= Vector{Vector{Float32}}(undef,0)
    target_labels::Vector{Vector{Float32}} = Vector{Vector{Float32}}(undef,0)
    other_data::Vector{Tuple{Float32,Float32}} = Vector{Tuple{Float32,Float32}}(undef,0)
end
validation_image_regression_results = ValidationImageRegressionResults()

@with_kw mutable struct ValidationImageSegmentationResults
    original::Vector{Array{RGB{N0f8},2}} = Vector{Array{RGB{N0f8},2}}(undef,0)
    predicted_data::Vector{Vector{Tuple{BitArray{2},Vector{N0f8}}}} = 
        Vector{Vector{Tuple{BitArray{2},Vector{N0f8}}}}(undef,0)
    target_data::Vector{Vector{Tuple{BitArray{2},Vector{N0f8}}}} = 
        Vector{Vector{Tuple{BitArray{2},Vector{N0f8}}}}(undef,0)
    error_data::Vector{Vector{Tuple{BitArray{3},Vector{N0f8}}}} = 
        Vector{Vector{Tuple{BitArray{3},Vector{N0f8}}}}(undef,0)
    other_data::Vector{Tuple{Float32,Float32}} = 
        Vector{Tuple{Float32,Float32}}(undef,0)
end
validation_image_segmentation_results = ValidationImageSegmentationResults()

@with_kw mutable struct ValidationData
    ImageClassificationResults::ValidationImageClassificationResults = validation_image_classification_results
    ImageRegressionResults::ValidationImageRegressionResults = validation_image_regression_results
    ImageSegmentationResults::ValidationImageSegmentationResults = validation_image_segmentation_results
    original_image::Array{RGB{N0f8},2} = Array{RGB{N0f8},2}(undef,0,0)
    result_image::Array{RGB{N0f8},2} = Array{RGB{N0f8},2}(undef,0,0)
    input_urls::Vector{String} = Vector{String}(undef,0)
    label_urls::Vector{String} = Vector{String}(undef,0)
    labels_classification::Vector{Int32} = Vector{Int32}(undef,0)
    labels_regression::Vector{Vector{Float32}} = Vector{Float32}(undef,0)
    tasks::Vector{Task} = Vector{Task}(undef,0)
end
validation_data = ValidationData()

@with_kw mutable struct ApplicationData
    input_urls::Vector{Vector{String}} = Vector{Vector{String}}(undef,0)
    folders::Vector{String} = Vector{String}(undef,0)
    tasks::Vector{Task} = Vector{Task}(undef,0)
end
application_data = ApplicationData()

@with_kw mutable struct AllData
    DesignData::DesignData = design_data
    TrainingData::TrainingData = training_data
    TestingData::TestingData = testing_data
    ValidationData::ValidationData = validation_data
    ApplicationData::ApplicationData = application_data
    image::Array{RGB{Float32},2} = Array{RGB{Float32},2}(undef,0,0)
end
all_data = AllData()

#---Settings

# Options
@with_kw mutable struct HardwareResources
    allow_GPU::Bool = true
    num_cores::Int64 = Threads.nthreads()
end
hardware_resources = HardwareResources()
@with_kw mutable struct Options
    HardwareResources::HardwareResources = hardware_resources
end
options = Options()

# Design
@with_kw mutable struct Design
    width::Float64 = 340
    height::Float64 = 100
    min_dist_x::Float64 = 40
    min_dist_y::Float64 = 40
end
design = Design()

# Training
@with_kw mutable struct ProcessingTraining
    grayscale::Bool = false
    mirroring::Bool = true
    num_angles::Int64 = 2
    min_fr_pix::Float64 = 0.1
end
processing_training = ProcessingTraining()

@with_kw mutable struct HyperparametersTraining
    optimiser::Tuple{String,Int64} = ("ADAM",5)
    optimiser_params::Vector{Vector{Float64}} = [[],[0.9],[0.9],[0.9],
      [0.9,0.999],[0.9,0.999],[0.9,0.999],[],[0.9],[0.9,0.999],
      [0.9,0.999],[0.9,0.999,0]]
    optimiser_params_names::Vector{Vector{String}} = [[],["ρ"],
      ["ρ"],["ρ"],
      ["β1","β2"],
      ["β1","β2"],
      ["β1","β2"],[],
      ["ρ"],["β1","β2"],
      ["β1","β2"],
      ["β1","β2","Weight decay"]]
    allow_lr_change::Bool = true
    learning_rate::Float64 = 1e-3
    epochs::Int64 = 1
    batch_size::Int64 = 10
    savepath::String = "./"
end
hyperparameters_training = HyperparametersTraining()

@with_kw mutable struct GeneralTraining
    allow_GPU::Bool = true
    weight_accuracy::Bool = true
    manual_weight_accuracy::Bool = false
end
general_training = GeneralTraining()

@with_kw mutable struct TestingTraining
    test_data_fraction::Float64 = 0
    num_tests::Float64 = 5
    manual_testing_data::Bool = false
end
testing_training = TestingTraining()

@with_kw mutable struct TrainingOptions
    General::GeneralTraining = general_training
    Testing::TestingTraining = testing_training
    Processing::ProcessingTraining = processing_training
    Hyperparameters::HyperparametersTraining = hyperparameters_training
end
training_options = TrainingOptions()

@with_kw mutable struct Training
    Options::TrainingOptions = training_options
    model_url::String = ""
    input_url::String = ""
    label_url::String = ""
    name::String = "new"
end
training = Training()

@with_kw mutable struct Testing
    input_url::String = ""
    label_url::String = ""
end
testing = Testing()

# Validation
@with_kw mutable struct Validation
    input_url::String = ""
    label_url::String = ""
    use_labels::Bool = false
end
validation = Validation()

# Application
@with_kw mutable struct ApplicationOptions
    savepath::String = ""
    apply_by::Tuple{String,Int64} = ("file",0)
    data_type::Int64 = 0
    image_type::Int64 = 0
    downsize::Int64 = 0
    skip_frames::Int64 = 0
    scaling::Float64 = 1
    minibatch_size::Int64 = 1
end
application_options = ApplicationOptions()

@with_kw mutable struct Application
    Options::ApplicationOptions = application_options
    model_url::String = ""
    input_url::String = ""
    checked_folders::Vector{String} = String[]
end
application = Application()

# Visualisation
@with_kw mutable struct Visualisation
    a::Bool = false
end
visualisation = Visualisation()

# Settings
@with_kw mutable struct Settings
    problem_type::Symbol = :Classification
    input_type::Symbol = :Image
    Options::Options = options
    Design::Design = design
    Training::Training = training
    Testing::Testing = testing
    Validation::Validation = validation
    Application::Application = application
    Visualisation::Visualisation = visualisation
end
settings = Settings()

#---Other

mutable struct Counter
    iteration::Int
    Counter() = new(0)
end
(c::Counter)() = (c.iteration += 1)