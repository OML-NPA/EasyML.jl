
module Training

using Parameters, Dates

import ..DataPreparation: ClassificationData, RegressionData, SegmentationData


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
    accuracy_mode::Symbol = :auto
end
accuracy_options = AccuracyOptions()

@with_kw mutable struct TestingOptions
    data_preparation_mode::Symbol = :auto
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