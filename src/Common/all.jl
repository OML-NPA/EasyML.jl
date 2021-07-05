
function check_abort_signal(channel::Channel)
    if isready(channel)
        value = fetch(channel)[1]
        if value==0
            return true
        else
            return false
        end
    else
        return false
    end
end

function set_data_type(type::Symbol)
    all_data.data_type = type
    return nothing
end

function set_problem_type(type::Symbol)
    all_data.problem_type = type
    return nothing
end

function set_problem_type(ind)
    ind = fix_QML_types(ind)
    if ind==0 
        all_data.problem_type = :Classification
    elseif ind==1
        all_data.problem_type = :Regression
    elseif ind==2
        all_data.problem_type = :Segmentation
    end
    return nothing
end

function get_problem_type()
    if problem_type()==:Classification
        return 0
    elseif problem_type()==:Regression
        return 1
    elseif problem_type()==:Segmentation
        return 2
    end
end

problem_type() = all_data.problem_type
input_type() = all_data.input_type


#---Model saving/loading--------------------------------------------

function save_model_main(model_data,url)
    url = fix_QML_types(url)
    dict_raw = Dict{Symbol,Any}()
    struct_to_dict!(dict_raw,model_data)
    dict = Dict{Symbol,IOBuffer}()
    ks = keys(dict_raw)
    vs = values(dict_raw)
    for (k,v) in zip(ks,vs)
        buffer = IOBuffer()
        d = Dict(:field => v)
        bson(buffer,d)
        dict[k] = buffer
    end
    BSON.@save(url,dict)
    return nothing
end

function load_model_main(model_data,url)
    url = fix_QML_types(url)
    if isfile(url)
        loaded_data = BSON.load(url)[:dict]
    else
        @error string(url, " does not exist.")
        return nothing
    end
    fnames = fieldnames(ModelData)
    ks = collect(keys(loaded_data))
    ks = intersect(ks,fnames)
    if loaded_data[ks[1]] isa IOBuffer
        for k in ks
            try
                serialized = seekstart(loaded_data[k])
                deserialized = BSON.load(serialized)[:field]
                if deserialized isa NamedTuple
                    to_struct!(model_data,k,deserialized)
                else
                    setfield!(model_data,k,deserialized)
                end
            catch e
                @warn string("Loading of ",k," failed. Exception: ",e)
            end
        end
    else
        to_struct!(model_data,loaded_data)
    end
    all_data.model_url = url
    url_split = split(url,('/','.'))
    all_data.model_name = url_split[end-1]
    return nothing
end

#---Channels---------------------------------------------------------------

# Return values from progress channels without taking the values
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

# Return values from progress channels by taking the values
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

#---
# Empties progress channels
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

# Empties results channels
function empty_results_channel_main(channels::Channels,field)
    field::String = fix_QML_types(field)
    field_sym = Symbol(field)
    channel = getfield(channels,field_sym)
    while true
        if isready(channel)
            take!(channel)
        else
            return nothing
        end
    end
end
empty_results_channel(field) = empty_results_channel_main(channels,field)

#---
# Puts data into modifiers channels
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


#------------------------------------------------------------------------

function empty_field!(str,field::Symbol)
    val = getfield(str,field)
    type = typeof(val)
    new_val = type(undef,zeros(Int64,length(size(val)))...)
    setfield!(str, field, new_val)
    return nothing
end

function data_length(fields,inds=[])
    return length(get_data(fields,inds))
end

#---Struct related functions
function struct_to_dict!(dict,obj)
    ks = fieldnames(typeof(obj))
    for k in ks
        value = getproperty(obj,k)
        type = typeof(value)
        if occursin("EasyML",string(parentmodule(type)))
            dict_current = Dict{Symbol,Any}()
            dict[k] = dict_current
            struct_to_dict!(dict_current,value)
        elseif value isa Vector && !isempty(value) && occursin("EasyML",string(parentmodule(eltype(type))))
            types = typeof.(value)
            dict_vec = Vector{Dict{Symbol,Any}}(undef,0)
            for obj_for_vec in value
                dict_for_vec = Dict{Symbol,Any}()
                struct_to_dict!(dict_for_vec,obj_for_vec)
                push!(dict_vec,dict_for_vec)
            end
            data_tuple = (vector_type = type, types = types, values = dict_vec)
            dict[k] = data_tuple
        else
            dict[k] = value
        end
    end
    return nothing
end

function dict_to_struct!(obj,dict::Dict)
    ks = [keys(dict)...]
    for i = 1:length(ks)
        ks_cur = ks[i]
        sym = Symbol(ks_cur)
        value = dict[ks_cur]
        if hasproperty(obj,sym)
            obj_property = getproperty(obj,sym)
            obj_type = typeof(obj_property)
            if value isa Dict
                dict_to_struct!(obj_property,value)
            elseif obj_property isa Vector && occursin("EasyML",string(parentmodule(eltype(obj_type))))
                if !isempty(value)
                    vector_type = getindex(value,:vector_type) 
                    types = getindex(value,:types) 
                    values = getindex(value,:values) 
                    struct_vec = vector_type(undef,0)
                    for j = 1:length(types)
                        obj_for_vec = types[j]()
                        dict_for_vec = values[j]
                        dict_to_struct!(obj_for_vec,dict_for_vec)
                        push!(struct_vec,obj_for_vec)
                    end
                    setproperty!(obj,sym,struct_vec)
                end
            else
                if hasfield(typeof(obj),sym)
                    setproperty!(obj,sym,value)
                end
            end
        end
    end
    return nothing
end

function make_tuple(array::AbstractArray)
    return (array...,)
end

function make_dir(target_dir::String)
    dirs = split(target_dir,('/','\\'))
    for i=1:length(dirs)
        temp_path = join(dirs[1:i],'\\')
        if !isdir(temp_path)
            mkdir(temp_path)
        end
    end
    if !isdir(target_dir)
        mkdir(target_dir)
    end
    return nothing
end

gc() = GC.gc()

function check_task(t::Task)
    if istaskdone(t)
        if t.:_isexception
            return :error, t.:result
        else
            return :done, nothing
        end
    else
        return :running, nothing
    end
end

add_dim(x::Array{T, N}) where {T,N} = reshape(x, Val(N+1))