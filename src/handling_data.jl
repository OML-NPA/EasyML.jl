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

#---
# Returns label colors
function get_labels_colors_main(training_data::Training_data,channels::Channels)
    url_labels = training_data.url_labels
    num = length(url_labels)
    put!(channels.training_labels_colors,num)
    colors_array = Vector{Vector{Vector{Float32}}}(undef,num)
    labelimgs = Vector{Array{RGB{Normed{UInt8,8}},2}}(undef,0)
    for i=1:num
        push!(labelimgs,RGB.(load(url_labels[i])))
    end
    @floop ThreadedEx() for i=1:num
            labelimg = labelimgs[i]
            unique_colors = unique(labelimg)
            ind = findfirst(unique_colors.==RGB.(0,0,0))
            deleteat!(unique_colors,ind)
            colors255 = float.(unique_colors).*255
            colors = map(x->[x.r,x.g,x.b],colors255)
            colors_array[i] = colors
            put!(channels.training_labels_colors,1)
    end
    colors_out = reduce(vcat,colors_array)
    unique_colors_out = unique(colors_out)
    put!(channels.training_labels_colors,unique_colors_out)
    return nothing
end
function get_labels_colors_main2(training_data::Training_data,channels::Channels)
    #@everywhere training_data
    #remote_do(get_labels_colors_main,workers()[end],training_data,channels)
    Threads.@spawn get_labels_colors_main(training_data,channels)
end
get_labels_colors() = get_labels_colors_main2(training_data,channels)

#---Data/settings related functions
# Allows to read data from GUI
function get_data_main(data::Master_data,fields,inds)
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
    return data
end
get_data(fields,inds=[]) = get_data_main(master_data,fields,inds)

# Allows to write to data from GUI
function set_data_main(master_data::Master_data,fields,args...)
    data = settings
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
    setproperty!(data, Symbol(fields[end]), value)
    return nothing
end
set_data(fields,value,args...) = set_data_main(master_data,fields,value,args...)

# Allows to read settings from GUI
function get_settings_main(data::Settings,fields,inds...)
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
    return data
end
get_settings(fields,inds...) = get_settings_main(settings,fields,inds...)

# Allows to write to settings from GUI
function set_settings_main(settings::Settings,fields::QML.QListAllocated,args...)
    data = settings
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
    setproperty!(data, Symbol(fields[end]), value)
    return nothing
end
set_settings(fields,value,args...) = set_settings_main(settings,fields,value,args...)

function save_settings_main(settings::Settings)
    dict = Dict{Symbol,Any}()
    struct_to_dict!(dict,settings)
    BSON.@save("config.bson",dict)
    return nothing
end
save_settings() = save_settings_main(settings)

function load_settings!(settings::Settings)
    data = BSON.load("config.bson")
    dict_to_struct!(settings,data[:dict])
    return nothing
end
load_settings() = load_settings!(settings)

function source_dir()
    return fix_slashes(pwd())
end

function filter_ext(urls::Vector{String},allowed_ext::Vector{String})
    urls_split = split.(urls,'.')
    ext = map(x->string(x[end]),urls_split)
    ext = lowercase.(ext)
    log_inds = map(x->x in allowed_ext,ext)
    urls_out = urls[log_inds]
    return urls_out
end

function filter_ext(urls::Vector{String},allowed_ext::String)
    urls_split = split.(urls,'.')
    ext = map(x->string(x[end]),urls_split)
    ext = lowercase.(ext)
    log_inds = map(x->x == allowed_ext,ext)
    urls = urls[log_inds]
    return urls
end

#---Class output related functions
# Allows to read class output options from GUI
function get_output_main(model_data::Model_data,fields,ind)
    fields::Vector{String} = fix_QML_types(fields)
    ind::Int64 = fix_QML_types(ind)
    data = model_data.output_options[ind]
    for i = 1:length(fields)
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    return data
end
get_output(fields,ind) = get_output_main(model_data,fields,ind)

# Allows to write to class output options from GUI
function set_output_main(model_data::Model_data,fields,ind,value)
    fields::Vector{String} = fix_QML_types(fields)
    ind::Int64 = fix_QML_types(ind)
    value = fix_QML_types(value)
    data = model_data.output_options[ind]
    for i = 1:length(fields)-1
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    setproperty!(data, Symbol(fields[end]), value)
    return nothing
end
set_output(fields,ind,value) = set_output_main(model_data,fields,ind,value)

#---

function reset_data_field_main(master_data::Master_data,fields)
    fields::Vector{String} = fix_QML_types(fields)
    data = master_data
    for i = 1:length(fields)
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    empty!(data)
    return nothing
end
reset_data_field(fields) = reset_data_field_main(master_data,fields)

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

