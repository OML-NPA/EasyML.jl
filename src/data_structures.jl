
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
    model::RefValue{<:Chain} = Ref{Chain}(Flux.Chain())
    loss::RefValue{<:Function} = Ref{Function}(Flux.Losses.mse)
    input_size::RefValue{NTuple{3,Int64}} = Ref((0,0,0))
    output_size::RefValue{NTuple{3,Int64}} = Ref((0,0,0))
    problem_type::RefValue{Type{<:AbstractProblemType}} = Ref{Type{<:AbstractProblemType}}(Classification)
    input_type::RefValue{Type{<:AbstractInputType}} = Ref{Type{<:AbstractInputType}}(Image)
    input_properties::RefValue{Vector{Symbol}} = Ref(Vector{Symbol}(undef,0))
    classes::RefValue{Vector{<:AbstractClass}} = 
        RefValue{Vector{<:AbstractClass}}(Vector{ImageClassificationClass}(undef,0))
end
model_data = ModelData()