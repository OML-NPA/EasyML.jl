#---Bindings------------------------------------------------------------------

abstract type AbstractEasyMLStruct end

function Base.getproperty(obj::AbstractEasyMLStruct, sym::Symbol)
    value = getfield(obj, sym)
    if value isa RefValue
        return value[]
    else
        return value
    end
end

function Base.setproperty!(obj::AbstractEasyMLStruct, sym::Symbol, x)
    value = getfield(obj,sym)
    if value isa RefValue
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
    validation_start::Channel{Int64} = Channel{Int64}(1)
    validation_progress::Channel{NTuple{2,Float32}} = Channel{NTuple{2,Float32}}(Inf)
    validation_modifiers::Channel{Tuple{Int64,Float64}} = Channel{Tuple{Int64,Float64}}(Inf) # 0 - abort
end
channels = Channels()


#---Model data-----------------------------------------------------------------

@with_kw mutable struct ModelData<:AbstractEasyMLStruct
    model::RefValue{<:Chain} = Ref{Chain}(Chain())
    loss::RefValue{<:Function} = Ref{Function}(Flux.Losses.mse)
    problem_type::RefValue{Symbol} = Ref(:Classification)
    input_type::RefValue{Symbol} = Ref(:Image)
    input_properties::RefValue{Vector{Symbol}} = Ref(Vector{Symbol}(undef,0))
    input_size::RefValue{NTuple{3,Int64}} = Ref((0,0,0))
    output_size::RefValue{NTuple{3,Int64}} = Ref((0,0,0))
    classes::RefValue{Vector{<:AbstractClass}} = 
        RefValue{Vector{<:AbstractClass}}(Vector{ImageClassificationClass}(undef,0))
end
model_data = ModelData()


#---All data--------------------------------------------------------------------

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

@with_kw mutable struct AllData<:AbstractEasyMLStruct
    ValidationData::ValidationData = validation_data
    model_url::RefValue{String} = Ref("")
    model_name::RefValue{String} = Ref("")
end
all_data = AllData()


#---Options------------------------------------------------------------------

@with_kw struct HardwareResources<:AbstractEasyMLStruct
    allow_GPU::RefValue{Bool} = Ref(true)
    num_threads::RefValue{Int64} = Ref(Threads.nthreads())
    num_slices::RefValue{Int64} = Ref{Int64}(1)
    offset::RefValue{Int64} = Ref{Int64}(20)
end
hardware_resources = HardwareResources()

@with_kw struct Graphics<:AbstractEasyMLStruct
    scaling_factor::RefValue{Float64} = Ref(1.0)
end
graphics = Graphics()

@with_kw struct GlobalOptions
    Graphics::Graphics = graphics
    HardwareResources::HardwareResources = hardware_resources
end
global_options = GlobalOptions()

@with_kw mutable struct ValidationAccuracyOptions
    weight_accuracy::Bool = true
    accuracy_mode::Symbol = :Auto
end
validation_accuracy_options = ValidationAccuracyOptions()

@with_kw struct ValidationOptions
    Accuracy::ValidationAccuracyOptions = validation_accuracy_options
end
validation_options = ValidationOptions()

@with_kw struct Options
    GlobalOptions::GlobalOptions = global_options
    ValidationOptions::ValidationOptions = validation_options
end
options = Options()


#---Testing----------------------------------------------------------------

@with_kw struct UnitTest<:AbstractEasyMLStruct
    state::RefValue{Bool} = Ref(false)
    urls::RefValue{Vector{String}} = Ref(String[])
    url_pusher = () -> popfirst!(unit_test.urls)
end
unit_test = UnitTest()
(m::UnitTest)() = m.state
