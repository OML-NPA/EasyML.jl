
#---Types-----------------------------------------------------------

abstract type AbstractProblemType end
struct Classification <: AbstractProblemType end
struct Regression <: AbstractProblemType end
struct Segmentation <: AbstractProblemType end


abstract type AbstractInputType end
struct Image <: AbstractInputType end


abstract type AbstractInputProperty end
struct Grayscale <: AbstractInputProperty end


#---Channels------------------------------------------------------------------

@with_kw struct Channels
    data_preparation_progress::Channel = Channel{Int64}(Inf)
    training_start_progress::Channel = Channel{NTuple{3,Int64}}(1)
    training_progress::Channel = Channel{Tuple{String,Float32,Float32,Int64}}(Inf)
    training_modifiers::Channel = Channel{Tuple{Int64,Float64}}(Inf) # 0 - abort; 1 - learning rate; 2 - epochs; 3 - number of tests
    validation_start::Channel{Int64} = Channel{Int64}(1)
    validation_progress::Channel{NTuple{2,Float32}} = Channel{NTuple{2,Float32}}(Inf)
    validation_modifiers::Channel{Tuple{Int64,Float64}} = Channel{Tuple{Int64,Float64}}(Inf) # 0 - abort
    application_progress::Channel = Channel{Int64}(Inf)
end
channels = Channels()


#---Model data----------------------------------------------------------------

@with_kw mutable struct ModelData
    model::Chain = Flux.Chain()
    loss::Function = Flux.Losses.mse
    input_size::NTuple{3,Int64} = (0,0,0)
    output_size::NTuple{3,Int64} = (0,0,0)
    problem_type::Type{<:AbstractProblemType} = Classification
    input_type::Type{<:AbstractInputType} = Image
    input_properties::Vector{Type{<:AbstractInputProperty}} = Vector{Type{AbstractInputProperty}}(undef,0)
    classes::Vector{<:AbstractClass} = Vector{ImageClassificationClass}(undef,0)
    layers_info::Vector{AbstractLayerInfo} =  Vector{AbstractLayerInfo}(undef,0)
end
model_data = ModelData()


#---Design data----------------------------------------------------------------

@with_kw mutable struct DesignData
    ModelData::ModelData = ModelData()
    warnings::Vector{String} = Vector{String}(undef,0)
end
design_data = DesignData()


#---Preparation data-----------------------------------------------------------

@with_kw mutable struct ClassificationUrlsData
    input_urls::Vector{Vector{String}} = Vector{Vector{String}}(undef,0)
    label_urls::Vector{String} = Vector{String}(undef,0)
    filenames::Vector{Vector{String}} = Vector{Vector{String}}(undef,0)
end

@with_kw mutable struct ClassificationResultsData
    data_input::Vector{Array{Float32,3}} = Vector{Array{Float32,3}}(undef,0)
    data_labels::Vector{Int32} = Vector{Int32}(undef,0)
end

@with_kw struct ClassificationData
    Urls::ClassificationUrlsData = ClassificationUrlsData()
    Results::ClassificationResultsData = ClassificationResultsData()
end

@with_kw mutable struct RegressionUrlsData
    initial_data_labels::Vector{Vector{Float32}} = Vector{Vector{Float32}}(undef,0)
    input_urls::Vector{String} = Vector{String}(undef,0)
    labels_url::String = ""
end

@with_kw mutable struct RegressionResultsData
    data_input::Vector{Array{Float32,3}} = Vector{Array{Float32,3}}(undef,0)
    data_labels::Vector{Vector{Float32}} = Vector{Vector{Float32}}(undef,0)
end

@with_kw struct RegressionData
    Urls::RegressionUrlsData = RegressionUrlsData()
    Results::RegressionResultsData = RegressionResultsData()
end

@with_kw mutable struct SegmentationUrlsData
    input_urls::Vector{String} = Vector{String}(undef,0)
    label_urls::Vector{String} = Vector{String}(undef,0)
    foldernames::Vector{String} = Vector{String}(undef,0)
end

@with_kw mutable struct SegmentationResultsData
    data_input::Vector{Array{Float32,3}} = Vector{Array{Float32,3}}(undef,0)
    data_labels::Vector{BitArray{3}} = Vector{BitArray{3}}(undef,0)
end

@with_kw struct SegmentationData
    Urls::SegmentationUrlsData = SegmentationUrlsData()
    Results::SegmentationResultsData = SegmentationResultsData()
end

@with_kw mutable struct PreparationUrls
    url_inputs::String = ""
    url_labels::String = ""
end
preparation_urls = PreparationUrls()

@with_kw mutable struct PreparationData
    ClassificationData::ClassificationData = ClassificationData()
    RegressionData::RegressionData = RegressionData()
    SegmentationData::SegmentationData = SegmentationData()
    Urls::PreparationUrls = preparation_urls
    tasks::Vector{Task} = Vector{Task}(undef,0)
end
preparation_data = PreparationData()


