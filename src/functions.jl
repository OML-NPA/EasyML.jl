
#---Model saving/loading--------------------------------------------

"""
    save_model(url::String)

Saves a model to a specified URL. The URL can be absolute or relative. 
Use '.model' extension.
"""
function save_model(url::AbstractString)
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

"""
save_model()

Opens a file dialog where you can select where to save a model and how it should be called.
"""
function save_model()
    name_filters = ["*.model"]
    if isempty(all_data_urls.model_name)
        all_data_urls.model_name = "new_model"
    end
    filename = string(all_data_urls.model_name,".model")
    url_out = String[""]
    observe(url) = url_out[1] = url
    # Launch GUI
    @qmlfunction(observe,unit_test)
    path_qml = string(@__DIR__,"/gui/UniversalSaveFileDialog.qml")
    loadqml(path_qml,
        name_filters = name_filters,
        filename = filename)
    exec()
    if unit_test()
        url_out[1] = unit_test.url_pusher()
    end
    if !isempty(url_out[1])
        save_model(url_out[1])
    end
    return nothing
end

"""
    load_model(url::String)

Loads a model from a specified URL. The URL can be absolute or relative.
"""
function load_model(url::AbstractString)
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
                elseif deserialized isa String
                    setproperty!(model_data,k,eval(Meta.parse(deserialized)))
                else
                    setproperty!(model_data,k,deserialized)
                end
            catch e
                @warn string("Loading of ",k," failed.")  exception=(e, catch_backtrace())
            end
        end
    else
        # v0.1 partial compatibility
        dict_to_struct!(model_data,loaded_data)
    end
    all_data_urls.model_url = url
    url_split = split(url,('/','.'))
    all_data_urls.model_name = url_split[end-1]
    return nothing
end

"""
load_model()

Opens a file dialog where you can select a model to be loaded and loads it.
"""
function load_model()
    name_filters = ["*.model"]
    url_out = String[""]
    observe(url) = url_out[1] = url
    # Launch GUI
    @qmlfunction(observe,unit_test)
    path_qml = string(@__DIR__,"/gui/UniversalFileDialog.qml")
    loadqml(path_qml,name_filters = name_filters)
    exec()
    if unit_test()
        url_out[1] = unit_test.url_pusher()
    end
    # Load model
    if !isempty(url_out[1])
        load_model(url_out[1])
    end
    return nothing
end


#---Options saving/loading--------------------------------------------------

function save_options_main(options)
    dict = Dict{Symbol,Any}()
    struct_to_dict!(dict,options)
    BSON.@save("options.bson",dict)
    return nothing
end
save_options() = save_options_main(options)

function load_options_main(options)
    if isfile("options.bson")
        try
            data = BSON.load("options.bson")
            dict_to_struct!(options,data[:dict])
        catch e
            @error string("Options were not loaded. Error: ",e)
            save_options()
        end 
    else
        save_options()
    end
    return nothing
end
"""
    load_options()

Loads options from your previous run which are located in `options.bson`. 
Uses present working directory. It is run automatically after `using EasyML`.
"""
load_options() = load_options_main(options)


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
function get_data_main(data,fields::Vector{<:AbstractString},inds)
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
get_data(fields,inds=[]) = get_data_main(all_data,fields,inds)
get_options(fields,inds=[]) = get_data_main(options,fields,inds)

# Allows to write data from GUI
function set_data_main(data,fields::Vector{<:AbstractString},args)
    fields::Vector{String} = fix_QML_types(fields)
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

set_data(fields,args...) = set_data_main(all_data,fields,args)

set_options(fields,args...) = set_data_main(options,fields,args)

function get_folder(dir = "")
    url_out = String[""]
    observe() = url_out[1]
    @qmlfunction(observe,unit_test)
    path_qml = string(@__DIR__,"/gui/UniversalFolderDialog.qml")
    loadqml(path_qml,currentfolder = dir)
    exec()
    if unit_test()
        url_out[1] = unit_test.url_pusher()
    end
    return url_out[1]
end

function get_file(dir = "", name_filters = [])
    url_out = String[""]
    observe() = url_out[1]
    @qmlfunction(observe,unit_test)
    path_qml = string(@__DIR__,"/gui/UniversalFileDialog.qml")
    loadqml(path_qml,
        currentfolder = dir,
        name_filters = name_filters)
    exec()
    if unit_test()
        url_out[1] = unit_test.url_pusher()
    end
    return url_out[1]
end


#---Handling channels---------------------------------------------------------

# Return a value from progress channels without taking the value
function check_progress_main(channels,field::AbstractString)
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

# Return a value from progress channels by taking the value
function get_progress_main(channels,field::AbstractString)
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

function get_progress_main(channels,field::Symbol)
    channel = getfield(channels,field)
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

function empty_channel_main(channels,field::AbstractString)
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

function empty_channel_main(channels,field::Symbol)
    channel = getproperty(channels,field)
    while true
        if isready(channel)
            take!(channel)
        else
            return
        end
    end
end
empty_channel(field) = empty_channel_main(channels,field)

function put_channel_main(channels,field::AbstractString,value)
    field = fix_QML_types(field)
    value = fix_QML_types(value)
    field_sym = Symbol(field)
    channel = getfield(channels,field_sym)
    if value isa Vector
        value_raw::Vector{Float64} = fix_QML_types(value)
        value1 = convert(Int64,value_raw[1])
        value2 = convert(Float64,value_raw[2])
        value = (value1,value2)
    end
    put!(channel,value)
    return nothing
end
put_channel(field,value) = put_channel_main(channels,field,value)


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
            dict[k] = String(Symbol(value))
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


#---Other-------------------------------------------

problem_type() = model_data.problem_type

input_type() = model_data.input_type

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