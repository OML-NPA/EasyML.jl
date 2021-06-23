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
function get_labels_colors_main(training_data::TrainingData,channels::Channels)
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
function get_labels_colors_main2(training_data::TrainingData,channels::Channels)
    #@everywhere training_data
    #remote_do(get_labels_colors_main,workers()[end],training_data,channels)
    Threads.@spawn get_labels_colors_main(training_data,channels)
end
get_labels_colors() = get_labels_colors_main2(training_data,channels)

#---Data/settings related functions
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
    if data isa Symbol
        data = string(data)
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
    # Import the configutation file
    if isfile("config.bson")
        try
            data = BSON.load("config.bson")
            dict_to_struct!(settings,data[:dict])
        catch e
            @error string("Settings were not loaded. Error: ",e)
            save_settings()
        end 
    else
        save_settings()
    end
    
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
function get_output_main(model_data::ModelData,fields,ind)
    fields::Vector{String} = fix_QML_types(fields)
    ind::Int64 = fix_QML_types(ind)
    data = model_data.OutputOptions[ind]
    for i = 1:length(fields)
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    return data
end
get_output(fields,ind) = get_output_main(model_data,fields,ind)

# Allows to write to class output options from GUI
function set_output_main(model_data::ModelData,fields,ind,value)
    fields::Vector{String} = fix_QML_types(fields)
    ind::Int64 = fix_QML_types(ind)
    value = fix_QML_types(value)
    data = model_data.OutputOptions[ind]
    for i = 1:length(fields)-1
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    setproperty!(data, Symbol(fields[end]), value)
    return nothing
end
set_output(fields,ind,value) = set_output_main(model_data,fields,ind,value)

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

#---Image related functions

function bitarray_to_image(array_bool::BitArray{2},color::Vector{Normed{UInt8,8}})
    s = size(array_bool)
    array = zeros(RGB{N0f8},s...)
    colorRGB = colorview(RGB,permutedims(color[:,:,:],(1,2,3)))[1]
    array[array_bool] .= colorRGB
    return collect(array)
end

function bitarray_to_image(array_bool::BitArray{3},color::Vector{Normed{UInt8,8}})
    s = size(array_bool)[2:3]
    array_vec = Vector{Array{RGB{N0f8},2}}(undef,0)
    for i in 1:3
        array_temp = zeros(RGB{N0f8},s...)
        color_temp = zeros(Normed{UInt8,8},3)
        color_temp[i] = color[i]
        colorRGB = colorview(RGB,permutedims(color_temp[:,:,:],(1,2,3)))[1]
        array_temp[array_bool[i,:,:]] .= colorRGB
        push!(array_vec,array_temp)
    end
    array = sum(array_vec)
    return collect(array)
end

# Saves image to the main image storage and returns its size
function get_image_main(validation_data::ValidationData,fields,img_size,inds)
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
        image = EasyML.imresize(image, ratio=r);
    end
    final_field = fields[end]
    if final_field=="original"
        validation_data.original_image = image
    elseif any(final_field.==("predicted_data","target_data","error_data"))
        validation_data.result_image = image
    end
    return [size(image)...]
end
get_image(fields,img_size,inds...) =
    get_image_main(validation_data,fields,img_size,inds...)

function get_image_size(fields,inds)
    fields = fix_QML_types(fields)
    inds = fix_QML_types(inds)
    image_data = get_data(fields,inds)
    if image_data isa Array{RGB{N0f8},2}
        return [size(image_data)...]
    else
        return [size(image_data[1])...]
    end
end

# Displays image from the main image storage to Julia canvas
function display_original_image(buffer::Array{UInt32, 1},width::Int32,height::Int32)
    buffer = reshape(buffer, convert(Int64,width), convert(Int64,height))
    buffer = reinterpret(ARGB32, buffer)
    image = validation_data.original_image
    s = size(image)
    
    if size(buffer)==reverse(size(image)) || (s[1]==s[2] && size(buffer)==size(image))
        buffer .= transpose(image)
    elseif size(buffer)==s
        buffer .= image
    end
    return
end

