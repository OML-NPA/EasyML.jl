
module CoreTypes

using Flux

#--Types--------------------------------------------------------------

abstract type AbstractProblemType end
struct Classification <: AbstractProblemType end
struct Regression <: AbstractProblemType end
struct Segmentation <: AbstractProblemType end

abstract type AbstractInputType end
struct Image <: AbstractInputType end

const AbstractModel = Union{Flux.Chain}


#---Export all--------------------------------------------------------------

for n in names(@__MODULE__; all=true)
    if Base.isidentifier(n) && n ∉ (Symbol(@__MODULE__), :eval, :include)
        @eval export $n
    end
end

end