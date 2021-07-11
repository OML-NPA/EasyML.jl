
function max_num_threads()
    return length(Sys.cpu_info())
end

num_threads() = hardware_resources.num_threads

# Get urls of files in selected folders. Requires data and labels
function get_urls2(url_inputs::String,label_url::String,allowed_ext::Vector{String})
    # Get a reference to url accumulators
    input_urls = Vector{Vector{String}}(undef,0)
    label_urls = Vector{Vector{String}}(undef,0)
    filenames = Vector{Vector{String}}(undef,0)
    fileindices = Vector{Vector{Int64}}(undef,0)
    # Empty url accumulators
    empty!(input_urls)
    empty!(label_urls)
    # Return if empty
    if isempty(url_inputs) || isempty(label_url)
        @error "Empty urls."
        return nothing,nothing,nothing
    end
    # Get directories containing our images and labels
    dirs_input= getdirs(url_inputs)
    dirs_labels = getdirs(label_url)
    # Keep only those present for both images and labels
    dirs = intersect(dirs_input,dirs_labels)
    # If no directories, then set empty string
    if length(dirs)==0
        dirs = [""]
    end
    # Collect urls
    cnt = 0
    for k = 1:length(dirs)
        input_urls_temp = Vector{String}(undef,0)
        label_urls_temp = Vector{String}(undef,0)
        # Get files in a directory
        files_input = getfiles(string(url_inputs,"/",dirs[k]))
        files_labels = getfiles(string(label_url,"/",dirs[k]))
        # Filter files
        files_input = filter_ext(files_input,allowed_ext)
        files_labels = filter_ext(files_labels,allowed_ext)
        # Remove extensions from files
        filenames_input = remove_ext(files_input)
        filenames_labels = remove_ext(files_labels)
        # Intersect file names
        inds1, inds2 = intersect_inds(filenames_labels, filenames_input)
        # Keep files present for both images and labels
        files_input = files_input[inds2]
        files_labels = files_labels[inds1]
        # Push urls into accumulators
        num = length(files_input)
        for l = 1:num
            push!(input_urls_temp,string(url_inputs,"/",files_input[l]))
            push!(label_urls_temp,string(label_url,"/",files_labels[l]))
        end
        push!(filenames,filenames_input[inds2])
        push!(fileindices,cnt+1:num)
        push!(input_urls,input_urls_temp)
        push!(label_urls,label_urls_temp)
        cnt = num
    end
    return input_urls,label_urls,dirs,filenames,fileindices
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


function load_image(url::String)
    img::Array{RGB{N0f8},2} = load(url)
    return img
end