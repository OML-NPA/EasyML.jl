
#---Histogram and objects related functions
function objects_count(components::Array{Int64,2})
    return maximum(components)
end

function objects_area(mask_current::BitArray{2},components_vector::Vector{Array{Int64,2}},
        labels_incl::Vector{Vector{Int64}},scaling::Float64,l::Int64)
    components = components_vector[l]
    scaling = scaling^2
    incl_bool = map(x->any(x.==l),labels_incl)
    ind = findfirst(incl_bool)
    if isnothing(ind)
        area = component_lengths(components)[2:end]
        area_out = convert(Vector{Float64},area)./scaling
    else
        components_parent = components_vector[ind]
        num = maximum(components_parent)
        area_out = Vector{Float64}(undef,num)
        for i = 1:num
            ind_bool = components_parent.==i
            area_out[i] = count(mask_current[ind_bool])./scaling
        end
    end
    return area_out
end

# Makes a 3D representation of a 2D object based on optimising circularity
function func2D_to_3D(objects_mask::BitArray{2})
    D = Float32.(distance_transform(feature_transform((!).(objects_mask))))
    w = zeros(Float32,(size(D)...,8))
    inds = vcat(1:4,6:9)
    for i = 1:8
      u = zeros(Float32,(9,1))
      u[inds[i]] = 1
      u = reshape(u,(3,3))
      w[:,:,i] = imfilter(D,centered(u))
    end
    pks = all(D.>=w,dims=3)[:,:] .& objects_mask
    mask2 = BitArray(undef,size(objects_mask))
    fill!(mask2,true)
    mask2[pks] .= false
    D2 = Float32.(distance_transform(feature_transform((!).(mask2))))
    D2[(!).(objects_mask)] .= 0
    mask_out = sqrt.((D+D2).^2-D2.^2)
    return mask_out
end

function objects_volume(objects_mask::BitArray{2},components_vector::Vector{Array{Int64,2}},
        labels_incl::Vector{Vector{Int64}},scaling::Float64,l::Int64)
    components = components_vector[l]
    volume_model = func2D_to_3D(objects_mask)
    scaling = scaling^3
    num = maximum(components)
    incl_bool = map(x->any(x.==l),labels_incl)
    ind = findfirst(incl_bool)
    
    if isnothing(ind)
        num = maximum(components)
        volumes_out = Vector{Float64}(undef,num)
        for i = 1:num
            logical_inds = components.==i
            pixels = volume_model[logical_inds]
            volumes_out[i] = 2*sum(pixels)/scaling
        end
    else
        components_parent = components_vector[ind]
        num = maximum(components_parent)
        volumes_out = Vector{Float64}(undef,num)
        for i = 1:num
            ind_bool = components_parent.==i
            pixels = volume_model[ind_bool]
            volumes_out[i] = 2*sum(pixels)/scaling
        end
    end
    return volumes_out
end

function get_dataframe_names(names::Vector{String},type::String,
        Bools::Vector{Bool},datatype::Symbol)
    names_x = String[]
    inds = findall(Bools)
    if datatype==:dists
        for i in inds
            name_current = names[i]
            name_edges = string(name_current,"_",type,"_edges")
            name_weights = string(name_current,"_",type,"_weights")
            push!(names_x,name_edges,name_weights)
        end
    elseif datatype==:objs
        for i in inds
            name_current = names[i]
            name = string(name_current,"_",type)
            push!(names_x,name)
        end
    end
    return names_x
end

function histograms_to_dataframe(df::DataFrame,histograms::Vector{Histogram},
        num::Int64,offset::Int64)
    inds = 1:2:2*num
    for j = 1:num
        ws = histograms[j].weights
        numel = length(ws)
        edges = collect(histograms[j].edges[1])
        edges = map(ind->mean([edges[ind],edges[ind+1]]),1:numel)
        df[1:numel,inds[j]+offset] .= edges
        df[1:numel,inds[j]+offset+1] .= ws
    end
end

