
function fix_slashes(url)
    url::String = fix_QML_types(url)
    url = replace(url, "\\" => "/")
    url = string(uppercase(url[1]),url[2:end])
end

# Works as fill!, but does not use a reference
function fill_no_ref!(target::AbstractArray,el)
    for i = 1:length(target)
        target[i] = copy(el)
    end
end

# Allows to read class output options from GUI
function get_output_main(model_data::ModelData,fields,ind)
    fields::Vector{String} = fix_QML_types(fields)
    ind::Int64 = fix_QML_types(ind)
    data = model_data.output_options[ind]
    for i = 1:length(fields)
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    if data isa Symbol
        return string(data)
    else
        return data
    end 
end
get_output(fields,ind) = get_output_main(model_data,fields,ind)

# Allows to write to class output options from GUI
function set_output_main(model_data::ModelData,fields,ind,value)
    fields::Vector{String} = fix_QML_types(fields)
    ind::Int64 = fix_QML_types(ind)
    value = fix_QML_types(value)
    data = model_data.output_options[ind]
    for i = 1:length(fields)-1
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    if getproperty(data, Symbol(fields[end])) isa Symbol
        setproperty!(data, Symbol(fields[end]), Symbol(value))
    else
        setproperty!(data, Symbol(fields[end]), value)
    end
    return nothing
end
set_output(fields,ind,value) = set_output_main(model_data,fields,ind,value)


# Get urls of files in a selected folder. Files are used for application.
function get_urls_application_main(application_data::ApplicationData)
    if input_type()==:image
        allowed_ext = ["png","jpg","jpeg"]
    end
    input_urls,dirs = get_urls1(application_data.url_inputs,allowed_ext)
    application_data.input_urls = input_urls
    application_data.folders = dirs
    return nothing
end

function prepare_application_data(norm_func::Function,classes::Vector{ImageClassificationClass},
        model_data::ModelData,urls::Vector{String})
    num = length(urls)
    data = Vector{Array{Float32,4}}(undef,length(urls))
    for i = 1:num
        url = urls[i]
        image = load_image(url)
        if :grayscale in model_data.input_properties
            data[i] = image_to_gray_float(image)[:,:,:,:]
        else
            data[i] = image_to_color_float(image)[:,:,:,:]
        end
        norm_func(data[i])
    end
    data_out = cat(data...,dims=Val(4))
    return data_out
end

function prepare_application_data(norm_func::Function,classes::Vector{ImageRegressionClass},
        model_data::ModelData,urls::Vector{String})
    num = length(urls)
    data = Vector{Array{Float32,4}}(undef,length(urls))
    for i = 1:num
        url = urls[i]
        image = load_image(url)
        image = imresize(image,model_data.input_size[1:2])
        if :grayscale in model_data.input_properties
            data[i] = image_to_gray_float(image)[:,:,:,:]
        else
            data[i] = image_to_color_float(image)[:,:,:,:]
        end
        norm_func(data[i])
    end
    data_out = cat(data...,dims=Val(4))
    return data_out
end

function prepare_application_data(norm_func::Function,classes::Vector{ImageSegmentationClass},
        model_data::ModelData,urls::Vector{String})
    num = length(urls)
    data = Vector{Array{Float32,4}}(undef,length(urls))
    for i = 1:num
        url = urls[i]
        image = load_image(url)
        if :grayscale in model_data.input_properties
            data[i] = image_to_gray_float(image)[:,:,:,:]
        else
            data[i] = image_to_color_float(image)[:,:,:,:]
        end
        norm_func(data[i])
    end
    data_out = cat(data...,dims=Val(4))
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

function get_output(norm_func::Function,classes::Vector{ImageClassificationClass},num::Int64,
    urls_batched::Vector{Vector{Vector{String}}},model_data::ModelData,
    num_slices_val::Int64,offset_val::Int64,use_GPU::Bool,
    data_channel::Channel{Tuple{Int64,Vector{Int64}}},channels::Channels)
    for k = 1:num
        urls_batch = urls_batched[k]
        num_batch = length(urls_batch)
        for l = 1:num_batch
            # Stop if asked
            #=if check_abort_signal(channels.application_modifiers)
                return nothing
            end=#
            # Get input
            input_data = prepare_application_data(norm_func,classes,model_data,urls_batch[l])
            # Get output
            predicted = forward(model_data.model,input_data,
                num_slices=num_slices_val,offset=offset_val,use_GPU=use_GPU)
            _, predicted_labels4 = findmax(predicted,dims=1)
            predicted_labels = map(x-> x.I[1],predicted_labels4[:])
            # Return result
            put!(data_channel,(l,predicted_labels))
        end
    end
    return nothing
end

