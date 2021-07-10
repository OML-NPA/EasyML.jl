
#---Bindings------------------------------------------------------------------

abstract type AbstractEasyML end

function Base.getproperty(obj::AbstractEasyML, sym::Symbol)
    value = getfield(obj, sym)
    if value isa Ref
        return value[]
    else
        return value
    end
end

function Base.setproperty!(obj::AbstractEasyML, sym::Symbol, x)
    value = getfield(obj,sym)
    if value isa Ref
        value[] = x
    else
        setfield!(obj,sym,x)
    end
    return nothing
end

function bind!(obj1,obj2)
    fields1 = fieldnames(typeof(obj1))
    fields2 = fieldnames(typeof(obj2))
    for field in fields1
        if field in fields2 && getfield(obj1,field) isa Ref
            setfield!(obj1,field,getfield(obj2,field))
        end
    end
end


#---Channels------------------------------------------------------------------

@with_kw struct Channels
    data_preparation_progress::Channel = Channel{Int64}(Inf)
end
channels = Channels()


#---Model data-----------------------------------------------------------------

@with_kw mutable struct ModelData<:AbstractEasyML
    problem_type::Ref{Symbol} = Ref(:Classification)
    input_type::Ref{Symbol} = Ref(:Image)
    input_properties::Ref{Vector{Symbol}} = Ref(Vector{Symbol}(undef,0))
    input_size::Ref{NTuple{3,Int64}} = Ref((0,0,0))
    output_size::Ref{NTuple{3,Int64}} = Ref((0,0,0))
    classes::Ref{Vector{<:EasyMLClasses.AbstractClass}} = Ref{Vector{<:EasyMLClasses.AbstractClass}}(Vector{EasyMLClasses.ImageClassificationClass}(undef,0))
end
model_data = ModelData()


#---All data------------------------------------------------------------------

@with_kw mutable struct ClassificationUrlsData
    input_urls::Vector{Vector{String}} = Vector{Vector{String}}(undef,0)
    label_urls::Vector{String} = Vector{String}(undef,0)
    filenames::Vector{Vector{String}} = Vector{Vector{String}}(undef,0)
end

@with_kw mutable struct ClassificationResultsData
    data_input::Vector{Array{Float32,3}} = Vector{Array{Float32,3}}(undef,0)
    data_labels::Vector{Int32} = Vector{Int32}(undef,0)
end

@with_kw mutable struct ClassificationData
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

@with_kw mutable struct RegressionData
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

@with_kw mutable struct SegmentationData
    Urls::SegmentationUrlsData = SegmentationUrlsData()
    Results::SegmentationResultsData = SegmentationResultsData()
end

@with_kw mutable struct PreparedData
    ClassificationData::ClassificationData = ClassificationData()
    RegressionData::RegressionData = RegressionData()
    SegmentationData::SegmentationData = SegmentationData()
    url_inputs::String = ""
    url_labels::String = ""
    tasks::Vector{Task} = Vector{Task}(undef,0)
end
prepared_data = PreparedData()

@with_kw mutable struct AllData
    PreparedData::PreparedData = prepared_data
    model_url::Ref{String} = Ref("")
    model_name::Ref{String} = Ref("")
end
all_data = AllData()


#---Options------------------------------------------------------------

@with_kw mutable struct HardwareResources
    allow_GPU::Bool = true
    num_threads::Int64 = Threads.nthreads()
    num_slices::Int64 = 1
    offset::Int64 = 20
end
hardware_resources = HardwareResources()

@with_kw mutable struct Graphics<:AbstractEasyML
    scaling_factor::Ref{Float64} = Ref(1.0)
end
graphics = Graphics()

@with_kw mutable struct GlobalOptions
    Graphics::Graphics = graphics
    HardwareResources::HardwareResources = hardware_resources
end
global_options = GlobalOptions()

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

@with_kw mutable struct DataPreparationOptions
    Images::ImagePreparationOptions = image_preparation_options
end
data_preparation_options = DataPreparationOptions()

# Options
@with_kw mutable struct Options
    DataPreparationOptions::DataPreparationOptions = data_preparation_options
    GlobalOptions::GlobalOptions = global_options
end
options = Options()


#---Testing----------------------------------------------------------------
@with_kw mutable struct UnitTest<:AbstractEasyML
    state::Ref{Bool} = Ref(false)
    urls::Ref{Vector{String}} = Ref(String[])
    url_pusher = () -> popfirst!(unit_test.urls)
end
unit_test = UnitTest()
(m::UnitTest)() = m.state