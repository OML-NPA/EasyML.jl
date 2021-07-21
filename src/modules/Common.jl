
module Common

using Flux, Parameters

#--Types--------------------------------------------------------------

const AbstractModel = Union{Flux.Chain}

function none(data)
    return Float32[]
end

@with_kw mutable struct Normalization
    f::Function = none
    args::Tuple = ()
end

function sym_to_string(sym::Symbol)
    return string(":",string(sym))
end

function msg_generator(value::Symbol,syms::NTuple{N,Symbol}) where N
    local msg_end
    msg_start = string(sym_to_string(value)," is not allowed. ")
    msg_mid = "Value should be "
    if N==1
        msg_end = string(sym_to_string.(syms),".")
    elseif N==2
        msg_end = string(join(sym_to_string.(syms), " or "),".")
    else
        msg_end = sym_to_string(syms[1])
        for i = 2:length(syms)-1
            msg_end = string(msg_end,", ",sym_to_string(syms[i]),".")
        end
        msg_end = string(msg_end," or ",sym_to_string(syms[end]))
    end
    msg = string(msg_start,msg_mid,msg_end)
    return msg
end

function check_setfield!(obj,k::Symbol,value::Symbol,syms::NTuple{N,Symbol}) where N
    if value in syms
        setfield!(obj,k,value)
    else
        msg = msg_generator(value,syms)
        throw(ArgumentError(msg))
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