function objs_to_dataframe(df::DataFrame,objs::Vector{Vector{Float64}},
        num::Int64,offset::Int64)
    for j = 1:num
        objs_current = objs[j]
        numel = length(objs_current)
        df[1:numel,j+offset] .= objs_current
    end
end

function objs_to_dataframe(df::DataFrame,objs::Vector{Float64},
        num::Int64,offset::Int64)
    start = offset + 1
    finish = num + start -1
    df[1,start:finish] .= objs
end

function data_to_histograms(histograms_area::Vector{Vector{Histogram}},
        histograms_volume::Vector{Vector{Histogram}},
        objs_area::Vector{Vector{Vector{Float64}}},
        objs_volume::Array{Vector{Vector{Float64}}},
        output_options::Vector{ImageSegmentationOutputOptions},num_batch::Int64,
        num_classes::Int64,num_border::Int64,border::Vector{Bool})
    for i = 1:num_batch
        temp_histograms_area = histograms_area[i]
        temp_histograms_volume = histograms_volume[i]
        for l = 1:num_classes
            current_options = output_options[l]
            area_dist_cond = current_options.Area.area_distribution
            volume_dist_cond = current_options.Volume.volume_distribution
            ind = l
            if border[l]==true
                ind = l + num_border + num_classes
            end
            if area_dist_cond
                area_options = current_options.Area
                area_values = objs_area[i][l]
                if isempty(area_values)
                    @warn "No objects to export for area."
                else
                    temp_histograms_area[l] = make_histogram(area_values,area_options)
                end
            end
            if volume_dist_cond
                volume_options = current_options.Volume
                volume_values = objs_volume[i][l]
                if isempty(area_values)
                    @warn "No objects to export for volume."
                else
                    temp_histograms_volume[l] = make_histogram(volume_values,volume_options)
                end
            end
        end
    end
    return nothing
end

function mask_to_data(objs_area::Vector{Vector{Vector{Float64}}},
        objs_volume::Vector{Vector{Vector{Float64}}},cnt::Int64,mask::BitArray{3},
        output_options::Vector{ImageSegmentationOutputOptions},
        labels_incl::Vector{Vector{Int64}},border::Vector{Bool},num_classes::Int64,
        num_border::Int64,scaling::Float64)
    temp_objs_area = objs_area[cnt]
    temp_objs_volume = objs_volume[cnt]
    components_vector = Vector{Array{Int64,2}}(undef,num_classes)
    for l = 1:num_classes
        ind = l
        if border[l]==true
            ind = l + num_border + num_classes
        end
        mask_current = mask[:,:,ind]
        components = label_components(mask_current,conn(4))
        components_vector[l] = components
    end
    for l = 1:num_classes
        current_options = output_options[l]
        area_dist_cond = current_options.Area.area_distribution
        area_obj_cond = current_options.Area.obj_area
        area_sum_obj_cond = current_options.Area.obj_area_sum
        volume_dist_cond = current_options.Volume.volume_distribution
        volume_obj_cond = current_options.Volume.obj_volume
        volume_sum_obj_cond = current_options.Volume.obj_volume_sum
        ind = l
        if border[l]==true
            ind = l + num_border + num_classes
        end
        mask_current = mask[:,:,ind]
        
        if area_dist_cond || area_obj_cond || area_sum_obj_cond
            temp_objs_area2 = temp_objs_area[l]
            area_values = [0]
            area_values = objects_area(mask_current,
                components_vector,labels_incl,scaling,l)
            
            if area_obj_cond || area_sum_obj_cond
                push!(temp_objs_area2,area_values...)
            end
        end
        if volume_dist_cond || volume_obj_cond || volume_sum_obj_cond
            temp_objs_volume2 = temp_objs_volume[l]
            volume_values = objects_volume(mask_current,
                components_vector,labels_incl,scaling,l)
            if volume_obj_cond || volume_sum_obj_cond
                push!(temp_objs_volume2,volume_values...)
            end
        end
    end
    return nothing
end

