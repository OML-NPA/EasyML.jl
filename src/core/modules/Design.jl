

module Design

using Parameters, ..Core.Common

#---Model data----------------------------------------------------------------
module Layers

    using Parameters

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
        normalization::Int64 = 0
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
        loss::Int64 = 0
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


    #---Export all--------------------------------------------------------------

    for n in names(@__MODULE__; all=true)
        if Base.isidentifier(n) && n ∉ (Symbol(@__MODULE__), :eval, :include)
            @eval export $n
        end
    end

end


#---Data----------------------------------------------------------------

using Flux, .Layers

@with_kw mutable struct DesignModelData
    model::Flux.Chain = Flux.Chain()
    normalization::Normalization = Normalization(none,())
    loss::Function = Flux.Losses.mse
    input_size::NTuple{3,Int64} = (0,0,0)
    output_size::NTuple{3,Int64} = (0,0,0)
    problem_type::Symbol = :classification
    input_type::Symbol = :image
    layers_info::Vector{AbstractLayerInfo} =  Vector{AbstractLayerInfo}(undef,0)
end

@with_kw mutable struct DesignData
    ModelData::DesignModelData = DesignModelData()
    warnings::Vector{String} = Vector{String}(undef,0)
end
design_data = DesignData()


#---Options----------------------------------------------------------------

@with_kw mutable struct DesignOptions
    width::Float64 = 340
    height::Float64 = 100
    min_dist_x::Float64 = 80
    min_dist_y::Float64 = 40
end
design_options = DesignOptions()


#---Export all--------------------------------------------------------------

for n in names(@__MODULE__; all=true)
    if Base.isidentifier(n) && n ∉ (Symbol(@__MODULE__), :eval, :include)
        @eval export $n
    end
end

end