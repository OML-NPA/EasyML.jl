
# Get urls of files in a selected folder. Files are used for application.
function get_urls_application_main(application_data::ApplicationData)
    if settings.input_type==:Image
        allowed_ext = ["png","jpg","jpeg"]
    end
    input_urls,dirs = get_urls1(application_data.url_inputs,allowed_ext)
    application_data.input_urls = input_urls
    application_data.folders = dirs
    return nothing
end
#get_urls_application() =
#    get_urls_application_main(application,application_data,model_data)

function prepare_application_data(model_data::ModelData,classes::Vector{ImageClassificationClass},
        urls::Vector{String},processing::ProcessingTraining)
    num = length(urls)
    data = Vector{Array{Float32,4}}(undef,length(urls))
    for i = 1:num
        url = urls[i]
        image = load_image(url)
        if processing.grayscale
            data[i] = image_to_gray_float(image)[:,:,:,:]
        else
            data[i] = image_to_color_float(image)[:,:,:,:]
        end
    end
    data_out = reduce(cat4,data)
    return data_out
end

function prepare_application_data(model_data::ModelData,classes::Vector{ImageRegressionClass},
        urls::Vector{String},processing::ProcessingTraining)
    num = length(urls)
    data = Vector{Array{Float32,4}}(undef,length(urls))
    for i = 1:num
        url = urls[i]
        image = load_image(url)
        image = imresize(image,model_data.input_size[1:2])
        if processing.grayscale
            data[i] = image_to_gray_float(image)[:,:,:,:]
        else
            data[i] = image_to_color_float(image)[:,:,:,:]
        end
    end
    data_out = reduce(cat4,data)
    return data_out
end

function prepare_application_data(model_data::ModelData,classes::Vector{ImageSegmentationClass},
        urls::Vector{String},processing::ProcessingTraining)
    num = length(urls)
    data = Vector{Array{Float32,4}}(undef,length(urls))
    for i = 1:num
        url = urls[i]
        image = load_image(url)
        if processing.grayscale
            data[i] = image_to_gray_float(image)[:,:,:,:]
        else
            data[i] = image_to_color_float(image)[:,:,:,:]
        end
    end
    data_out = reduce(cat4,data)
    return data_out
end

function get_filenames(urls::Vector{Vector{String}})
    num = length(urls)
    data = Vector{Vector{String}}(undef,num)
    for i = 1:num
        data_temp = copy(urls[i])
        data_temp = map((x) -> split(x,('\\','/')), data_temp)
        data_temp = map(x->x[end],data_temp)
        data_temp = split.(data_temp,'.')
        data[i] = map(x->string(x[1:end-1]...),data_temp)
    end
    return data
end

# Batches filenames together allowing for correct naming during export
function batch_urls_filenames(urls::Vector{Vector{String}},batch_size::Int64)
    num = length(urls)
    filenames = get_filenames(urls)
    filename_batches = Vector{Vector{Vector{String}}}(undef,num)
    url_batches = Vector{Vector{Vector{String}}}(undef,num)
    for i = 1:num
        urls_temp = urls[i]
        filenames_temp = filenames[i]
        len = length(urls_temp)
        url_batches_temp = Vector{Vector{String}}(undef,0)
        filename_batches_temp = Vector{Vector{String}}(undef,0)
        num = len - batch_size
        val = max(0.0,floor(num/batch_size))
        finish = Int64(val*batch_size)
        inds = collect(0:batch_size:finish)
        if isempty(inds)
            inds = [0]
        end
        num = length(inds)
        for j = 1:num
            ind = inds[j]
            if j==num
                ind1 = ind+1
                ind2 = len
            else
                ind1 = ind+1
                ind2 = ind+batch_size
            end
            push!(url_batches_temp,urls_temp[ind1:ind2])
            push!(filename_batches_temp,filenames_temp[ind1:ind2])
        end
        url_batches[i] = url_batches_temp
        filename_batches[i] = filename_batches_temp
    end
    return url_batches,filename_batches
end

