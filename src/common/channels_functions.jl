
function empty_channel_main(channels::Channels,field::Symbol)
    channel = getfield(channels,field)
    while true
        if isready(channel)
            take!(channel)
        else
            return
        end
    end
    return nothing
end
empty_channel(field) = empty_channel_main(channels,field)

function get_progress_main(channels::Channels,field::Symbol)
    channel = getfield(channels,field)
    if isready(channel)
        value = take!(channel)
        return value
    else
        return false
    end
    return nothing
end
get_progress(field) = get_progress_main(channels,field)

function get_progress(field_raw::AbstractString)
    field = Symbol(fix_QML_types(field_raw))
    value_initial = get_progress(field)
    if value_initial isa Tuple
        return [value_initial...]
    else
        return value_initial
    end
end


function put_channel_main(channels::Channels,field,value)
    field = fix_QML_types(field)
    field_sym = Symbol(field)
    channel = getfield(channels,field_sym)
    value_raw = [2.0,10.0]
    value_raw::Vector{Float64} = fix_QML_types(value)
    value1 = convert(Int64,value_raw[1])
    value2 = convert(Float64,value_raw[2])
    value = (value1,value2)
    put!(channel,value)
end
put_channel(field,value) = put_channel_main(channels,field,value)
