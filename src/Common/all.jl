
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

#---Model saving/loading------------------------------------------
function save_model_main(model_data,url)
    url = fix_QML_types(url)
    dict = Dict{Symbol,Any}()
    struct_to_dict!(dict,model_data)
    BSON.@save(url,dict)
    return nothing
end
"""
    save_model(url::String)

Saves a model to a specified URL. The URL can be absolute or relative. 
Use '.model' extension.
"""
save_model(url) = save_model_main(model_data,url)

# loads ML model
function load_model_main(model_data,url)
    url = fix_QML_types(url)
    if isfile(url)
        data = BSON.load(url)
    else
        @error string(url, " does not exist.")
        return nothing
    end
    ks = collect(keys(data))
    if data[ks[1]] isa IOBuffer
        # Will be removed before addition to the registry
        for k in ks
            try
                serialized = seekstart(data[k])
                deserialized = BSON.load(serialized)[:field]
                if all(k.!=(:output_size,:loss,:model,:classes,:OutputOptions))
                    type = typeof(getfield(model_data,k))
                    deserialized = convert(type,deserialized)
                elseif k==:classes || k==:OutputOptions
                    deserialized = [deserialized...]
                    if !isempty(deserialized)
                        type = eltype(deserialized)
                        deserialized = convert(Vector{type},deserialized)
                    else
                        continue
                    end
                end
                setfield!(model_data,k,deserialized)
            catch e
                @warn string("Loading of ",k," failed. Exception: ",e)
            end
        end
    else
        dict_to_struct!(model_data,data[:dict])
    end
    all_data.model_url = url
    url_split = split(url,('/','.'))
    all_data.model_name = url_split[end-1]
    if model_data.classes isa Vector{ImageClassificationClass}
        all_data.input_type = :Image
        all_data.problem_type = :Classification
    elseif model_data.classes isa Vector{ImageRegressionClass}
        all_data.input_type = :Image
        all_data.problem_type = :Regression
    elseif model_data.classes isa Vector{ImageSegmentationClass}
        all_data.input_type = :Image
        all_data.problem_type = :Segmentation
    end
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