function get_output(model_data::ModelData,classes::Vector{ImageClassificationClass},processing::ProcessingTraining,
    num::Int64,urls_batched::Vector{Vector{Vector{String}}},num_slices_current::Int64,use_GPU::Bool,
    data_channel::Channel{Tuple{Int64,Vector{Int64}}},channels::Channels)
    for k = 1:num
        urls_batch = urls_batched[k]
        num_batch = length(urls_batch)
        for l = 1:num_batch
            # Stop if asked
            if check_abort_signal(channels.application_modifiers)
                return nothing
            end
            # Get input
            input_data = prepare_application_data(model_data,classes,urls_batch[l],processing)
            # Get output
            predicted = forward(model_data.model,input_data,num_slices=num_slices_current,use_GPU=use_GPU)
            _, predicted_labels4 = findmax(predicted,dims=1)
            predicted_labels = map(x-> x.I[1],predicted_labels4[:])
            # Return result
            put!(data_channel,(l,predicted_labels))
        end
    end
    return nothing
end

function get_output(model_data::ModelData,classes::Vector{ImageRegressionClass},processing::ProcessingTraining,
        num::Int64,urls_batched::Vector{Vector{Vector{String}}},num_slices_current::Int64,use_GPU::Bool,
        data_channel::Channel{Tuple{Int64,Vector{Float32}}},channels::Channels)
    for k = 1:num
        urls_batch = urls_batched[k]
        num_batch = length(urls_batch)
        for l = 1:num_batch
            # Stop if asked
            if check_abort_signal(channels.application_modifiers)
                return nothing
            end
            # Get input
            input_data = prepare_application_data(model_data,classes,urls_batch[l],processing)
            # Get output
            predicted = forward(model_data.model,input_data,num_slices=num_slices_current,use_GPU=use_GPU)
            predicted_labels = reshape(predicted,:)
            # Return result
            put!(data_channel,(l,predicted_labels))
        end
    end
    return nothing
end

function adjust_size(input_data::Array{Float32,4},input_size::NTuple{2,Int64})
    s = size(input_data)
    s12 = s[1:2]
    r = s12./input_size
    change_size = !all(floor.(r).==r)
    if change_size
        new_s = convert.(Int64,ceil.(r).*input_size)
        new_data = zeros(Float32,(new_s...,size(input_data)[3:4]...))
        new_data[1:s[1],1:s[2],1:s[3],s[4]] = input_data
        input_data = new_data
    end
    return input_data,change_size,s
end

function get_output(model_data::ModelData,classes::Vector{ImageSegmentationClass},processing::ProcessingTraining,
        num::Int64,urls_batched::Vector{Vector{Vector{String}}},num_slices_current::Int64,use_GPU::Bool,
        data_channel::Channel{Tuple{Int64,BitArray{4}}},channels::Channels)
    for k = 1:num
        urls_batch = urls_batched[k]
        num_batch = length(urls_batch)
        for l = 1:num_batch
            # Stop if asked
            if check_abort_signal(channels.application_modifiers)
                return
            end
            # Get input
            input_data = prepare_application_data(model_data,classes,urls_batch[l],processing)
            # Adjust input size if required to avoid incorrect size of output 
            input_data,change_size,s = adjust_size(input_data,model_data.input_size[1:2])
            # Get output
            predicted = forward(model_data.model,input_data,num_slices=num_slices_current,use_GPU=use_GPU)
            if change_size
                predicted = predicted[1:s[1],1:s[2],:,:]
            end
            predicted_bool = predicted.>0.5
            # Return result
            put!(data_channel,(l,predicted_bool))
        end
    end
    return nothing
end

