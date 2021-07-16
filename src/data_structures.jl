
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
    model::AbstractModel = Flux.Chain()
    normalization::Normalization = Normalization()
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


#---Data-------------------------------------------------------------------

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