function get_output(norm_func::Function,classes::Vector{ImageRegressionClass},num::Int64,
        urls_batched::Vector{Vector{Vector{String}}},model_data::ModelData,
        num_slices_val::Int64,offset_val::Int64,use_GPU::Bool,
        data_channel::Channel{Tuple{Int64,Vector{Float32}}},channels::Channels)
    for k = 1:num
        urls_batch = urls_batched[k]
        num_batch = length(urls_batch)
        for l = 1:num_batch
            # Stop if asked
            #=if check_abort_signal(channels.application_modifiers)
                return nothing
            end=#
            # Get input
            input_data = prepare_application_data(norm_func,classes,model_data,urls_batch[l])
            # Get output
            predicted = forward(model_data.model,input_data,
                num_slices=num_slices_val,offset=offset_val,use_GPU=use_GPU)
            predicted_labels = reshape(predicted,:)
            # Return result
            put!(data_channel,(l,predicted_labels))
        end
    end
    return nothing
end

function get_output(norm_func::Function,classes::Vector{ImageSegmentationClass},num::Int64,
        urls_batched::Vector{Vector{Vector{String}}},model_data::ModelData,
        num_slices_val::Int64,offset_val::Int64,use_GPU::Bool,
        data_channel::Channel{Tuple{Int64,BitArray{4}}},channels::Channels)
    for k = 1:num
        urls_batch = urls_batched[k]
        num_batch = length(urls_batch)
        for l = 1:num_batch
            # Stop if asked
            #=if check_abort_signal(channels.application_modifiers)
                return
            end=#
            # Get input
            input_data = prepare_application_data(norm_func,classes,model_data,urls_batch[l])
            # Get output
            predicted = forward(model_data.model,input_data,
                num_slices=num_slices_val,offset=offset_val,use_GPU=use_GPU)
            predicted_bool = predicted.>0.5
            # Return result
            put!(data_channel,(l,predicted_bool))
        end
    end
    return nothing
end

function run_iteration(classes::Vector{ImageSegmentationClass},output_options::Vector{ImageSegmentationOutputOptions},
        savepath::String,filenames_batch::Vector{Vector{String}},num_c::Int64,num_border::Int64,
        labels_color::Vector{Vector{Float64}},labels_incl::Vector{Vector{Int64}},apply_border::Bool,border::Vector{Bool},
        objs_area::Vector{Vector{Vector{Float64}}},objs_volume::Vector{Vector{Vector{Float64}}},img_ext_string::String,
        img_ext::Symbol,scaling::Float64,apply_by_file::Bool,data_taken::Threads.Atomic{Bool},
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
            temp_mask = cat(temp_mask,border_mask,dims=Val(3))
        end
        for i=1:num_c
            min_area = classes[i].min_area
            if min_area>1
                if border[i]
                    ind = i + num_c + num_border
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
    #=if check_abort_signal(channels.application_modifiers)
        return nothing
    end=#
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
        mask_to_img(mask,classes,output_options,labels_color,border,savepath,filename,img_ext_string,img_ext)
        # Make data out of masks
        mask_to_data(objs_area,objs_volume,cnt,mask,output_options,labels_incl,border,
            num_c,num_border,scaling)
    end
    put!(channels.application_progress,1)
end

function process_output(classes::Vector{ImageClassificationClass},output_options::Vector{ImageClassificationOutputOptions},
        savepath_main::String,folders::Vector{String},filenames_batched::Vector{Vector{Vector{String}}},num::Int64,
        img_ext_string::String,img_ext::Symbol,data_ext_string::String,data_ext::Symbol,
        scaling::Float64,apply_by_file::Bool,data_channel::Channel{Tuple{Int64,Vector{Int64}}},channels::Channels)
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
                    #=if check_abort_signal(channels.application_modifiers)
                        return nothing
                    end=#
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
        name = string(folder,data_ext_string)
        save(df,savepath,name,data_ext)
        put!(channels.application_progress,1)
    end
    return nothing
end

function process_output(classes::Vector{ImageRegressionClass},output_options::Vector{ImageRegressionOutputOptions},
        savepath_main::String,folders::Vector{String},filenames_batched::Vector{Vector{Vector{String}}},num::Int64,
        img_ext_string::String,img_ext::Symbol,data_ext_string::String,data_ext::Symbol,
        scaling::Float64,apply_by_file::Bool,data_channel::Channel{Tuple{Int64,Vector{Float32}}},channels::Channels)
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
                    #=if check_abort_signal(channels.application_modifiers)
                        return nothing
                    end=#
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
        name = string(folder,data_ext_string)
        save(df,savepath,name,data_ext)
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
        img_ext_string::String,img_ext::Symbol,data_ext_string::String,data_ext::Symbol,
        scaling::Float64,apply_by_file::Bool,data_channel::Channel{Tuple{Int64,BitArray{4}}},channels::Channels)
    num_c = length(classes)
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
        fill_no_ref!(objs_area,Vector{Vector{Float64}}(undef,num_c))
        for i = 1:num_init
            fill_no_ref!(objs_area[i],Float64[])
        end
        fill_no_ref!(objs_volume,Vector{Vector{Float64}}(undef,num_c))
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
                    #=if check_abort_signal(channels.application_modifiers)
                        return nothing
                    end=#
                    sleep(0.1)
                end
            end
            t = Threads.@spawn run_iteration(classes,output_options,savepath,filenames_batch,num_c,
                num_border,labels_color,labels_incl,apply_border,border,objs_area,objs_volume,img_ext_string,
                img_ext,scaling,apply_by_file,data_taken,data_channel,channels)
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
                for j = 1:num_c
                    if output_options[j].Area.obj_area_sum
                        objs_area_sum[i][j] = sum(objs_area[i][j])
                    end
                end
            end
        end
        if num_obj_volume_sum>0 
            for i = 1:num_init
                for j = 1:num_c
                    if output_options[j].Volume.obj_volume_sum
                        objs_volume_sum[i][j] = sum(objs_volume[i][j])
                    end
                end
            end
        end
        data_to_histograms(histograms_area,histograms_volume,objs_area,objs_volume,
        output_options,num_init,num_c,num_border,border)
        # Export data
        if apply_by_file
            filenames = reduce(vcat,filenames_batch)
        else
            filenames = [folder]
        end
        export_histograms(histograms_area,histograms_volume,classes,num_init,num_dist_area,
            num_dist_volume,log_area_dist,log_volume_dist,
            savepath,filenames,data_ext_string,data_ext)
        export_objs("Objects",objs_area,objs_volume,classes,num_init,num_obj_area,
            num_obj_volume,log_area_obj,log_volume_obj,
            savepath,filenames,data_ext_string,data_ext)
        export_objs("Objects sum",objs_area_sum,objs_volume_sum,classes,num_init,num_obj_area_sum,
            num_obj_volume_sum,log_area_obj_sum,log_volume_obj_sum,
            savepath,filenames,data_ext_string,data_ext)
        put!(channels.application_progress,1)
    end
    return nothing
