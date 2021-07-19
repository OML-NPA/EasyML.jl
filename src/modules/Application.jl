
module Application

using Parameters, EasyMLCore.Common

#---Model data----------------------------------------------------------

abstract type AbstractApplicationMethod end

struct File<:AbstractApplicationMethod end
struct Folder<:AbstractApplicationMethod end

# File types
struct CSV end
struct XLSX end
struct JSON end
struct BSON end
struct PNG end
struct TIFF end

const AbstractDelimitedFileType = Union{CSV,XLSX,JSON,BSON}
const AbstractImageFileType = Union{PNG,JSON,BSON}

###### Auto
struct NumberOfBins end
struct BinWidth end

const AbstractBinningMethod = Union{Auto,NumberOfBins,BinWidth}

###### None
struct Probability end
struct Density end
struct PDF end

const AbstractNormalizationMethod = Union{None,Probability,Density,PDF}

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
    binning::Type{<:AbstractBinningMethod} = Auto
    value::Float64 = 10
    normalisation::Type{<:AbstractNormalizationMethod} = None
end

@with_kw mutable struct OutputVolume
    volume_distribution::Bool = false
    obj_volume::Bool = false
    obj_volume_sum::Bool = false
    binning::Type{<:AbstractBinningMethod} = Auto
    value::Float64 = 10
    normalisation::Type{<:AbstractNormalizationMethod} = None
end

@with_kw mutable struct ImageSegmentationOutputOptions<:AbstractOutputOptions
    Mask::OutputMask = OutputMask()
    Area::OutputArea = OutputArea()
    Volume::OutputVolume = OutputVolume()
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
    apply_by::Type{<:AbstractApplicationMethod} = File
    data_type::Type{<:AbstractDelimitedFileType} = CSV
    image_type::Type{<:AbstractImageFileType} = PNG
    scaling::Float64 = 1
end
application_options = ApplicationOptions()


#---Export all--------------------------------------------------------------

for n in names(@__MODULE__; all=true)
    if Base.isidentifier(n) && n ∉ (Symbol(@__MODULE__), :eval, :include)
        @eval export $n
    end
end

end