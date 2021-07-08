
# Get urls of files in selected folders. Requires only data
function get_urls1(url_inputs::String,allowed_ext::Vector{String})
    # Get a reference to url accumulators
    input_urls = Vector{Vector{String}}(undef,0)
    filenames = Vector{Vector{String}}(undef,0)
    # Empty a url accumulator
    empty!(input_urls)
    # Return if empty
    if isempty(url_inputs)
        @warn "Directory is empty."
        return nothing
    end
    # Get directories containing our images and labels
    dirs = getdirs(url_inputs)
    # If no directories, then set empty string
    if length(dirs)==0
        dirs = [""]
    end
    # Collect urls
    for k = 1:length(dirs)
        input_urls_temp = Vector{String}(undef,0)
        dir = dirs[k]
        # Get files in a directory
        files_input = getfiles(string(url_inputs,"/",dir))
        files_input = filter_ext(files_input,allowed_ext)
        # Push urls into an accumulator
        for l = 1:length(files_input)
            push!(input_urls_temp,string(url_inputs,"/",dir,"/",files_input[l]))
        end
        push!(filenames,files_input)
        push!(input_urls,input_urls_temp)
    end
    if dirs==[""]
        url_split = split(url_inputs,('/','\\'))
        dirs = [url_split[end]]
    end
    return input_urls,dirs,filenames
end

