
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

#---Final----------------------------------------------------------------

@with_kw mutable struct ModelData<:AbstractEasyML
    model::RefValue{Chain} = Ref{Chain}(Flux.Chain())
    loss::RefValue{Function} = Ref{Function}(Flux.Losses.mse)
    input_size::RefValue{NTuple{3,Int64}} = Ref((0,0,0))
    output_size::RefValue{NTuple{3,Int64}} = Ref((0,0,0))
    problem_type::RefValue{Type{<:AbstractProblemType}} = 
        Ref{Type{<:AbstractProblemType}}(Classification)
    input_type::RefValue{Type{<:AbstractInputType}} = 
        Ref{Type{<:AbstractInputType}}(Image)
    input_properties::RefValue{Vector{Type{<:AbstractInputProperty}}} = 
        Ref{Vector{Type{<:AbstractInputProperty}}}(Type{AbstractInputProperty}[])
    classes::RefValue{Vector{<:AbstractClass}} = 
        Ref{Vector{<:AbstractClass}}(Vector{ImageClassificationClass}(undef,0))
    layers_info::RefValue{<:Vector{AbstractLayerInfo}} = 
        Ref{Vector{AbstractLayerInfo}}([])
end
model_data = ModelData()


#---Testing--------------------------------------------------------------

@with_kw mutable struct UnitTest<:AbstractEasyML
    state = Ref(false)
    urls = Ref(String[])
    url_pusher = Ref{Function}(() -> popfirst!(urls[]))
end
unit_test = UnitTest()
(m::UnitTest)() = m.state