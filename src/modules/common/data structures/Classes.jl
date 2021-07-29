
module Classes

using Parameters


#---Data----------------------------------------------------------------

abstract type AbstractClass end

@with_kw mutable struct ImageClassificationClass<:AbstractClass
    name::String = ""
    weight::Float32 = 1
    function ImageClassificationClass(name;weight=1)
        new(name,weight)
    end
end

@with_kw mutable struct ImageRegressionClass<:AbstractClass
    name::String = ""
    function ImageRegressionClass(name)
        new(name)
    end
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
    function ImageSegmentationClass(name;color::Vector{Int64},weight=1,parents=["",""],overlap=false,min_area=0,border_class=BorderClass())
        new(name,weight,color,parents,overlap,min_area,border_class)
    end
end


#---Options----------------------------------------------------------------


#---Export all--------------------------------------------------------------

for n in names(@__MODULE__; all=true)
    if Base.isidentifier(n) && n ∉ (Symbol(@__MODULE__), :eval, :include)
        @eval export $n
    end
end


end