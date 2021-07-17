
module Training

using Parameters, Dates


#---Data----------------------------------------------------------------

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


#---Options----------------------------------------------------------------

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


#---Export all--------------------------------------------------------------
for n in names(@__MODULE__; all=true)
    if Base.isidentifier(n) && n ∉ (Symbol(@__MODULE__), :eval, :include)
        @eval export $n
    end
end

end