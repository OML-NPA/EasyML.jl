
#---Misc-----------------------------------------------------------

abstract type AbstractEasyML end


abstract type AbstractProblemType end
struct Classification <: AbstractProblemType end
struct Regression <: AbstractProblemType end
struct Segmentation <: AbstractProblemType end


abstract type AbstractInputType end
struct Image <: AbstractInputType end


abstract type AbstractInputProperty end
struct Grayscale <: AbstractInputProperty end


#---Classes-----------------------------------------------------------

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


#---Final----------------------------------------------------------------

@with_kw mutable struct ModelData<:AbstractEasyML
    model = Ref{Chain}(Flux.Chain())
    loss = Ref{Function}(Flux.Losses.mse)
    input_size = Ref((0,0,0))
    output_size = Ref((0,0,0))
    problem_type = Ref{Type{<:AbstractProblemType}}(Classification)
    input_type = Ref{Type{<:AbstractInputType}}(Image)
    input_properties = Ref{Vector{Type{<:AbstractInputProperty}}}(Type{AbstractInputProperty}[])
    classes = Ref{Vector{<:AbstractClass}}(Vector{ImageClassificationClass}(undef,0))
end
model_data = ModelData()


#---Testing--------------------------------------------------------------

@with_kw mutable struct UnitTest<:AbstractEasyML
    state::RefValue{Bool} = Ref(false)
    urls::RefValue{Vector{String}} = Ref(String[])
    url_pusher = () -> popfirst!(urls[])
end
unit_test = UnitTest()
(m::UnitTest)() = m.state