function display_result_image(buffer::Array{UInt32, 1},width::Int32,height::Int32)
    buffer = reshape(buffer, convert(Int64,width), convert(Int64,height))
    buffer = reinterpret(ARGB32, buffer)
    image = validation_data.result_image
    if size(buffer)==reverse(size(image))
        buffer .= transpose(image)
    end
    return
end


# Set model type
function set_model_type_main(model_data::ModelData,type1,type2)
    model_data.type = [fix_QML_types(type1),fix_QML_types(type2)]
end
set_model_type(type1,type2) = set_model_type_main(model_data,type1,type2)

# Get model type
function get_model_type_main(model_data::ModelData)
    return model_data.type
end
get_model_type() = get_model_type_main(model_data)

# Resets model classes
function reset_classes_main(model_data)
    if settings.problem_type==:Classification
        model_data.classes = Vector{ImageClassificationClass}(undef,0)
    elseif settings.problem_type==:Regression
        model_data.classes = Vector{ImageRegressionClass}(undef,0)
    elseif settings.problem_type==:Segmentation
        model_data.classes = Vector{ImageSegmentationClass}(undef,0)
    end
    return nothing
end
reset_classes() = reset_classes_main(model_data::ModelData)

# Resets model output options
function reset_output_options_main(model_data)
    if settings.problem_type==:Classification
        model_data.OutputOptions = Vector{ImageClassificationOutputOptions}(undef,0)
    elseif settings.problem_type==:Regression
        model_data.OutputOptions = Vector{ImageRegressionOutputOptions}(undef,0)
    elseif settings.problem_type==:Segmentation
        model_data.OutputOptions = Vector{ImageSegmentationOutputOptions}(undef,0)
    end
    return nothing
end
reset_output_options() = reset_output_options_main(model_data::ModelData)

# Appends model classes
function append_classes_main(model_data::ModelData,design_data::DesignData,id,data)
    data = fix_QML_types(data)
    id = convert(Int64,id)
    type = eltype(model_data.classes)
    backup = design_data.output_options_backup
    if settings.problem_type==:Classification
        class = ImageClassificationClass()
        class.name = data[1]
    elseif settings.problem_type==:Regression
        class = ImageRegressionClass()
        class.name = data[1]
    elseif settings.problem_type==:Segmentation
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

    if type==ImageClassificationClass
        type_output = ImageClassificationOutputOptions
    elseif type==ImageRegressionClass
        type_output = ImageRegressionOutputOptions
    elseif type==ImageSegmentationClass
        type_output = ImageSegmentationOutputOptions
    end
    if eltype(model_data.OutputOptions)!=type_output
        model_data.OutputOptions = Vector{type_output}(undef,0)
    end
    if id in 1:length(backup) && eltype(backup)==type_output
        push!(model_data.OutputOptions,design_data.output_options_backup[id])
    else
        push!(model_data.OutputOptions,type_output())
    end
    return nothing
end
append_classes(id,data) = append_classes_main(model_data,design_data,id,data)

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

function backup_options_main(model_data::ModelData)
    design_data.output_options_backup = deepcopy(model_data.OutputOptions)
end
backup_options() = backup_options_main(model_data)

function set_problem_type(ind)
    ind = fix_QML_types(ind)
    if ind==0 
        settings.problem_type = :Classification
    elseif ind==1
        settings.problem_type = :Regression
    elseif ind==2
        settings.problem_type = :Segmentation
    end
    return nothing
end

function get_problem_type()
    if settings.problem_type==:Classification
        return 0
    elseif settings.problem_type==:Regression
        return 1
    elseif settings.problem_type==:Segmentation
        return 2
    end
end

#---Model saving/loading
# Saves ML model
function save_model_main(model_data,url)
    names = fieldnames(ModelData)
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
    settings.Application.model_url = url
    settings.Training.model_url = url
    url_split = split(url,('/','.'))
    settings.Training.name = url_split[end-1]
    if model_data.classes isa Vector{ImageClassificationClass}
        settings.input_type = :Image
        settings.problem_type = :Classification
    elseif model_data.classes isa Vector{ImageRegressionClass}
        settings.input_type = :Image
        settings.problem_type = :Regression
    elseif model_data.classes isa Vector{ImageSegmentationClass}
        settings.input_type = :Image
        settings.problem_type = :Segmentation
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
    all_data.image = img
    return [size(img)...]
end