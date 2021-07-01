
# Returns color for labels, whether should be combined with other
# labels and whether border data should be obtained
function get_class_data(classes::Vector{ImageSegmentationClass})
    num = length(classes)
    class_names = Vector{String}(undef,num)
    class_parents = Vector{Vector{String}}(undef,num)
    labels_color = Vector{Vector{Float64}}(undef,num)
    labels_incl = Vector{Vector{Int64}}(undef,num)
    for i=1:num
        class = classes[i]
        class_names[i] = classes[i].name
        class_parents[i] = classes[i].parents
        labels_color[i] = class.color
    end
    for i=1:num
        labels_incl[i] = findall(any.(map(x->x.==class_parents[i],class_names)))
    end
    class_inds = Vector{Int64}(undef,0)
    for i = 1:num
        if !classes[i].not_class
            push!(class_inds,i)
        end
    end
    num = length(class_inds)
    border = Vector{Bool}(undef,num)
    border_thickness = Vector{Int64}(undef,num)
    for i in class_inds
        class = classes[i]
        border[i] = class.border
        border_thickness[i] = class.border_thickness
    end
    return class_inds,labels_color,labels_incl,border,border_thickness
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

# Saves image to the main image storage
function get_image_main(classes::Vector{AbstractClass},all_data,fields,inds,class_ind=0)
    fields = fix_QML_types(fields)
    inds = fix_QML_types(inds)
    image_data = get_data(fields,inds)
    if image_data isa Array{RGB{N0f8},2}
        image = image_data
    elseif image_data isa BitArray
        image = bitarray_to_image(image_data...)
    else
        if class_ind==0
            temp = image_data
        else
            if class_ind<=length(classes)
                color_float = classes[class_ind].color
                color = convert(Vector{Vector{N0f8}},color_float/255)
            else
                border_bool = map(class -> class.border,classes)
                colors = map(class -> class.color,classes)
                colors = colors[border_bool]
                color_float = colors[class_ind - length(classes)]
                color = convert(Vector{N0f8},color_float/255)
            end
            temp = image_data[:,:,class_ind]
            temp_bool = temp.>0
            image = bitarray_to_image(temp_bool,color)
        end
    end
    first_field = fields[1]
    some_data = get_data(first_field)
    final_field = fields[end]
    if any(final_field.==("original","data_input"))
        some_data.original_image = image
    elseif any(final_field.==("predicted_data","target_data","error_data","data_labels"))
        some_data.target_image = image
    end
    return
end
get_image(fields,inds,channel) =
    get_image_main(model_data.classes,all_data,fields,inds,channel)

function get_image_size(fields,inds)
    fields = fix_QML_types(fields)
    inds = fix_QML_types(inds)
    image_data = get_data(fields,inds)
    return [size(image_data)...]
end

# Displays image from the main image storage to Julia canvas
function display_original_image(some_data,buffer::Array{UInt32, 1},width::Int32,height::Int32)
    buffer = reshape(buffer, convert(Int64,width), convert(Int64,height))
    buffer = reinterpret(ARGB32, buffer)
    image = some_data.original_image
    s = size(image)
    
    if size(buffer)==reverse(size(image)) || (s[1]==s[2] && size(buffer)==size(image))
        buffer .= transpose(image)
    elseif size(buffer)==s
        buffer .= image
    end
    return
end
display_original_image_validation(buffer,width,height) = display_original_image(validation_data,buffer,width,height)
display_original_image_training(buffer,width,height) = display_original_image(training_data,buffer,width,height)
display_original_image_testing(buffer,width,height) = display_original_image(testing_data,buffer,width,height)

function display_label_image(some_data,buffer::Array{UInt32, 1},width::Int32,height::Int32)
    buffer = reshape(buffer, convert(Int64,width), convert(Int64,height))
    buffer = reinterpret(ARGB32, buffer)
    image = validation_data.label_image
    if size(buffer)==reverse(size(image))
        buffer .= transpose(image)
    end
    return
end
display_label_image_validation(buffer,width,height) = display_label_image(validation_data,buffer,width,height)
display_label_image_training(buffer,width,height) = display_label_image(training_data,buffer,width,height)
display_label_image_testing(buffer,width,height) = display_label_image(testing_data,buffer,width,height)