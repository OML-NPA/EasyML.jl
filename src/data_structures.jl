
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
    model = Ref{Chain}(Flux.Chain())
    loss = Ref{Function}(Flux.Losses.mse)
    input_size = Ref((0,0,0))
    output_size = Ref((0,0,0))
    problem_type = Ref{Type{<:AbstractProblemType}}(Classification)
    input_type = Ref{Type{<:AbstractInputType}}(Image)
    input_properties = Ref{Vector{Type{<:AbstractInputProperty}}}(Type{AbstractInputProperty}[])
    classes = Ref{Vector{<:AbstractClass}}(Vector{ImageClassificationClass}(undef,0))
    layers_info::RefValue{<:Vector{AbstractLayerInfo}} = Ref{Vector{AbstractLayerInfo}}([])
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