
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

#---Model data

abstract type AbstractLayerInfo end

@with_kw mutable struct GenericInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    type::String = ""
    group::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
end

@with_kw mutable struct InputInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    type::String = ""
    group::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    size::NTuple{3,Int64} = (0,0,0)
    normalisation::Tuple{String,Int64} = ("",0)
end

@with_kw mutable struct OutputInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    type::String = ""
    group::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    loss::Tuple{String,Int64} = ("",0)
end

@with_kw mutable struct ConvInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    type::String = ""
    group::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    filters::Int64 = 0
    filter_size::NTuple{2,Int64} = (0,0)
    stride::Int64 = 0
    dilation_factor::Int64 = 0
end

@with_kw mutable struct TConvInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    type::String = ""
    group::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    filters::Int64 = 0
    filter_size::NTuple{2,Int64} = (0,0)
    stride::Int64 = 0
    dilation_factor::Int64 = 0
end

@with_kw mutable struct DenseInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    type::String = ""
    group::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    filters::Int64 = 0
end

@with_kw mutable struct BatchNormInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    type::String = ""
    group::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    epsilon::Float64 = 0
end

@with_kw mutable struct DropoutInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    type::String = ""
    group::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    probability::Float64 = 0
end

@with_kw mutable struct LeakyReLUInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    type::String = ""
    group::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    scale::Float64 = 0
end

@with_kw mutable struct ELUInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    type::String = ""
    group::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    alpha::Float64 = 0
end

@with_kw mutable struct PoolInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    type::String = ""
    group::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    poolsize::NTuple{2,Int64} = (0,0)
    stride::Int64 = 0
end

@with_kw mutable struct AdditionInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    type::String = ""
    group::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    inputs::Int64 = 0
end

@with_kw mutable struct JoinInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    type::String = ""
    group::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    inputs::Int64 = 0
    dimension::Int64 = 0
end

@with_kw mutable struct SplitInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    type::String = ""
    group::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    outputs::Int64 = 0
    dimension::Int64 = 0
end

@with_kw mutable struct UpsampleInfo<:AbstractLayerInfo
    id::Int64 = 0
    name::String = ""
    type::String = ""
    group::String = ""
    connections_up::Vector{Int64} = Vector{Int64}(undef,0)
    connections_down::Vector{Vector{Int64}} = Vector{Vector{Int64}}(undef,0)
    x::Float64 = 0
    y::Float64 = 0
    label_color::NTuple{3,Int64} = (0,0,0)
    multiplier::Int64 = 0
    dimensions::Vector{Int64} = [0]
end

@with_kw mutable struct ModelData<:AbstractEasyMLStruct
    model::RefValue{<:Chain} = Ref{Chain}(Chain())
    layers_info::RefValue{<:Vector{AbstractLayerInfo}} = Ref{Vector{AbstractLayerInfo}}([])
    loss::RefValue{Function} = Ref{Function}(Flux.Losses.mse)
    input_size::RefValue{NTuple{3,Int64}} = Ref((1,1,1))
    output_size::RefValue{NTuple{3,Int64}} = Ref((1,1,1))
    problem_type::RefValue{Symbol} = Ref(:Classification)
end
model_data = ModelData()

#---Master data
@with_kw mutable struct DesignData
    ModelData::ModelData = ModelData()
    warnings::Vector{String} = Vector{String}(undef,0)
end
design_data = DesignData()

@with_kw mutable struct AllData
    DesignData::DesignData = design_data
    model_url::String = ""
    model_name::String = ""
end
all_data = AllData()

#---Options

# Global Options
@with_kw mutable struct Graphics<:AbstractEasyMLStruct
    scaling_factor::RefValue{Float64} = Ref(1.0)
end
graphics = Graphics()

@with_kw struct GlobalOptions
    Graphics::Graphics = graphics
end
global_options = GlobalOptions()

# Design
@with_kw mutable struct DesignOptions
    width::Float64 = 340
    height::Float64 = 100
    min_dist_x::Float64 = 80
    min_dist_y::Float64 = 40
end
design_options = DesignOptions()

# Options
@with_kw struct Options
    GlobalOptions::GlobalOptions = global_options
    DesignOptions::DesignOptions = design_options
end
options = Options()

# Needed for testing
@with_kw mutable struct UnitTest<:AbstractEasyMLStruct
    state::RefValue{Bool} = Ref(false)
    url_pusher = []
    urls::RefValue{Vector{String}} = Ref(String[])
end
unit_test = UnitTest()
(m::UnitTest)() = m.state