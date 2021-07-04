
#---Channels

@with_kw struct Channels
    training_start_progress::Channel = Channel{NTuple{3,Int64}}(1)
    training_progress::Channel = Channel{Tuple{String,Float32,Float32,Int64}}(Inf)
    training_modifiers::Channel = Channel{Tuple{Int64,Float64}}(Inf) # 0 - abort; 1 - learning rate; 2 - epochs; 3 - number of tests
end
channels = Channels()

#---Model data

#--Required for compatibility

@with_kw mutable struct ModelData
    model::Chain = Chain()
    input_size::Union{Tuple{Int64},NTuple{3,Int64}} = (0,0,0)
    output_size::Union{Tuple{Int64},NTuple{3,Int64}} = (0,0,0)
    loss::Function = Flux.Losses.mse
end
model_data = ModelData()

#---All data

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

@with_kw mutable struct ClassificationData
    data_input::Union{Vector{T1},Vector{T2}} where {T1<:Vector{Float32},T2<:Array{Float32,3}} = 
        Vector{Array{Float32,3}}(undef,0)
    data_labels::Vector{Int32} = Vector{Int32}(undef,0)
    max_labels::Int32 = 0
end
classification_data = ClassificationData()

@with_kw mutable struct RegressionData{T1<:Vector{Float32},T2<:Array{Float32,3}}
    data_input::Union{Vector{T1},Vector{T2}} = Vector{Array{Float32,3}}(undef,0)
    data_labels::Union{Vector{T1},Vector{T2}} = Vector{Vector{Float32}}(undef,0)
end
regression_data = RegressionData()

@with_kw mutable struct SegmentationData
    data_input::Union{Vector{T1a},Vector{T2a}} where {T1a<:Vector{Float32},T2a<:Array{Float32,3}} = 
        Vector{Array{Float32,3}}(undef,0)
    data_labels::Union{Vector{T1b},Vector{T2b}} where {T1b<:BitArray{1},T2b<:BitArray{3}} = 
        Vector{BitArray{3}}(undef,0)
end
segmentaion_data = SegmentationData()

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

@with_kw mutable struct AllData
    TrainingData::TrainingData = training_data
    TestingData::TestingData = testing_data
    problem_type::Symbol = :Classification
    data_type::Symbol = :Image
    model_url::String = ""
    model_name::String = ""
end
all_data = AllData()

#---Options

@with_kw mutable struct HardwareResources
    allow_GPU::Bool = true
    num_threads::Int64 = Threads.nthreads()
end
hardware_resources = HardwareResources()

@with_kw mutable struct Graphics
    scaling_factor::Float64 = 1
end
graphics = Graphics()

@with_kw mutable struct GlobalOptions
    Graphics::Graphics = graphics
    HardwareResources::HardwareResources = hardware_resources
end
global_options = GlobalOptions()

# Training
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

@with_kw mutable struct Options
    GlobalOptions::GlobalOptions = global_options
    TrainingOptions::TrainingOptions = training_options
end
options = Options()

#---Other

mutable struct Counter
    iteration::Int
    Counter() = new(0)
end
(c::Counter)() = (c.iteration += 1)

num_threads() = hardware_resources.num_threads