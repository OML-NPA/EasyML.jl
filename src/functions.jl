
#---Binding----------------------------------------------

function Base.getproperty(obj::AbstractEasyML, sym::Symbol)
    value = getfield(obj, sym)
    if value isa Ref
        return value[]
    else
        return value
    end
end

function Base.setproperty!(obj::AbstractEasyML, sym::Symbol, x)
    value = getfield(obj,sym)
    if value isa Ref
        value[] = x
    else
        setfield!(obj,sym,x)
    end
    return nothing
end

function bind!(obj1,obj2)
    fields1 = fieldnames(typeof(obj1))
    fields2 = fieldnames(typeof(obj2))
    for field in fields1
        if field in fields2 && getfield(obj1,field) isa Ref
            setfield!(obj1,field,getfield(obj2,field))
        end
    end
end


#---Model saving/loading--------------------------------------------

function save_model(model_data,url)
    url = fix_QML_types(url)
    # Make folders if needed
    if '\\' in url || '/' in url
        url_split = split(url,('/','\\'))[1:end-1]
        url_dir = reduce((x,y) -> join([x,y],'/'),url_split)
        mkpath(url_dir)
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

function load_model(model_data,url,all_data_urls)
    url = fix_QML_types(url)
    if isfile(url)
        loaded_data = BSON.load(url)[:dict]
    else
        error(string(url, " does not exist."))
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
                elseif deserialized isa Vector
                    type = typeof(getproperty(model_data,k))
                    deserialized_typed = convert(type,deserialized)
                    setproperty!(model_data,k,deserialized_typed)
                elseif deserialized isa Symbol
                    setproperty!(model_data,k,eval(deserialized))
                else
                    setproperty!(model_data,k,deserialized)
                end
            catch e
                @warn string("Loading of ",k," failed.")  exception=(e, catch_backtrace())
            end
        end
    else
        dict_to_struct!(model_data,loaded_data)
    end
    all_data_urls.model_url = url
    url_split = split(url,('/','.'))
    all_data_urls.model_name = url_split[end-1]
    return nothing
end


#---Options saving/loading--------------------------------------------------

function save_options(options)
    dict = Dict{Symbol,Any}()
    struct_to_dict!(dict,options)
    BSON.@save("options.bson",dict)
    return nothing
end

function load_options(options)
    if isfile("options.bson")
        try
            data = BSON.load("options.bson")
            dict_to_struct!(options,data[:dict])
        catch e
            @error string("Options were not loaded. Error: ",e)
            save_options(options)
        end 
    else
        save_options(options)
    end
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
    else
        return var
    end
end

# Allows to read data from GUI
function get_data(data,fields,inds)
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

# Allows to read options from GUI
function get_options(data,fields,inds=[])
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

# Allows to write to options from GUI
function set_options(options,fields,args...)
    data = options
    fields = fix_QML_types(fields)
    field_end = Symbol(fields[end])
    args = fix_QML_types(args)
    for i = 1:length(fields)-1
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    if length(args)==1
        type = typeof(getproperty(data,field_end))
        value = type(args[1])
    elseif length(args)==2
        inds = args[1]
        value = getproperty(data,field_end)
        value_temp = value
        if !(isempty(inds))
            for i = 1:(length(inds)-1)
                value_temp = value_temp[inds[i]]
            end
        end
        type = typeof(value_temp[inds[end]])
        value_temp[inds[end]] = type(args[2])
    end
    setproperty!(data, field_end, value)
    return nothing
end


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
            data_tuple = (vector_type = string(type), types = string(types), values = dict_vec)
            dict[k] = data_tuple
        elseif value isa DataType
            dict[k] = Symbol(value)
        else
            dict[k] = value
        end
    end
    return nothing
end

function to_struct!(obj,sym::Symbol,value::NamedTuple)
    if !isempty(value)
        vector_type = eval(Meta.parse(getindex(value,:vector_type)))
        types = eval.(Meta.parse.(getindex(value,:types)))
        vals = getindex(value,:values) 
        struct_vec = vector_type(undef,0)
        for j = 1:length(types)
            obj_for_vec = types[j]()
            dict_for_vec = vals[j]
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
            if value isa Dict
                dict_to_struct!(obj_property,value)
            else
                setproperty!(obj,sym,value)
            end
        end
    end
    return nothing
end
