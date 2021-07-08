
# Return a value from progress channels without taking the value
function check_progress_main(channels::Channels,field)
    field::String = fix_QML_types(field)
    field_sym = Symbol(field)
    channel = getfield(channels,field_sym)
    if isready(channel)
        return fetch(channel)
    else
        return false
    end
end
check_progress(field) = check_progress_main(channels,field)

# Return a value from progress channels by taking the value
function get_progress_main(channels::Channels,field)
    field::String = fix_QML_types(field)
    field_sym = Symbol(field)
    channel = getfield(channels,field_sym)
    if isready(channel)
        value_raw = take!(channel)
        if value_raw isa Tuple
            value = [value_raw...]
        else
            value = value_raw
        end
        return value
    else
        return false
    end
end
get_progress(field) = get_progress_main(channels,field)

function empty_progress_channel_main(channels::Channels,field)
    field::String = fix_QML_types(field)
    field_sym = Symbol(field)
    channel = getfield(channels,field_sym)
    while true
        if isready(channel)
            take!(channel)
        else
            return
        end
    end
end
empty_progress_channel(field) = empty_progress_channel_main(channels,field)

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

