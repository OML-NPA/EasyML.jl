
#---Model saving/loading--------------------------------------------

function save_model_main(model_data,url)
    url = fix_QML_types(url)
    # Make folders if needed
    if '\\' in url || '/' in url
        url_split = split(url,('/','\\'))[1:end-1]
        url_dir = reduce((x,y) -> join([x,y],'\\'),url_split)
        make_dir(url_dir)
    end
    # Serialize and save model
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
        error(string(url, " does not exist."))
        return nothing
    end
    fnames = fieldnames(ModelData)
    ks = collect(keys(loaded_data))
    ks = intersect(ks,fnames)
    k = :layers_info
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
        dict_to_struct!(model_data,loaded_data)
    end
    all_data.model_url = url
    url_split = split(url,('/','.'))
    all_data.model_name = url_split[end-1]
    return nothing
end


#---GUI data handling-----------------------------------------------------

# Convert QML types to Julia types
function fix_QML_types(var)
    if var isa AbstractString
        return String(var)
    elseif var isa Integer
        return Int64(var)
    elseif var isa AbstractFloat
        return Float64(var)
    elseif var isa QML.QListAllocated
        return fix_QML_types.(QML.value.(var))
    elseif var isa Tuple
        return fix_QML_types.(var)
    else
        return var
    end
end

# Allows to read data from GUI
function get_data_main(data::AllData,fields,inds)
    fields::Vector{String} = fix_QML_types(fields)
    inds = convert(Vector{Int64},fix_QML_types(inds))
    for i = 1:length(fields)
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    if !(isempty(inds))
        for i = 1:length(inds)
            data = data[inds[i]]
        end
    end
    if data isa Symbol
        data = string(data)
    end
    return data
end
get_data(fields,inds=[]) = get_data_main(all_data,fields,inds)

# Allows to write to data from GUI
function set_data_main(all_data::AllData,fields,args...)
    data = all_data
    fields::Vector{String} = fix_QML_types(fields)
    args = fix_QML_types(args)
    for i = 1:length(fields)-1
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    if length(args)==1
        value = args[1]
    elseif length(args)==2
        value = getproperty(data,Symbol(fields[end]))
        value[args[1]] = args[2]
    elseif length(args)==3
        value = getproperty(data,Symbol(fields[end]))
        value[args[1]][args[2]] = args[3]
    end
    field = Symbol(fields[end])
    if getproperty(data,field) isa Symbol
        data = Symbol(data)
    end
    setproperty!(data, field, value)
    return nothing
end
set_data(fields,value,args...) = set_data_main(all_data,fields,value,args...)

# Allows to read options from GUI
function get_options_main(data::Options,fields,inds...)
    fields::Vector{String} = fix_QML_types(fields)
    inds = fix_QML_types(inds)
    for i = 1:length(fields)
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    if !(isempty(inds))
        for i = 1:length(inds)
            data = data[inds[i]]
        end
    end
    if data isa Symbol
        data = string(data)
    end
    return data
end
get_options(fields,inds...) = get_options_main(options,fields,inds...)

# Allows to write to options from GUI
function set_options_main(options::Options,fields,args...)
    data = options
    fields = fix_QML_types(fields)
    args = fix_QML_types(args)
    for i = 1:length(fields)-1
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    if length(args)==1
        value = args[1]
    elseif length(args)==2
        value = getproperty(data,Symbol(fields[end]))
        if args[end]=="make_tuple"
            fun = args[2]
            value = make_tuple(args[1])
        else
            value[args[1]] = args[2]
        end
    elseif length(args)==3
        value = getproperty(data,Symbol(fields[end]))
        if args[end]=="make_tuple"
            fun = args[3]
            value[args[1]] = make_tuple(args[2])
        else
            value[args[1]][args[2]] = args[3]
        end
    elseif length(args)==4
        value = getproperty(data,Symbol(fields[end]))
        if args[end]=="make_tuple"
            fun = args[4]
            value[args[1]][args[2]] = make_tuple(args[3])
        else
            value[args[1]][args[2]][args[3]] = args[4]
        end
    end
    if typeof(getproperty(data, Symbol(fields[end])))==Symbol
        value = Symbol(value)
    end
    setproperty!(data, Symbol(fields[end]), value)
    return nothing
end
set_options(fields,value,args...) = set_options_main(options,fields,value,args...)


#---Struct related functions--------------------------------------------------

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

function to_struct!(obj,sym::Symbol,value::NamedTuple)
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
                to_struct!(obj,sym,value)
            else
                if hasfield(typeof(obj),sym)
                    setproperty!(obj,sym,value)
                end
            end
        end
    end
    return nothing
end

#---Other-------------------------------------------------------------

problem_type() = model_data.problem_type

input_type() = model_data.input_type

function make_dir(target_dir::AbstractString)
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