function make_histogram(values::Vector{<:Real}, options::Union{OutputArea,OutputVolume})
    if options.binning==:auto
        h = fit(Histogram, values)
    elseif options.binning==:number_of_bins
        maxval = maximum(values)
        minval = minimum(values)
        dif = maxval-minval
        step = dif/(options.value-1)
        bins = minval:step:maxval
        h = fit(Histogram, values,bins)
    else # options.binning==:bin_width
        num = round(maximum(values)/options.value)
        h = fit(Histogram, values, nbins=num)
    end
    h = normalize(h, mode=options.normalization)
    return h
end

function export_histograms(histograms_area::Vector{Vector{Histogram}},
        histograms_volume::Vector{Vector{Histogram}},classes::Vector{ImageSegmentationClass},num::Int64,
        num_dist_area::Int64,num_dist_volume::Int64,
        log_area_dist::Vector{Bool},log_volume_dist::Vector{Bool},savepath::String,
        filenames::Vector{String},data_ext_string::String,data_ext::Symbol)
    num_cols_dist = num_dist_area + num_dist_volume
    if num_cols_dist==0
        return nothing
    end
    for i = 1:num
        if !isdefined(histograms_area,i)
            continue
        end
        num_cols_dist = num_dist_area + num_dist_volume
        if num_dist_area>0
            num_rows_area = maximum(map(x->length(x.weights),histograms_area[i]))
        else
            num_rows_area = 0
        end
        if num_dist_volume>0
            num_rows_volume = maximum(map(x->length(x.weights),histograms_volume[i]))
        else
            num_rows_volume = 0
        end
        num_rows = max(num_rows_area,num_rows_volume)
        histogram_area = histograms_area[i]
        histogram_volume = histograms_volume[i]
        rows = Vector{Union{Float64,String}}(undef,num_rows)
        fill!(rows,"")
        df_dists = DataFrame(repeat(rows,1,2*num_cols_dist), :auto)
        histograms_to_dataframe(df_dists,histogram_area,num_dist_area,0)
        offset = 2*num_dist_area
        histograms_to_dataframe(df_dists,histogram_volume,num_dist_volume,offset)
        names = map(x->x.name,classes)
        names_area = get_dataframe_names(names,"area",log_area_dist,:dists)
        names_volume = get_dataframe_names(names,"volume",log_volume_dist,:dists)
        names_all = vcat(names_area,names_volume)
        rename!(df_dists, Symbol.(names_all))
        fname = filenames[i]
        name = string("Distributions ",fname,data_ext_string)
        save(df_dists,savepath,name,data_ext)
    end
    return nothing
end

function export_objs(type_name::String,objs_area::Vector,
        objs_volume::Vector,classes::Vector{ImageSegmentationClass},
        num::Int64,num_obj_area::Int64,num_obj_volume::Int64,
        log_area_obj::Vector{Bool},log_volume_obj::Vector{Bool},savepath::String,
        filenames::Vector{String},data_ext_string::String,data_ext::Symbol)
    num_cols_obj = num_obj_area + num_obj_volume
    if num_cols_obj==0
        return nothing
    end
    for i = 1:num
        if num_obj_area>0
            num_rows_area = maximum(map(x->length(x),objs_area[i]))
        else
            num_rows_area = 0
        end
        if num_obj_volume>0
            num_rows_volume = maximum(map(x->length(x),objs_volume[i]))
        else
            num_rows_volume = 0
        end
        num_rows = max(num_rows_area,num_rows_volume)
        obj_area = objs_area[i]
        obj_volume = objs_volume[i]
        rows = Vector{Union{Float64,String}}(undef,num_rows)
        fill!(rows,"")
        df_objs = DataFrame(repeat(rows,1,num_cols_obj), :auto)
        objs_to_dataframe(df_objs,obj_area,num_obj_area,0)
        offset = num_obj_area
        objs_to_dataframe(df_objs,obj_volume,num_obj_volume,offset)
        names = map(x->x.name,classes)
        names_area = get_dataframe_names(names,"area",log_area_obj,:objs)
        names_volume = get_dataframe_names(names,"volume",log_volume_obj,:objs)
        names_all = vcat(names_area,names_volume)
        rename!(df_objs, Symbol.(names_all))
        fname = filenames[i]
        name = string(type_name," ",fname,data_ext_string)
        save(df_objs,savepath,name,data_ext)
    end
    return nothing
