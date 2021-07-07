
#---Model data

abstract type AbstractClass end

@with_kw mutable struct ImageClassificationClass<:AbstractClass
    name::String = ""
    weight::Float32 = 1
end

@with_kw mutable struct ImageRegressionClass<:AbstractClass
    name::String = ""
end

@with_kw mutable struct ImageSegmentationClass<:AbstractClass
    name::String = ""
    weight::Float32 = 1
    color::Vector{Float64} = Vector{Float64}(undef,3)
    border::Bool = false
    border_thickness::Int64 = 3
    border_remove_objs::Bool = false
    min_area::Int64 = 1
    parents::Vector{String} = ["",""]
    not_class::Bool = false
end

abstract type AbstractOutputOptions end

@with_kw mutable struct ImageClassificationOutputOptions<:AbstractOutputOptions
    temp::Bool = false
end

@with_kw mutable struct ImageRegressionOutputOptions<:AbstractOutputOptions
    temp::Bool = false
end

@with_kw mutable struct OutputMask
    mask::Bool = false
    mask_border::Bool = false
    mask_applied_border::Bool = false
end

@with_kw mutable struct OutputArea
    area_distribution::Bool = false
    obj_area::Bool = false
    obj_area_sum::Bool = false
    binning::Int64 = 0
    value::Float64 = 10
    normalisation::Int64 = 0
end

@with_kw mutable struct OutputVolume
    volume_distribution::Bool = false
    obj_volume::Bool = false
    obj_volume_sum::Bool = false
    binning::Int64 = 0
    value::Float64 = 10
    normalisation::Int64 = 0
end

@with_kw mutable struct ImageSegmentationOutputOptions<:AbstractOutputOptions
    Mask::OutputMask = OutputMask()
    Area::OutputArea = OutputArea()
    Volume::OutputVolume = OutputVolume()
end

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

@with_kw mutable struct ModelData
    model::Chain = Chain()
    layers_info::Vector{AbstractLayerInfo} = []
    loss::Function = Flux.Losses.mse
    input_size::NTuple{3,Int64} = (1,1,1)
    output_size::Union{Tuple{Int64},NTuple{3,Int64}} = (1,1,1)
    problem_type::Symbol = :Classification
end
model_data = ModelData()

#---Master data
@with_kw mutable struct DesignData
    ModelData::ModelData = ModelData()
    output_options_backup::Vector{AbstractOutputOptions} = Vector{ImageClassificationOutputOptions}(undef,0)
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
@with_kw mutable struct Graphics
    scaling_factor::Float64 = 1
end
graphics = Graphics()

@with_kw mutable struct GlobalOptions
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
@with_kw mutable struct Options
    GlobalOptions::GlobalOptions = global_options
    DesignOptions::DesignOptions = design_options
end
options = Options()

# Needed for testing
@with_kw mutable struct UnitTest
    state::Bool = false
end
unit_test = UnitTest()
(m::UnitTest)() = m.state