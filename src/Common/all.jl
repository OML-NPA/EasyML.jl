
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

#---Model saving/loading
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
"""
    save_model(url::String)

Saves a model to a specified URL. The URL can be absolute or relative. 
Use '.model' extension.
"""
save_model(url) = save_model_main(model_data,url)

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
    return nothing
end
"""
    load_model(url::String)

Loads a model from a specified URL. The URL can be absolute or relative.
"""
load_model(url) = load_model_main(model_data,url)

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

problem_type() = all_data.problem_type
input_type() = all_data.input_type