end

#---Image related functions
function get_save_image_info(num_dims::Int64,classes::Vector{ImageSegmentationClass},
        output_options::Vector{ImageSegmentationOutputOptions},border::Vector{Bool})
    num_classes = length(border)
    num_border = sum(border)
    logical_inds = BitArray{1}(undef,num_dims)
    img_names = Vector{String}(undef,num_classes+num_border*2)
    for a = 1:num_classes
        class = classes[a]
        class_name = class.name
        if output_options[a].Mask.mask
            logical_inds[a] = true
            img_names[a] = class_name
        end
        if class.border
            if output_options[a].Mask.mask_border
                ind = a + num_classes
                logical_inds[ind] = true
                img_names[ind] = string(class_name," (border)")
            end
            if output_options[a].Mask.mask_applied_border
                ind = num_classes + num_border + a
                logical_inds[ind] = true
                img_names[ind] = string(class_name," (applied border)")
            end
        end
    end
    inds = findall(logical_inds)
    return inds,img_names
end

function mask_to_img(mask::BitArray{3},classes::Vector{ImageSegmentationClass},
        output_options::Vector{ImageSegmentationOutputOptions},
        labels_color::Vector{Vector{Float64}},border::Vector{Bool},
        savepath::String,filename::String,ext::String,sym_ext::Symbol)
    num_dims = size(mask)[3]
    inds,img_names = get_save_image_info(num_dims,classes,output_options,border)
    if isempty(inds)
        return nothing
    end
    border_colors = labels_color[findall(border)]
    labels_color = vcat(labels_color,border_colors,border_colors)
    perm_labels_color64 = map(x -> permutedims(x[:,:,:]/255,[3,2,1]),labels_color)
    perm_labels_color = convert(Array{Array{Float32,3}},perm_labels_color64)
    path = joinpath(savepath,filename)
    if !isdir(path)
        mkdir(path)
    end
    for j = 1:length(inds)
        ind = inds[j]
        mask_current = mask[:,:,ind]
        color = perm_labels_color[ind]
        mask_float = convert(Array{Float32,2},mask_current)
        mask_dim3 = cat3(mask_float,mask_float,mask_float)
        mask_dim3 = mask_dim3.*color
        mask_dim3 = cat3(mask_dim3,mask_float)
        mask_dim3 = permutedims(mask_dim3,[3,1,2])
        mask_RGB = colorview(RGBA,mask_dim3)
        img_name = img_names[ind]
        name = string(img_name," ",filename,ext)
        save(mask_RGB,path,name,sym_ext)
    end
    return nothing
end

#---Saving
function get_data_ext(data_type)
    ext = [:csv,:xlsx,:json,:bson]
    ind = findfirst(data_type.==ext)
    ext_string = [".csv",".xlsx",".json",".bson"]
    return ext[ind]
end

function get_image_ext(data_type)
    ext = [:png,:tiff,:bson]
    ind = findfirst(data_type.==ext_symbol_caps)
    ext_string = [".png",".tiff",".bson"]
    return ext[ind]
end

function save(data,path::String,name::String,ext::Symbol)
    if !isdir(path)
        dirs = splitpath(path)
        start = length(dirs) - 3
        for i=start:length(dirs)
            temp_path = join(dirs[1:i],'/')
            if !isdir(temp_path)
                mkdir(temp_path)
            end
        end
    end
    url = joinpath(path,name)
    if isfile(url)
        rm(url)
    end
    if ext==:json
        open(url,"w") do f
            JSON_pkg.print(f,data)
        end
    elseif ext==:bson
        BSON.@save(url,data)
    elseif ext==:xlsx
        XLSX.writetable(url, collect(DataFrames.eachcol(data)), DataFrames.names(data))
    else
        FileIO.save(url,data)
    end
end