#---Image related functions

function bitarray_to_image(array_bool::BitArray{2},color::Vector{Normed{UInt8,8}})
    s = size(array_bool)
    array_uint = zeros(N0f8,4,s...)
    inds = [2,1,4]
    for i = 1:3
        ind = inds[i]
        channel = color[i]
        if channel>0
            slice = array_uint[ind,:,:]
            slice[array_bool] .= channel
            array_uint[ind,:,:] .= slice
        end
    end
    array_uint[3,:,:] .= 1
    return collect(colorview(ARGB32,array_uint))
end

function bitarray_to_image(array_bool::BitArray{3},color::Vector{Normed{UInt8,8}})
    s = size(array_bool)[2:3]
    array_uint = zeros(N0f8,4,s...)
    inds = [2,1,4]
    for i = 1:3
        ind = inds[i]
        channel = color[i]
        if channel>0
            slice = array_uint[ind,:,:]
            slice[array_bool[i,:,:]] .= channel
            array_uint[ind,:,:] .= slice
        end
    end
    array_uint[3,:,:] .= 1
    return collect(colorview(ARGB32,array_uint))
end

# Saves image to the main image storage and returns its size
function get_image_main(master_data::Master_data,fields,img_size,inds)
    fields = fix_QML_types(fields)
    img_size = fix_QML_types(img_size)
    inds = fix_QML_types(inds)
    image_data = get_data(fields,inds)
    if image_data isa Array{RGB{N0f8},2}
        image = image_data
    else
        image = bitarray_to_image(image_data...)
    end
    inds = findall(img_size.!=0)
    if !isempty(inds)
        r = minimum(map(x-> img_size[x]/size(image,x),inds))
        image = imresize(image, ratio=r)
    end
    master_data.image = image
    return [size(image)...]
end
get_image(fields,img_size,inds...) =
    get_image_main(master_data,fields,img_size,inds...)

# Displays image from the main image storage to Julia canvas
function display_image(buffer::Array{UInt32, 1},width::Int32,height::Int32)
    buffer = reshape(buffer, convert(Int64,width), convert(Int64,height))
    buffer = reinterpret(ARGB32, buffer)
    image = master_data.image
    if size(buffer)==reverse(size(image))
        buffer .= transpose(image)
    end
    return
end

#---Model related functions
# Number of model layers
model_count() = length(model_data.layers)

# Returns keys for layer properties
model_properties(index) = [keys(model_data.layers[Int64(index)])...]

# Returns model layer property value
function model_get_layer_property_main(model_data::Model_data,index,property_name)
    layer = model_data.layers[Int64(index)]
    property = layer[property_name]
    if  isa(property,Tuple)
        property = join(property,',')
    end
    return property
end
model_get_layer_property(index,property_name) =
    model_get_layer_property_main(model_data,index,property_name)

# Empties model layers
function reset_layers_main(model_data::Model_data)
    empty!(model_data.layers)
    return nothing
end
reset_layers() = reset_layers_main(model_data::Model_data)

# Saves new model layer data into a Julia dictionary
function update_layers_main(model_data::Model_data,keys,values,ext...)
    layers = model_data.layers
    keys = fix_QML_types(keys)
    values = fix_QML_types(values)
    ext = fix_QML_types(ext)
    dict = Dict{String,Any}()
    sizehint!(dict, length(keys))
    for i = 1:length(keys)
        var = values[i]
        if var isa String
            var_num = tryparse(Float64, var)
            if isnothing(var_num)
              if occursin(",", var) && !occursin("[", var)
                 dict[keys[i]] = str2tuple(Int64,var)
              else
                 dict[keys[i]] = var
              end
            else
              dict[keys[i]] = var_num
            end
        else
            dict[keys[i]] = var
        end
    end
    if length(ext)!=0
        for i = 1:2:length(ext)
            dict[ext[i]] = ext[i+1]
        end
    end
    dict = fixtypes(dict)
    push!(layers, copy(dict))
    return nothing
end
update_layers(keys,values,ext...) = update_layers_main(model_data::Model_data,
    keys,values,ext...)

# Fix types coming from QML
function fixtypes(dict::Dict)
    for key in [
        "filters",
        "dilationfactor",
        "stride",
        "inputs",
        "outputs",
        "dimension",
        "multiplier"]
        if haskey(dict, key)
            dict[key] = Int64(dict[key])
        end
    end
    if haskey(dict, "size")
        if length(dict["size"])==2
            dict["size"] = (dict["size"]...,1)
        end
    end
    for key in ["filtersize", "poolsize"]
        if haskey(dict, key)
            if length(dict[key])==1 && !(dict[key] isa Array)
                dict[key] = Int64(dict[key])
                dict[key] = (dict[key], dict[key])
            else
                dict[key] = (dict[key]...,)
            end
        end
    end
    return dict