function run_iteration(classes::Vector{ImageSegmentationClass},output_options::Vector{ImageSegmentationOutputOptions},
        savepath::String,filenames_batch::Vector{Vector{String}},num_classes::Int64,num_border::Int64,
        labels_color::Vector{Vector{Float64}},labels_incl::Vector{Vector{Int64}},apply_border::Bool,border::Vector{Bool},
        objs_area::Vector{Vector{Vector{Float64}}},objs_volume::Vector{Vector{Vector{Float64}}},img_ext::String,
        img_sym_ext::Symbol,scaling::Float64,apply_by_file::Bool,data_taken::Threads.Atomic{Bool},
        data_channel::Channel{Tuple{Int64,BitArray{4}}},channels::Channels)
    # Get neural network output
    l,predicted_bool = take!(data_channel)
    Threads.atomic_xchg!(data_taken, true)
    size_dim4 = size(predicted_bool,4)
    # Flatten and use border info if present
    masks = Vector{BitArray{3}}(undef,size_dim4)
    for j = 1:size_dim4
        temp_mask = predicted_bool[:,:,:,j]
        if apply_border
            border_mask = apply_border_data(temp_mask,classes)
            temp_mask = cat3(temp_mask,border_mask)
        end
        for i=1:num_classes
            min_area = classes[i].min_area
            if min_area>1
                if border[i]
                    ind = i + num_classes + num_border
                else
                    ind = i
                end
                temp_array = temp_mask[:,:,ind]
                # Fix areaopen not removing all objects less than min area
                for _ = 1:2
                    areaopen!(temp_array,min_area)
                end
                temp_mask[:,:,ind] .= temp_array
            end
        end
        masks[j] = temp_mask
    end
    # Stop if asked
    if check_abort_signal(channels.application_modifiers)
        return nothing
    end
    filenames = filenames_batch[l]
    cnt = sum(length.(filenames_batch[1:l-1]))
    for j = 1:length(masks)
        if apply_by_file
            cnt = cnt + 1
        else
            cnt = 1
        end
        filename = filenames[j]
        mask = masks[j]
        # Make and export images
        mask_to_img(mask,classes,output_options,labels_color,border,savepath,filename,img_ext,img_sym_ext)
        # Make data out of masks
        mask_to_data(objs_area,objs_volume,cnt,mask,output_options,labels_incl,border,
            num_classes,num_border,scaling)
    end
    put!(channels.application_progress,1)
end

function process_output(classes::Vector{ImageClassificationClass},output_options::Vector{ImageClassificationOutputOptions},
        savepath_main::String,folders::Vector{String},filenames_batched::Vector{Vector{Vector{String}}},num::Int64,
        img_ext::String,img_sym_ext::Symbol,data_ext::String,data_sym_ext::Symbol,scaling::Float64,apply_by_file::Bool,
        data_channel::Channel{Tuple{Int64,Vector{Int64}}},channels::Channels)
    class_names = map(x -> x.name,classes)
    for k=1:num
        folder = folders[k]
        filenames_batch = filenames_batched[k]
        num_batch = length(filenames_batch)
        savepath = joinpath(savepath_main,folder)
        if !isdir(savepath)
            mkdir(savepath)
        end
        # Initialize accumulators
        labels = Vector{String}(undef,0)
        data_taken = Threads.Atomic{Bool}(true)
        for _ = 1:num_batch
            while true
                if isready(data_channel) && data_taken[]==true
                    Threads.atomic_xchg!(data_taken, false)
                    break
                else
                    # Stop if asked
                    if check_abort_signal(channels.application_modifiers)
                        return nothing
                    end
                    sleep(0.1)
                end
            end
            # Get neural network output
            _, label_inds = take!(data_channel)
            Threads.atomic_xchg!(data_taken, true)
            for j = 1:length(label_inds)
                label_ind = label_inds[j]
                push!(labels,class_names[label_ind])
            end
            put!(channels.application_progress,1)
        end
        # Export the result
        filenames = reduce(vcat,filenames_batch)
        df_filenames = DataFrame(Filenames=filenames)
        df_labels = DataFrame(Labels = labels)
        df = hcat(df_filenames,df_labels)
        name = string(folder,data_ext)
        save(df,savepath,name,data_sym_ext)
        put!(channels.application_progress,1)
    end
    return nothing
end

function process_output(classes::Vector{ImageRegressionClass},output_options::Vector{ImageRegressionOutputOptions},
        savepath_main::String,folders::Vector{String},filenames_batched::Vector{Vector{Vector{String}}},num::Int64,
        img_ext::String,img_sym_ext::Symbol,data_ext::String,data_sym_ext::Symbol,scaling::Float64,apply_by_file::Bool,
        data_channel::Channel{Tuple{Int64,Vector{Float32}}},channels::Channels)
    class_names = map(x -> x.name,classes)
    for k=1:num
        folder = folders[k]
        filenames_batch = filenames_batched[k]
        num_batch = length(filenames_batch)
        savepath = joinpath(savepath_main,folder)
        if !isdir(savepath)
            mkdir(savepath)
        end
        # Initialize accumulators
        labels_accum = Vector{Vector{Float32}}(undef,0)
        data_taken = Threads.Atomic{Bool}(true)
        for _ = 1:num_batch
            while true
                if isready(data_channel) && data_taken[]==true
                    Threads.atomic_xchg!(data_taken, false)
                    break
                else
                    # Stop if asked
                    if check_abort_signal(channels.application_modifiers)
                        return nothing
                    end
                    sleep(0.1)
                end
            end
            # Get neural network output
            _, label = take!(data_channel)
            Threads.atomic_xchg!(data_taken, true)
            push!(labels_accum,label)
            put!(channels.application_progress,1)
        end
        labels_temp = reduce(vcat,labels_accum)
        if length(classes)==1
            labels = convert(Array{Float64,2},reshape(labels_temp,:,1))
        else
            labels = convert(Array{Float64,2},labels_temp)
        end
        # Export the result
        filenames = reduce(vcat,filenames_batch)
        df_filenames = DataFrame(Filenames=filenames)
        df_labels = DataFrame(labels,class_names)
        df = hcat(df_filenames,df_labels)
        name = string(folder,data_ext)
        save(df,savepath,name,data_sym_ext)
        put!(channels.application_progress,1)
    end
    return nothing
