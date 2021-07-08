
#---Channels

@with_kw struct Channels
    data_preparation_progress::Channel = Channel{Int64}(Inf)
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
    parents::Vector{String} = ["",""]
    not_class::Bool = false
end

abstract type AbstractOutputOptions end

@with_kw mutable struct ImageClassificationOutputOptions<:AbstractOutputOptions
    temp::Bool = false
end

@with_kw mutable struct ImageRegressionOutputOptions<:AbstractOutputOptions
    temp::Bool = false
end

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

@with_kw mutable struct ImageSegmentationOutputOptions<:AbstractOutputOptions
    Mask::OutputMask = OutputMask()
    Area::OutputArea = OutputArea()
    Volume::OutputVolume = OutputVolume()
end

@with_kw mutable struct ModelData
    input_size::NTuple{3,Int64} = (0,0,0)
    output_size::Union{Tuple{Int64},NTuple{3,Int64}} = (0,0,0)
    classes::Vector{<:AbstractClass} = Vector{ImageClassificationClass}(undef,0)
    problem_type::Symbol = :Classification
    input_type::Symbol = :Image
end
model_data = ModelData()

#---All data

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
    model_url::String = ""
    model_name::String = ""
end
all_data = AllData()


#---Options

@with_kw mutable struct HardwareResources
    allow_GPU::Bool = true
    num_threads::Int64 = Threads.nthreads()
    num_slices::Int64 = 1
    offset::Int64 = 20
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

@with_kw mutable struct ImagePreparationOptions
    grayscale::Bool = false
    mirroring::Bool = false
    num_angles::Int64 = 1
    min_fr_pix::Float64 = 0.0
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

# Needed for testing
@with_kw mutable struct UnitTest
    state::Bool = false
end
unit_test = UnitTest()
(m::UnitTest)() = m.state