end

# Set model type
function set_model_type_main(model_data::Model_data,type1,type2)
    model_data.type = [fix_QML_types(type1),fix_QML_types(type2)]
end
set_model_type(type1,type2) = set_model_type_main(model_data,type1,type2)

# Get model type
function get_model_type_main(model_data::Model_data)
    return model_data.type
end
get_model_type() = get_model_type_main(model_data)

# Resets model classes
function reset_classes_main(model_data)
    empty!(model_data.classes)
    return nothing
end
reset_classes() = reset_classes_main(model_data::Model_data)

# Resets model output options
function reset_output_options_main(model_data)
    empty!(model_data.output_options)
    return nothing
end
reset_output_options() = reset_output_options_main(model_data::Model_data)

# Appends model classes
function append_classes_main(model_data::Model_data,design_data::Design_data,id,data)
    data = fix_QML_types(data)
    id = convert(Int64,id)
    type = eltype(model_data.classes)
    backup = design_data.output_options_backup
    if type==Image_classification_class
        class = Image_classification_class()
        class.name = data[1]
    elseif type==Image_segmentation_class
        class = Image_segmentation_class()
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

    if type==Image_classification_class
        type_output = Image_classification_output_options
    elseif type==Image_segmentation_class
        type_output = Image_segmentation_output_options
    end
    if eltype(model_data.output_options)!=type_output
        model_data.output_options = Vector{type_output}(undef,0)
    end
    if id in 1:length(backup) && eltype(backup)==type_output
        push!(model_data.output_options,design_data.output_options_backup[id])
    else
        push!(model_data.output_options,type_output())
    end
    return nothing
end
append_classes(id,data) = append_classes_main(model_data,design_data,id,data)

# Returns the number of classes
function num_classes_main(model_data::Model_data)
    return length(model_data.classes)
end
num_classes() = num_classes_main(model_data::Model_data)

# Returns class value
function get_class_main(model_data::Model_data,index,fieldname)
    return getfield(model_data.classes[Int64(index)], Symbol(String(fieldname)))
end
get_class_field(index,fieldname) = get_class_main(model_data,index,fieldname)

function backup_options_main(model_data::Model_data)
    design_data.output_options_backup = deepcopy(model_data.output_options)
end
backup_options() = backup_options_main(model_data)

function get_problem_type()
    if eltype(model_data.classes)==Image_classification_class
        return 0
    elseif eltype(model_data.classes)==Image_segmentation_class
        return 1
    end
end

#---Model saving/loading
# Saves ML model
function save_model_main(model_data,url)
    names = fieldnames(Model_data)
    num = length(names)
    dict = Dict{Symbol,IOBuffer}()
    sizehint!(dict,num)
    for name in names
        field = getfield(model_data,name)
        BSON_stream = IOBuffer()
        BSON.@save(BSON_stream, field)
        dict[name] = BSON_stream
    end
    bson(String(url),dict)
  return nothing
end
save_model(url) = save_model_main(model_data,url)

# loads ML model
function load_model_main(settings,model_data,url)
    url = fix_QML_types(url)
    data = BSON.load(url)
    ks = keys(data)
    for k in ks
        try
            serialized = seekstart(data[k])
            deserialized = BSON.load(serialized)[:field]
            if all(k.!=(:loss,:model,:classes,:output_options))
                type = typeof(getfield(model_data,k))
                deserialized = convert(type,deserialized)
            elseif k==:classes || k==:output_options
                deserialized = [deserialized...]
                type = eltype(deserialized)
                deserialized = convert(Vector{type},deserialized)
            end
            setfield!(model_data,k,deserialized)
        catch e
            @warn string("Loading of ",k," failed. Exception: ",e)
        end
    end
    settings.Application.model_url = url
    settings.Training.model_url = url
    url_split = split(url,('/','.'))
    settings.Training.name = url_split[end-1]
    if model_data.classes isa Image_classification_class
        settings.Training.input_type = ("Image",0)
        settings.Training.problem_type = ("Classification",0)
    elseif model_data.classes isa Image_segmentation_class
        settings.Training.input_type = ("Image",0)
        settings.Training.problem_type = ("Segmentation",1)
    end
    return nothing
end
load_model(url) = load_model_main(settings,model_data,url)

function empty_field!(str,field::Symbol)
    val = getfield(str,field)
    type = typeof(val)
    new_val = type(undef,zeros(Int64,length(size(val)))...)
    setfield!(str, field, new_val)
    return nothing
end

function import_image(url)
    img = load(url)
    master_data.image = img
    return [size(img)...]
end