
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
    BorderClass::BorderClass = BorderClass()
end

@with_kw mutable struct ModelData
    problem_type::Symbol = :Classification
    input_type::Symbol = :Image
    classes::Vector{<:AbstractClass} = Vector{ImageClassificationClass}(undef,0)
end
model_data = ModelData()


#---All data------------------------------------------------------------------

@with_kw mutable struct AllData
    model_url::String = ""
    model_name::String = ""
end
all_data = AllData()


#---Options-------------------------------------------------------------------

@with_kw mutable struct Graphics
    scaling_factor::Float64 = 1
end
graphics = Graphics()

@with_kw mutable struct GlobalOptions
    Graphics::Graphics = graphics
end
global_options = GlobalOptions()
# Options
@with_kw mutable struct Options
    GlobalOptions::GlobalOptions = global_options
end
options = Options()


#---Testing-------------------------------------------------------------------

@with_kw mutable struct UnitTest
    state::Bool = false
    url_pusher = []
    urls::Vector{String} = String[]
end
unit_test = UnitTest()
(m::UnitTest)() = m.state