end

function process_output(classes::Vector{ImageSegmentationClass},output_options::Vector{ImageSegmentationOutputOptions},
        savepath_main::String,folders::Vector{String},filenames_batched::Vector{Vector{Vector{String}}},num::Int64,
        num_border::Int64,labels_color::Vector{Vector{Float64}},labels_incl::Vector{Vector{Int64}},apply_border::Bool,
        border::Vector{Bool},log_area_obj::Vector{Bool},log_area_obj_sum::Vector{Bool},log_area_dist::Vector{Bool},
        log_volume_obj::Vector{Bool},log_volume_obj_sum::Vector{Bool},log_volume_dist::Vector{Bool},num_obj_area::Int64,
        num_obj_area_sum::Int64,num_dist_area::Int64,num_obj_volume::Int64,num_obj_volume_sum::Int64,num_dist_volume::Int64,
        img_ext::String,img_sym_ext::Symbol,data_ext::String,data_sym_ext::Symbol,scaling::Float64,apply_by_file::Bool,
        data_channel::Channel{Tuple{Int64,BitArray{4}}},channels::Channels)
    num_classes = length(classes)
    for k=1:num
        folder = folders[k]
        filenames_batch = filenames_batched[k]
        num_batch = length(filenames_batch)
        savepath = joinpath(savepath_main,folder)
        if !isdir(savepath)
            mkdir(savepath)
        end
        # Initialize accumulators
        if apply_by_file
            num_init = num_batch
        else
            num_init = 1
        end
        objs_area = Vector{Vector{Vector{Float64}}}(undef,num_init)
        objs_volume = Vector{Vector{Vector{Float64}}}(undef,num_init)
        objs_area_sum = Vector{Vector{Float64}}(undef,num_init)
        objs_volume_sum = Vector{Vector{Float64}}(undef,num_init)
        histograms_area = Vector{Vector{Histogram}}(undef,num_init)
        histograms_volume = Vector{Vector{Histogram}}(undef,num_init)
        fill_no_ref!(objs_area,Vector{Vector{Float64}}(undef,num_classes))
        for i = 1:num_init
            fill_no_ref!(objs_area[i],Float64[])
        end
        fill_no_ref!(objs_volume,Vector{Vector{Float64}}(undef,num_classes))
        for i = 1:num_init
            fill_no_ref!(objs_volume[i],Float64[])
        end
        fill_no_ref!(objs_area_sum,Vector{Float64}(undef,num_obj_area_sum))
        fill_no_ref!(objs_volume_sum,Vector{Float64}(undef,num_obj_volume_sum))
        fill_no_ref!(histograms_area,Vector{Histogram}(undef,num_dist_area))
        fill_no_ref!(histograms_volume,Vector{Histogram}(undef,num_dist_volume))
        tasks = Vector{Task}(undef,0)
        data_taken = Threads.Atomic{Bool}(true)
        for _ = 1:num_batch
            while true
                if isready(data_channel) && data_taken[]==true
                    Threads.atomic_xchg!(data_taken, false)
                    break
                else
                    # Stop if asked
                    if check_abort_signal(channels.application_modifiers)
                        return nothing
                    end
                    sleep(0.1)
                end
            end
            t = Threads.@spawn run_iteration(classes,output_options,savepath,filenames_batch,num_classes,
                num_border,labels_color,labels_incl,apply_border,border,objs_area,objs_volume,img_ext,
                img_sym_ext,scaling,apply_by_file,data_taken,data_channel,channels)
            push!(tasks,t)
        end
        while length(tasks)!=num_batch
            sleep(1)
        end
        while !all(istaskdone.(tasks))
            sleep(1)
        end
        if num_obj_area_sum>0 
            for i = 1:num_init
                for j = 1:num_classes
                    if output_options[j].Area.obj_area_sum
                        objs_area_sum[i][j] = sum(objs_area[i][j])
                    end
                end
            end
        end
        if num_obj_volume_sum>0 
            for i = 1:num_init
                for j = 1:num_classes
                    if output_options[j].Volume.obj_volume_sum
                        objs_volume_sum[i][j] = sum(objs_volume[i][j])
                    end
                end
            end
        end
        data_to_histograms(histograms_area,histograms_volume,objs_area,objs_volume,
        output_options,num_init,num_classes,num_border,border)
        # Export data
        if apply_by_file
            filenames = reduce(vcat,filenames_batch)
        else
            filenames = [folder]
        end
        export_histograms(histograms_area,histograms_volume,classes,num_init,num_dist_area,
            num_dist_volume,log_area_dist,log_volume_dist,
            savepath,filenames,data_ext,data_sym_ext)
        export_objs("Objects",objs_area,objs_volume,classes,num_init,num_obj_area,
            num_obj_volume,log_area_obj,log_volume_obj,
            savepath,filenames,data_ext,data_sym_ext)
        export_objs("Objects sum",objs_area_sum,objs_volume_sum,classes,num_init,num_obj_area_sum,
            num_obj_volume_sum,log_area_obj_sum,log_volume_obj_sum,
            savepath,filenames,data_ext,data_sym_ext)
        put!(channels.application_progress,1)
    end
    return nothing
