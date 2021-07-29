
module Application

using Parameters
import ..check_setfield!

#---Model data----------------------------------------------------------

abstract type AbstractOutputOptions end

mutable struct ImageClassificationOutputOptions<:AbstractOutputOptions
end

mutable struct ImageRegressionOutputOptions<:AbstractOutputOptions
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
    binning::Symbol = :auto
    value::Float64 = 10
    normalization::Symbol = :none
end

@with_kw mutable struct OutputVolume
    volume_distribution::Bool = false
    obj_volume::Bool = false
    obj_volume_sum::Bool = false
    binning::Symbol = :auto
    value::Float64 = 10
    normalization::Symbol = :none
end

@with_kw mutable struct ImageSegmentationOutputOptions<:AbstractOutputOptions
    Mask::OutputMask = OutputMask()
    Area::OutputArea = OutputArea()
    Volume::OutputVolume = OutputVolume()
end

function Base.setproperty!(obj::Union{OutputArea,OutputVolume},k::Symbol,value::Symbol)
    if k==:binning
        syms = (:auto,:number_of_bins,:bin_width)
        check_setfield!(obj,k,value,syms)
    elseif k==:normalization
        syms = (:none,:probability,:density,:pdf)
        check_setfield!(obj,k,value,syms)
    else
        setfield!(obj,k,value)
    end
    return nothing
end


#---Data----------------------------------------------------------------

@with_kw mutable struct ApplicationData
    input_urls::Vector{Vector{String}} = Vector{Vector{String}}(undef,0)
    folders::Vector{String} = Vector{String}(undef,0)
    url_inputs::String = ""
    tasks::Vector{Task} = Vector{Task}(undef,0)
end
application_data = ApplicationData()


#---Options----------------------------------------------------------------

@with_kw mutable struct ApplicationOptions
    savepath::String = ""
    apply_by::Symbol = :file
    data_type::Symbol = :csv
    image_type::Symbol = :png
    scaling::Float64 = 1
end
application_options = ApplicationOptions()

function Base.setproperty!(obj::ApplicationOptions,k::Symbol,value::Symbol)
    if k==:apply_by
        syms = (:file,:folder)
        check_setfield!(obj,k,value,syms)
    elseif k==:data_type
        syms = (:csv,:xlsx,:json,:bson)
        check_setfield!(obj,k,value,syms)
    elseif k==:image_type
        syms = (:png,:tiff,:json,:bson)
        check_setfield!(obj,k,value,syms)
    end
    return nothing
end


#---Export all--------------------------------------------------------------

for n in names(@__MODULE__; all=true)
    if Base.isidentifier(n) && n ∉ (Symbol(@__MODULE__), :eval, :include)
        @eval export $n
    end
end

end