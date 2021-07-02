# Make urls QML compatible
function fix_slashes(url)
    url::String = fix_QML_types(url)
    url = replace(url, "\\" => "/")
    url = string(uppercase(url[1]),url[2:end])
end

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

#---Data/options related functions
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
function set_options_main(options::Options,fields::QML.QListAllocated,args...)
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

function save_options_main(options::Options)
    dict = Dict{Symbol,Any}()
    struct_to_dict!(dict,options)
    BSON.@save("options.bson",dict)
    return nothing
end
save_options() = save_options_main(options)

function load_options!(options::Options)
    # Import the configutation file
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
load_options() = load_options!(options)

#---

function reset_data_field_main(all_data::AllData,fields)
    fields::Vector{String} = fix_QML_types(fields)
    data = all_data
    for i = 1:length(fields)
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    empty!(data)
    return nothing
end
reset_data_field(fields) = reset_data_field_main(all_data,fields)

# Resets data property
function resetproperty!(datatype,field)
    var = getproperty(datatype,field)
    if var isa Array
        var = similar(var,0)
    elseif var isa Number
        var = zero(typeof(var))
    elseif var isa String
        var = ""
    end
    setproperty!(datatype,field,var)
    return nothing
end

# Resets model classes
function reset_classes_main(model_data)
    if problem_type()==:Classification
        model_data.classes = Vector{ImageClassificationClass}(undef,0)
    elseif problem_type()==:Regression
        model_data.classes = Vector{ImageRegressionClass}(undef,0)
    elseif problem_type()==:Segmentation
        model_data.classes = Vector{ImageSegmentationClass}(undef,0)
    end
    return nothing
end
reset_classes() = reset_classes_main(model_data::ModelData)

# Appends model classes
function append_classes_main(model_data::ModelData,id,data)
    data = fix_QML_types(data)
    id = convert(Int64,id)
    if problem_type()==:Classification
        class = ImageClassificationClass()
        class.name = data[1]
    elseif problem_type()==:Regression
        class = ImageRegressionClass()
        class.name = data[1]
    elseif problem_type()==:Segmentation
        class = ImageSegmentationClass()
        class.name = String(data[1])
        class.color = Int64.([data[2],data[3],data[4]])
        class.border = Bool(data[5])
        class.border_thickness = Int64(data[6])
        class.border_remove_objs = Bool(data[7])
        class.min_area = Int64(data[8])
        class.parents = data[9]
        class.not_class = Bool(data[10])
    end
    push!(model_data.classes,class)
    return nothing
end
append_classes(id,data) = append_classes_main(model_data,id,data)

# Returns the number of classes
function num_classes_main(model_data::ModelData)
    return length(model_data.classes)
end
num_classes() = num_classes_main(model_data::ModelData)

# Returns class value
function get_class_main(model_data::ModelData,index,fieldname)
    return getfield(model_data.classes[Int64(index)], Symbol(String(fieldname)))
end
get_class_field(index,fieldname) = get_class_main(model_data,index,fieldname)

#------------------------------------------------------------------------
function source_dir()
    return fix_slashes(pwd())
end