end

function get_output_info(classes::Vector{ImageClassificationClass},output_options::Vector{ImageClassificationOutputOptions})
    num_classes = length(classes)
    return classes,()
end

function get_output_info(classes::Vector{ImageRegressionClass},output_options::Vector{ImageRegressionOutputOptions})
    num_classes = length(classes)
    return classes,()
end

function get_output_info(classes::Vector{ImageSegmentationClass},output_options::Vector{ImageSegmentationOutputOptions})
    class_inds,labels_color,labels_incl,border = get_class_data(classes)
    classes = classes[class_inds]
    num_classes = length(classes)
    labels_color = labels_color[class_inds]
    labels_incl = labels_incl[class_inds]
    num_classes = length(classes)
    num_border = sum(border)
    apply_border = num_border>0
    log_area_obj = map(x->x.Area.obj_area,output_options)
    log_area_obj_sum = map(x->x.Area.obj_area_sum,output_options)
    log_area_dist = map(x->x.Area.area_distribution,output_options)
    log_volume_obj = map(x->x.Volume.obj_volume,output_options)
    log_volume_obj_sum = map(x->x.Volume.obj_volume_sum,output_options)
    log_volume_dist = map(x->x.Volume.volume_distribution,output_options)
    num_obj_area = count(log_area_obj)
    num_obj_area_sum = count(log_area_obj_sum)
    num_dist_area = count(log_area_dist)
    num_obj_volume = count(log_volume_obj)
    num_obj_volume_sum = count(log_volume_obj_sum)
    num_dist_volume = count(log_volume_dist)
    return classes,(num_border,labels_color,labels_incl,apply_border,border,
        log_area_obj,log_area_obj_sum,log_area_dist,log_volume_obj,
        log_volume_obj_sum,log_volume_dist,num_obj_area,num_obj_area_sum,
        num_dist_area,num_obj_volume,num_obj_volume_sum,num_dist_volume)
end

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
    if options.binning==0
        h = fit(Histogram, values)
    elseif options.binning==1
        maxval = maximum(values)
        minval = minimum(values)
        dif = maxval-minval
        step = dif/(options.value-1)
        bins = minval:step:maxval
        h = fit(Histogram, values,bins)
    else
        num = round(maximum(values)/options.value)
        h = fit(Histogram, values, nbins=num)
    end
    if options.normalisation==0
        h = normalize(h, mode=:pdf)
    elseif options.normalisation==1
        h = normalize(h, mode=:density)
    elseif options.normalisation==2
        h = normalize(h, mode=:probability)
    else
        h = normalize(h, mode=:none)
    end
    return h
end

