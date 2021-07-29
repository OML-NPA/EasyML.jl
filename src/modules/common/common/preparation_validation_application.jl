
num_threads() = options.GlobalOptions.HardwareResources.num_threads

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

function getdirs(dir)
    return filter(x -> isdir(joinpath(dir, x)),readdir(dir))
end

function getfiles(dir)
    return filter(x -> !isdir(joinpath(dir, x)),
        readdir(dir))
end


function filter_ext(urls::Vector{String},allowed_ext::Vector{String})
    urls_split = split.(urls,'.')
    ext = map(x->string(x[end]),urls_split)
    ext = lowercase.(ext)
    log_inds = map(x->x in allowed_ext,ext)
    urls_out = urls[log_inds]
    return urls_out
end


# Convert images to grayscale Array{Float32,2}
function image_to_gray_float(image::Array{RGB{Normed{UInt8,8}},2})
    img_temp = channelview(float.(Gray.(image)))
    return collect(reshape(img_temp,size(img_temp)...,1))
end

# Convert images to RGB Array{Float32,3}
function image_to_color_float(image::Array{RGB{Normed{UInt8,8}},2})
    img_temp = permutedims(channelview(float.(image)),[2,3,1])
    return collect(img_temp)
end


function load_image(url::String)
    img::Array{RGB{N0f8},2} = load(url)
    return img
end