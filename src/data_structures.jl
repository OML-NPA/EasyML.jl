
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
            setfield!(obj1,field,getfield(obj2,field))
        end
    end
end


#---Model data----------------------------------------------------------------------

abstract type AbstractProblemType end
struct Classification <: AbstractProblemType end
struct Regression <: AbstractProblemType end
struct Segmentation <: AbstractProblemType end

abstract type AbstractInputType end
struct Image <: AbstractInputType end