function export_histograms(histograms_area::Vector{Vector{Histogram}},
        histograms_volume::Vector{Vector{Histogram}},classes::Vector{ImageSegmentationClass},num::Int64,
        num_dist_area::Int64,num_dist_volume::Int64,
        log_area_dist::Vector{Bool},log_volume_dist::Vector{Bool},savepath::String,
        filenames::Vector{String},data_ext::String,data_sym_ext::Symbol)
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
        name = string("Distributions ",fname,data_ext)
        save(df_dists,savepath,name,data_sym_ext)
    end
    return nothing
end

function export_objs(type_name::String,objs_area::Vector,
        objs_volume::Vector,classes::Vector{ImageSegmentationClass},
        num::Int64,num_obj_area::Int64,num_obj_volume::Int64,
        log_area_obj::Vector{Bool},log_volume_obj::Vector{Bool},savepath::String,
        filenames::Vector{String},data_ext::String,data_sym_ext::Symbol)
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
        name = string(type_name," ",fname,data_ext)
        save(df_objs,savepath,name,data_sym_ext)
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
function get_data_ext(ind)
    ext = [".csv",".xlsx",".json",".bson"]
    ext_symbol = [:csv,:xlsx,:json,:bson]
    return ext[ind+1],ext_symbol[ind+1]
end

function get_image_ext(ind)
    ext = [".png",".tiff",".bson"]
    ext_symbol = [:png,:tiff,:bson]
    return ext[ind+1],ext_symbol[ind+1]
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
            JSON.print(f,data)
        end
    elseif ext==:bson
        BSON.@save(url,data)
    elseif ext==:xlsx
        XLSX.writetable(url, collect(DataFrames.eachcol(data)), DataFrames.names(data))
    else
        FileIO.save(url,data)
    end
end

"""
    remove_application_data()

Removes all application data.
"""
function remove_application_data()
    data = application_data
    fields = fieldnames(ApplicationData)
    for field in fields
        data_field = getfield(data, field)
        if data_field isa Array
            empty!(data_field)
        end
    end
end

# Main function that performs application
function apply_main(settings::Settings,training::Training,application_data::ApplicationData,
        model_data::ModelData,T::DataType,channels::Channels)
    # Initialize constants
    application = settings.Application
    application_options = application.Options
    processing = training.Options.Processing
    classes = model_data.classes
    output_options = model_data.OutputOptions
    use_GPU = false
    if training.Options.General.allow_GPU
        if has_cuda()
            use_GPU = true
        else
            @warn "No CUDA capable device was detected. Using CPU instead."
        end
    end
    scaling = application_options.scaling
    batch_size = application_options.minibatch_size
    apply_by_file = application_options.apply_by[1]=="file"
    data_channel = Channel{Tuple{Int64,T}}(Inf)
    # Get file extensions
    img_ext,img_sym_ext = get_image_ext(application_options.image_type)
    data_ext,data_sym_ext = get_data_ext(application_options.data_type)
    # Get folders and names
    folders = application_data.folders
    num = length(folders)
    urls = application_data.input_urls
    urls_batched,filenames_batched = batch_urls_filenames(urls,batch_size)
    # Get savepath directory
    savepath_main = application_options.savepath
    if isempty(savepath_main)
        savepath_main = string(pwd(),"/Output data/")
    end
    # Make savepath directory if does not exist
    make_dir(savepath_main)
    # Send number of iterations
    put!(channels.application_progress,sum(length.(urls_batched)))
    # Output information
    classes,output_info = get_output_info(classes,output_options)
    # Prepare output
    if settings.problem_type==:Classification || settings.problem_type==:Regression
        num_slices_current = 1
    else
        num_slices_current = 30
    end
    t = Threads.@spawn get_output(model_data,classes,processing,num,
        urls_batched,num_slices_current,use_GPU,data_channel,channels)
    push!(application_data.tasks,t)
    # Process output and save data
    process_output(classes,output_options,savepath_main,folders,filenames_batched,num,output_info...,
        img_ext,img_sym_ext,data_ext,data_sym_ext,scaling,apply_by_file,data_channel,channels)
    return nothing
end
function apply_main2(settings::Settings,training::Training,application_data::ApplicationData,
        model_data::ModelData,channels::Channels)
    if settings.problem_type==:Classification
        T = Vector{Int64}
    elseif settings.problem_type==:Regression
        T = Vector{Float32}
    elseif settings.problem_type==:Segmentation
        T = BitArray{4}
    end
    t = Threads.@spawn apply_main(settings,training,application_data,model_data,T,channels)
    push!(application_data.tasks,t)
end