
#---Channels------------------------------------------------------------------

@with_kw struct Channels
    data_preparation_progress::Channel = Channel{Int64}(Inf)
end
channels = Channels()


#---Model data-----------------------------------------------------------------

@with_kw mutable struct ModelData<:AbstractEasyML
    problem_type = EasyMLCore.model_data.problem_type
    input_type = EasyMLCore.model_data.input_type
    input_properties = EasyMLCore.model_data.input_properties
    input_size = EasyMLCore.model_data.input_size
    output_size = EasyMLCore.model_data.output_size
    classes = EasyMLCore.model_data.classes
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

@with_kw mutable struct AllDataUrls<:AbstractEasyML
    model_url::RefValue{String} = Ref("")
    model_name::RefValue{String} = Ref("")
end
all_data_urls = AllDataUrls()

@with_kw struct AllData
    PreparationData::PreparationData = preparation_data
    Urls::AllDataUrls = all_data_urls
end
all_data = AllData()


#---Options------------------------------------------------------------

@with_kw mutable struct HardwareResources<:AbstractEasyML
    allow_GPU::RefValue{Bool} = Ref(true)
    num_threads::RefValue{Int64} = Ref(Threads.nthreads())
    num_slices::RefValue{Int64} = Ref(1)
    offset::RefValue{Int64} = Ref(20)
end
hardware_resources = HardwareResources()

@with_kw mutable struct Graphics<:AbstractEasyML
    scaling_factor::RefValue{Float64} = Ref(1.0)
end
graphics = Graphics()

@with_kw struct GlobalOptions
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

@with_kw struct DataPreparationOptions
    Images::ImagePreparationOptions = image_preparation_options
end
data_preparation_options = DataPreparationOptions()

@with_kw struct Options
    DataPreparationOptions::DataPreparationOptions = data_preparation_options
    GlobalOptions::GlobalOptions = global_options
end
options = Options()


#---Testing----------------------------------------------------------------
@with_kw mutable struct UnitTest<:AbstractEasyML
    state::RefValue{Bool} = Ref(false)
    urls::RefValue{Vector{String}} = Ref(String[])
    url_pusher = () -> popfirst!(urls[])
end
unit_test = UnitTest()
(m::UnitTest)() = m.state