end

function get_output_info(classes::Vector{ImageClassificationClass},output_options::Vector{ImageClassificationOutputOptions})
    return classes,()
end

function get_output_info(classes::Vector{ImageRegressionClass},output_options::Vector{ImageRegressionOutputOptions})
    return classes,()
end

function get_output_info(classes::Vector{ImageSegmentationClass},output_options::Vector{ImageSegmentationOutputOptions})
    class_inds,labels_color,labels_incl,border = get_class_data(classes)
    classes = classes[class_inds]
    labels_color = labels_color[class_inds]
    labels_incl = labels_incl[class_inds]
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

function fix_output_options(model_data)
    if problem_type()==:classification
        model_data.output_options = ImageClassificationOutputOptions[]
    elseif problem_type()==:regression
        model_data.output_options = ImageRegressionOutputOptions[]
    end
    return nothing
end

# Main function that performs application
function apply_main(T::DataType,model_data::ModelData,all_data::AllData,options::Options,channels::Channels)
    # Initialize constants
    application_data = all_data.ApplicationData
    application_options = options.ApplicationOptions
    classes = model_data.classes
    output_options = model_data.output_options
    use_GPU = false
    if options.GlobalOptions.HardwareResources.allow_GPU
        if has_cuda()
            use_GPU = true
        else
            @warn "No CUDA capable device was detected. Using CPU instead."
        end
    end
    scaling = application_options.scaling
    batch_size = 1
    apply_by_file = application_options.apply_by==:file
    if problem_type()==:classification
        T = Vector{Int64}
    elseif problem_type()==:regression
        T = Vector{Float32}
    elseif problem_type()==:segmentation
        T = BitArray{4}
    end
    data_channel = Channel{Tuple{Int64,T}}(Inf)
    # Get file extensions
    img_ext,img_ext_string = get_image_ext(application_options.image_type)
    data_ext,data_ext_string = get_data_ext(application_options.data_type)
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
    mkpath(savepath_main)
    # Send number of iterations
    put!(channels.application_progress,num+sum(length.(urls_batched)))
    # Output information
    fix_output_options(model_data)
    classes,output_info = get_output_info(classes,output_options)
    # Prepare output
    if problem_type()==:segmentation
        num_slices_val = options.GlobalOptions.HardwareResources.num_slices
        offset_val = options.GlobalOptions.HardwareResources.offset
    else
        num_slices_val = 1
        offset_val = 0
    end
    normalization = model_data.normalization
    norm_func(x) = model_data.normalization.f(x,normalization.args...)
    t = Threads.@spawn get_output(norm_func,classes,num,urls_batched,model_data,
        num_slices_val,offset_val,use_GPU,data_channel,channels)
    push!(application_data.tasks,t)
    # Process output and save data
    process_output(classes,output_options,savepath_main,folders,filenames_batched,num,output_info...,
        img_ext_string,img_ext,data_ext_string,data_ext,scaling,apply_by_file,data_channel,channels)
    return nothing
end
function apply_main2(model_data::ModelData,all_data::AllData,options::Options,channels::Channels)
    t = Threads.@spawn apply_main(T,model_data,all_data,options,channels)
    push!(application_data.tasks,t)
    return t
end