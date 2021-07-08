
function empty_channel_main(channels::Channels,field::Symbol)
    channel = getfield(channels,field)
    while true
        if isready(channel)
            take!(channel)
        else
            return
        end
    end
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
end
get_progress(field) = get_progress_main(channels,field)


