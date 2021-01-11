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
function get_labels_colors(url_labels::Vector{String})
    num = length(url_labels)
    colors_array = Vector{Vector{Vector{Float32}}}(undef,num)
    labelimgs = Vector{Array{RGB{Normed{UInt8,8}},2}}(undef,0)
    for i=1:num
        push!(labelimgs,RGB.(load(url_labels[i])))
    end
    Threads.@threads for i=1:num
            labelimg = labelimgs[i]
            unique_colors = unique(labelimg)
            ind = findfirst(unique_colors.==RGB.(0,0,0))
            deleteat!(unique_colors,ind)
            colors255 = float.(unique_colors).*255
            colors = map(x->[x.r,x.g,x.b],colors255)
            colors_array[i] = colors
    end
    colors_out = reduce(vcat,colors_array)
    unique_colors_out = unique(colors_out)
    return unique_colors_out
end

#---Data/settings related functions
# Allows to read data from GUI
function get_data_main(data::Master_data,fields,inds)
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
    values = Array{Any}(undef,length(args))
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
    BSON.@save("config.bson",settings)
    return nothing
end
save_settings() = save_settings_main(settings)

function load_settings!(settings::Settings)
    data = BSON.load("config.bson")
    copystruct!(settings,data[:settings])
    return nothing
end
load_settings() = load_settings!(settings)

function source_dir()
    return fix_slashes(pwd())
end

#---Feature output related functions
# Allows to read feature output options from GUI
function get_output_main(model_data::Model_data,fields,ind)
    fields::Vector{String} = fix_QML_types(fields)
    ind::Int64 = fix_QML_types(ind)
    data = model_data.features[ind].Output
    for i = 1:length(fields)
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    return data
end
get_output(fields,ind) = get_output_main(model_data,fields,ind)

# Allows to write to feature output options from GUI
function set_output_main(model_data::Model_data,fields,ind,value)
    fields::Vector{String} = fix_QML_types(fields)
    ind::Int64 = fix_QML_types(ind)
    value = fix_QML_types(value)
    data = model_data.features[ind].Output
    for i = 1:length(fields)-1
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    setproperty!(data, Symbol(fields[end]), value)
    return nothing
end
set_output(fields,ind,value) = set_output_main(model_data,fields,ind,value)

#---
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
# Saves image to the main image storage and returns its size
function get_image_main(master_data::Master_data,model_data::Model_data,fields,
        img_size,inds)
    fields = fix_QML_types(fields)
    img_size = fix_QML_types(img_size)
    inds = fix_QML_types(inds)
    image = collect(get_data(fields,inds))
    if isempty(image)
        master_data.image = ARGB32.(image)
        return [0,0]
    end

    inds = findall(img_size.!=0)
    if !isempty(inds)
        r = minimum(map(x-> img_size[x]/size(image,x),inds))
        image = imresize(image, ratio=r)
    end
    master_data.image = ARGB32.(image)
    return [size(image)...]
end
get_image(fields,img_size,inds...) =
    get_image_main(master_data,model_data,fields,img_size,inds...)

# Displays image from the main image storage to Julia canvas
function display_image(buffer::Array{UInt32, 1},
                      width32::Int32,
                      height32::Int32)
    width = width32
    height = height32
    buffer = reshape(buffer, width, height)
    buffer = reinterpret(ARGB32, buffer)
    image = master_data.image
    if size(buffer)==reverse(size(image))
        buffer .= transpose(ARGB32.(image))
    end
    return nothing
end

#---Model related functions
# Number of model layers
model_count() = length(model_data.layers)

# Returns keys for layer properties
model_properties(index) = [keys(model_data.layers[index])...]

# Returns model layer property value
function model_get_property_main(model_data::Model_data,index,property_name)
    layer = model_data.layers[index]
    property = layer[property_name]
    if  isa(property,Tuple)
        property = join(property,',')
    end
    return property
end
model_get_property(index,property_name) =
    model_get_property_main(model_data,index,property_name)

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
            if var_num == nothing
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
        "dimension"]
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

# Resets model features
function reset_features_main(model_data)
    empty!(model_data.features)
    return nothing
end
reset_features() = reset_features_main(model_data::Model_data)

# Appends model features
function append_features_main(model_data::Model_data,output_options::Output_options,
        name,colorR,colorG,colorB,border,parent)
    push!(model_data.features,Feature(String(name),Int64.([colorR,colorG,colorB]),
        Bool(border),String(parent),output_options))
    return nothing
end
append_features(name,colorR,colorG,colorB,border,parent) =
    append_features_main(model_data,output_options,name,colorR,colorG,colorB,border,parent)

# Updates model feature with new data
function update_features_main(model_data,index,name,colorR,colorG,colorB,border,parent)
    feature = model_data.features[index]
    feature.name = String(name)
    feature.color = Int64.([colorR,colorG,colorB])
    feature.border = Bool(border)
    feature.parent = String(parent)
    feature.Output = feature.Output
end
update_features(index,name,colorR,colorG,colorB,border,parent) =
    update_features_main(model_data,index,name,colorR,colorG,colorB,border,parent)

# Returns the number of features
function num_features_main(model_data::Model_data)
    return length(model_data.features)
end
num_features() = num_features_main(model_data::Model_data)

# Returns feature value
function get_feature_main(model_data::Model_data,index,fieldname)
    return getfield(model_data.features[index], Symbol(String(fieldname)))
end
get_feature_field(index,fieldname) = get_feature_main(model_data,index,fieldname)

#---Model saving/loading
# Saves ML model
function save_model_main(model_data,url)
  BSON.@save(String(url),model_data)
  return nothing
end
save_model(url) = save_model_main(model_data,url)

# loads ML model
function load_model_main(url,model_data)
  data = BSON.load(String(url))
  if haskey(data,:model_data)
      imported_model_data = data[:model_data]
      ks = fieldnames(Model_data)
      for i = 1:length(ks)
        value = getproperty(imported_model_data,ks[i])
        setproperty!(model_data,ks[i],value)
      end
      return true
  else
      return false
  end
end
load_model(url) = load_model_main(url,model_data)

function load_model()
    # Launches GUI
    @qmlfunction(
        # Handle features
        model_count,
        model_properties,
        model_get_property,
        # Model functions
        load_model
    )
    load("GUI/FileDialogWindow.qml")
    exec()

    return model_data
end
