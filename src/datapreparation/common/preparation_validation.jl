
function load_regression_data(url::String)
    ext_raw = split(url,".")[end]
    ext = Unicode.normalize(ext_raw, casefold=true)
    if ext=="csv"
        labels_info = DataFrame(CSVFiles.load(url))
    else ext=="xlsx"
        labels_info = DataFrame(XLSX.readtable(url,1)...)
    end
    filenames_labels::Vector{String} = labels_info[:,1]
    labels_original_T = map(ind->Vector(labels_info[ind,2:end]),1:size(labels_info,1))
    loaded_labels::Vector{Vector{Float32}} = convert(Vector{Vector{Float32}},labels_original_T)
    return filenames_labels,loaded_labels
end

function intersect_regression_data!(input_urls::Vector{String},filenames_inputs::Vector{String},
        loaded_labels::Vector{Vector{Float32}},filenames_labels::Vector{String})
    num = length(filenames_inputs)
    inds_adj = zeros(Int64,num)
    inds_remove = Vector{Int64}(undef,0)
    cnt = 1
    l = length(filenames_inputs)
    while cnt<=l
        filename = filenames_inputs[cnt]
        ind = findfirst(x -> x==filename, filenames_labels)
        if isnothing(ind)
            deleteat!(input_urls,cnt)
            deleteat!(filenames_inputs,cnt)
            l-=1
        else
            inds_adj[cnt] = ind
            cnt += 1
        end
    end
    num = cnt - 1
    inds_adj = inds_adj[1:num]
    filenames_labels_temp = filenames_labels[inds_adj]
    loaded_labels_temp = loaded_labels[inds_adj]
    r = length(filenames_labels_temp)+1:length(filenames_labels)
    deleteat!(filenames_labels,r)
    deleteat!(loaded_labels,r)
    filenames_labels .= filenames_labels_temp
    loaded_labels .= loaded_labels_temp
    return nothing
end

function intersect_inds(ar1,ar2)
    inds1 = Array{Int64,1}(undef, 0)
    inds2 = Array{Int64,1}(undef, 0)
    for i=1:length(ar1)
        inds_log = ar2.==ar1[i]
        if any(inds_log)
            push!(inds1,i)
            push!(inds2,findfirst(inds_log))
        end
    end
    return (inds1, inds2)
end

function remove_ext(files::Vector{String})
    filenames = copy(files)
    for i=1:length(files)
        chars = collect(files[i])
        ind = findfirst(chars.=='.')
        filenames[i] = String(chars[1:ind-1])
    end
    return filenames
end

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

# Convert images to BitArray{3}
function label_to_bool(labelimg::Array{RGB{Normed{UInt8,8}},2}, class_inds::Vector{Int64},
        labels_color::Vector{Vector{Float64}},labels_incl::Vector{Vector{Int64}},
        border::Vector{Bool},border_num::Vector{Int64})
    colors = map(x->RGB((n0f8.(./(x,255)))...),labels_color)
    num = length(class_inds)
    num_borders = sum(border)
    inds_borders = findall(border)
    label = fill!(BitArray{3}(undef, size(labelimg)...,
        num + num_borders),0)
    # Find classes based on colors
    for i in class_inds
        colors_current = [colors[i]]
        inds = findall(map(x->issubset(i,x),labels_incl))
        if !isempty(class_inds)
            push!(colors_current,colors[inds]...)
        end
        bitarrays = map(x -> .==(labelimg,x)[:,:,:],colors_current)
        label[:,:,i] = any(reduce(cat3,bitarrays),dims=3)
    end
    # Make classes outlining object borders
    for j=1:length(inds_borders)
        ind = inds_borders[j]
        border = outer_perim(label[:,:,ind])
        dilate!(border,border_num[ind])
        label[:,:,num+j] = border
    end
    return label
end


#---Other----------------------------------------------------------

cat3(A::AbstractArray, B::AbstractArray) = cat(A, B; dims=Val(3))