#---Training data--------------------------------------------------------------


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
    accuracy::Vector{Float32} = Vector{Float32}(undef,0)
    loss::Vector{Float32} = Vector{Float32}(undef,0)
    test_accuracy::Vector{Float32} = Vector{Float32}(undef,0)
    test_loss::Vector{Float32} = Vector{Float32}(undef,0)
    test_iteration::Vector{Int64} = Vector{Int64}(undef,0)
end
training_results_data = TrainingResultsData()

@with_kw mutable struct TrainingOptionsData
    optimiser_params::Vector{Vector{Float64}} = [[],[0.9],[0.9],[0.9],[0.9,0.999],
        [0.9,0.999],[0.9,0.999],[],[0.9],[0.9,0.999],[0.9,0.999],[0.9,0.999,0]]
    optimiser_params_names::Vector{Vector{String}} = [[],["ρ"],["ρ"],["ρ"],["β1","β2"],
        ["β1","β2"],["β1","β2"],[],["ρ"],["β1","β2"],["β1","β2"],["β1","β2","Weight decay"]]
    allow_lr_change::Bool = true
    run_test::Bool = false
end
training_options_data = TrainingOptionsData()


@with_kw mutable struct TrainingData
    PlotData::TrainingPlotData = training_plot_data
    Results::TrainingResultsData = training_results_data
    ClassificationData::ClassificationData = ClassificationData()
    RegressionData::RegressionData = RegressionData()
    SegmentationData::SegmentationData = SegmentationData()
    OptionsData::TrainingOptionsData = training_options_data
    weights::Vector{Float32} = Vector{Float32}(undef,0)
    tasks::Vector{Task} = Vector{Task}(undef,0)
    warnings::Vector{String} = Vector{String}(undef,0)
    errors::Vector{String} = Vector{String}(undef,0)
end
training_data = TrainingData()

@with_kw mutable struct TestingData
    ClassificationData::ClassificationData = ClassificationData()
    RegressionData::RegressionData = RegressionData()
    SegmentationData::SegmentationData = SegmentationData()
end
testing_data = TestingData()


#---Validation data------------------------------------------------------------

@with_kw mutable struct ValidationImageClassificationResults
    original_images::Vector{Array{RGB{N0f8},2}} = Vector{Array{RGB{N0f8},2}}(undef,0)
    predicted_labels::Vector{String} = Vector{String}(undef,0)
    target_labels::Vector{String} = Vector{String}(undef,0)
    accuracy::Vector{Float32} = Vector{Float32}(undef,0)
    loss::Vector{Float32} = Vector{Float32}(undef,0)
end
validation_image_classification_results = ValidationImageClassificationResults()

@with_kw mutable struct ValidationImageRegressionResults
    original_images::Vector{Array{RGB{N0f8},2}} = Vector{Array{RGB{N0f8},2}}(undef,0)
    predicted_labels::Vector{Vector{Float32}}= Vector{Vector{Float32}}(undef,0)
    target_labels::Vector{Vector{Float32}} = Vector{Vector{Float32}}(undef,0)
    accuracy::Vector{Float32} = Vector{Float32}(undef,0)
    loss::Vector{Float32} = Vector{Float32}(undef,0)
end
validation_image_regression_results = ValidationImageRegressionResults()

@with_kw mutable struct ValidationImageSegmentationResults
    original_images::Vector{Array{RGB{N0f8},2}} = Vector{Array{RGB{N0f8},2}}(undef,0)
    predicted_data::Vector{Vector{Tuple{BitArray{2},Vector{N0f8}}}} = 
        Vector{Vector{Tuple{BitArray{2},Vector{N0f8}}}}(undef,0)
    target_data::Vector{Vector{Tuple{BitArray{2},Vector{N0f8}}}} = 
        Vector{Vector{Tuple{BitArray{2},Vector{N0f8}}}}(undef,0)
    error_data::Vector{Vector{Tuple{BitArray{3},Vector{N0f8}}}} = 
        Vector{Vector{Tuple{BitArray{3},Vector{N0f8}}}}(undef,0)
    accuracy::Vector{Float32} = Vector{Float32}(undef,0)
    loss::Vector{Float32} = Vector{Float32}(undef,0)
end
validation_image_segmentation_results = ValidationImageSegmentationResults()

@with_kw mutable struct ValidationUrls
    input_urls::Vector{String} = Vector{String}(undef,0)
    label_urls::Vector{String} = Vector{String}(undef,0)
    labels_classification::Vector{Int32} = Vector{Int32}(undef,0)
    labels_regression::Vector{Vector{Float32}} = Vector{Float32}(undef,0)
    url_inputs::String = ""
    url_labels::String = ""
end
validation_urls = ValidationUrls()

@with_kw mutable struct ValidationPlotData
    original_image::Array{RGB{N0f8},2} = Array{RGB{N0f8},2}(undef,0,0)
    label_image::Array{RGB{N0f8},2} = Array{RGB{N0f8},2}(undef,0,0)
    use_labels::Bool = false
