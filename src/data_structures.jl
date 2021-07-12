
#---Model data----------------------------------------------------------------------

abstract type AbstractClass end

@with_kw mutable struct ImageClassificationClass<:AbstractClass
    name::String = ""
    weight::Float32 = 1
end

@with_kw mutable struct ImageRegressionClass<:AbstractClass
    name::String = ""
end

@with_kw mutable struct BorderClass
    enabled::Bool = false
    thickness::Int64 = 3
end

@with_kw mutable struct ImageSegmentationClass<:AbstractClass
    name::String = ""
    weight::Float32 = 1
    color::Vector{Float64} = Vector{Float64}(undef,3)
    parents::Vector{String} = ["",""]
    overlap::Bool = false
    min_area::Int64 = 0
    BorderClass::BorderClass = BorderClass()
end

@with_kw mutable struct ModelData<:AbstractEasyML
    problem_type::RefValue{Type{<:AbstractProblemType}} = Ref{Type{<:AbstractProblemType}}(Classification)
    input_type::RefValue{Type{<:AbstractInputType}} = Ref{Type{<:AbstractInputType}}(Image)
    classes::RefValue{Vector{<:AbstractClass}} = Ref{Vector{<:AbstractClass}}(Vector{ImageClassificationClass}(undef,0))
end
model_data = ModelData()


#---All data------------------------------------------------------------------

@with_kw mutable struct AllDataUrls<:AbstractEasyML
    model_url::RefValue{String} = Ref("")
    model_name::RefValue{String} = Ref("")
end
all_data_urls = AllDataUrls()

@with_kw struct AllData<:AbstractEasyML
    Urls::AllDataUrls = all_data_urls
end
all_data = AllData()


#---Options-------------------------------------------------------------------

@with_kw mutable struct Graphics<:AbstractEasyML
    scaling_factor::RefValue{Float64} = Ref(1.0)
end
graphics = Graphics()

@with_kw struct GlobalOptions
    Graphics::Graphics = graphics
end
global_options = GlobalOptions()

@with_kw struct Options
    GlobalOptions::GlobalOptions = global_options
end
options = Options()


#---Testing-------------------------------------------------------------------

@with_kw mutable struct UnitTest<:AbstractEasyML
    state::RefValue{Bool} = Ref(false)
    urls::RefValue{Vector{String}} = Ref(String[])
    url_pusher = () -> popfirst!(unit_test.urls)
end
unit_test = UnitTest()
(m::UnitTest)() = m.state

