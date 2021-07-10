
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
            setproperty!(obj1,field,getproperty(obj2,field))
        end
    end
end


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

@with_kw mutable struct ModelData<:AbstractEasyML
    problem_type::Ref{Symbol} = Ref(:Classification)
    input_type::Ref{Symbol} = Ref(:Image)
    classes::Ref{Vector{<:AbstractClass}} = Ref{Vector{<:AbstractClass}}(Vector{ImageClassificationClass}(undef,0))
end
model_data = ModelData()


#---All data------------------------------------------------------------------

@with_kw mutable struct AllData<:AbstractEasyML
    model_url::Ref{String} = Ref("")
    model_name::Ref{String} = Ref("")
end
all_data = AllData()


#---Options-------------------------------------------------------------------

@with_kw mutable struct Graphics<:AbstractEasyML
    scaling_factor::Ref{Float64} = Ref(1.0)
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

@with_kw mutable struct UnitTest<:AbstractEasyML
    state::Ref{Bool} = Ref(false)
    urls::Ref{Vector{String}} = Ref(String[])
    url_pusher = () -> popfirst!(unit_test.urls)
end
unit_test = UnitTest()
(m::UnitTest)() = m.state