end
validation_plot_data = ValidationPlotData()

@with_kw struct ValidationData
    PlotData::ValidationPlotData = validation_plot_data
    ImageClassificationResults::ValidationImageClassificationResults = validation_image_classification_results
    ImageRegressionResults::ValidationImageRegressionResults = validation_image_regression_results
    ImageSegmentationResults::ValidationImageSegmentationResults = validation_image_segmentation_results
    Urls::ValidationUrls = validation_urls
    tasks::Vector{Task} = Vector{Task}(undef,0)
end
validation_data = ValidationData()


#---Application data-----------------------------------------------------------

@with_kw mutable struct ApplicationData
    input_urls::Vector{Vector{String}} = Vector{Vector{String}}(undef,0)
    folders::Vector{String} = Vector{String}(undef,0)
    url_inputs::String = ""
    tasks::Vector{Task} = Vector{Task}(undef,0)
end
application_data = ApplicationData()


#---All data-------------------------------------------------------------------

@with_kw mutable struct AllDataUrls
    model_url::String = ""
    model_name::String = ""
end
all_data_urls = AllDataUrls()

@with_kw mutable struct AllData
    DesignData::DesignData = design_data
    PreparationData::PreparationData = preparation_data
    TrainingData::TrainingData = training_data
    TestingData::TestingData = testing_data
    ValidationData::ValidationData = validation_data
    ApplicationData::ApplicationData = application_data
    Urls::AllDataUrls = all_data_urls
end
all_data = AllData()


#---Options-----------------------------------------------------------------

# Global options
@with_kw mutable struct Graphics
    scaling_factor::Float64 = 1.0
end
graphics = Graphics()

@with_kw mutable struct HardwareResources
    allow_GPU::Bool = true
    num_threads::Int64 = Threads.nthreads()
    num_slices::Int64 = 1
    offset::Int64 = 20
end
hardware_resources = HardwareResources()

@with_kw struct GlobalOptions
    Graphics::Graphics = graphics
    HardwareResources::HardwareResources = hardware_resources
end
global_options = GlobalOptions()


# Design options
@with_kw mutable struct DesignOptions
    width::Float64 = 340
    height::Float64 = 100
    min_dist_x::Float64 = 80
    min_dist_y::Float64 = 40
end
design_options = DesignOptions()


# Data preparation options
@with_kw mutable struct BackgroundCroppingOptions
    enabled::Bool = false
    threshold::Float64 = 0.3
    closing_value::Int64 = 1
end
background_cropping_options = BackgroundCroppingOptions()

@with_kw mutable struct ImagePreparationOptions
    grayscale::Bool = false
    mirroring::Bool = false
    num_angles::Int64 = 1
    min_fr_pix::Float64 = 0.0
    BackgroundCropping::BackgroundCroppingOptions = background_cropping_options
end
image_preparation_options = ImagePreparationOptions()

@with_kw struct DataPreparationOptions
    Images::ImagePreparationOptions = image_preparation_options
end
data_preparation_options = DataPreparationOptions()


# Training options
@with_kw mutable struct AccuracyOptions
    weight_accuracy::Bool = true
    accuracy_mode::Symbol = :Auto
end
accuracy_options = AccuracyOptions()

@with_kw mutable struct TestingOptions
    data_preparation_mode::Symbol = :Auto
    test_data_fraction::Float64 = 0.1
    num_tests::Float64 = 2
end
testing_options = TestingOptions()

@with_kw mutable struct HyperparametersOptions
    optimiser::Symbol = :ADAM
    optimiser_params::Vector{Float64} = [0.9,0.999]
    learning_rate::Float64 = 1e-3
    epochs::Int64 = 1
    batch_size::Int64 = 10
end
hyperparameters_options = HyperparametersOptions()

@with_kw mutable struct TrainingOptions
    Accuracy::AccuracyOptions = accuracy_options
    Testing::TestingOptions = testing_options
    Hyperparameters::HyperparametersOptions = hyperparameters_options
end
training_options = TrainingOptions()


# Validation options


# Application options
@with_kw mutable struct ApplicationOptions
    savepath::String = ""
    apply_by::Symbol = :file
    data_type::Symbol = :CSV
    image_type::Symbol = :PNG
    scaling::Float64 = 1
end
application_options = ApplicationOptions()


# All options
@with_kw struct Options
    GlobalOptions::GlobalOptions = global_options
    DesignOptions::DesignOptions = design_options
    DataPreparationOptions::DataPreparationOptions = data_preparation_options
    TrainingOptions::TrainingOptions = training_options
    ApplicationOptions::ApplicationOptions = application_options
end
options = Options()



#---Testing--------------------------------------------------------------------

@with_kw mutable struct UnitTest
    state = false
    urls = String[]
    url_pusher = () -> popfirst!(urls)
end
unit_test = UnitTest()
(m::UnitTest)() = m.state