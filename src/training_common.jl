
# Get urls of files in a selected folder. Files are used for training and/or validation.
function get_urls(dir_inputs::String,dir_labels::String)
    # Initialise accumulators
    urls_inputs = String[]
    urls_labels = String[]
    # Get directories containing our inputs and labels
    dirs_inputs = getdirs(dir_inputs)
    dirs_labels = getdirs(dir_labels)
    # Keep only those present for both inputs and labels
    dirs = intersect(dirs_inputs,dirs_labels)
    # If no directories, then set empty string
    if length(dirs)==0
        dirs = [""]
    end
    # Collect urls
    for k = 1:length(dirs)
        # Get files in a directory
        files_inputs = getfiles(string(dir_inputs,"/",dirs[k]))
        files_labels = getfiles(string(dir_labels,"/",dirs[k]))
        # Remove extensions from files
        filenames_inputs = remove_ext(files_inputs)
        filenames_labels = remove_ext(files_labels)
        # Intersect file names
        inds1, inds2 = intersect_inds(filenames_labels, filenames_inputs)
        # Keep files present for both inputs and labels
        files_inputs = files_inputs[inds1]
        files_labels = files_labels[inds2]
        # Push urls into accumulators
        for l = 1:length(files_inputs)
            push!(urls_inputs,string(dir_inputs,"/",files_inputs[l]))
            push!(urls_labels,string(dir_labels,"/",files_labels[l]))
        end
    end
    return urls_inputs,urls_labels
end

function get_urls(dir_inputs::String)
    # Initialise accumulators
    urls = String[]
    labels = String[]
    # Get directories containing our images
    dirs_inputs = getdirs(dir)
    # If no directories, then set empty string
    if length(dirs)==0
        dirs = [""]
    end
    # Collect urls
    for k = 1:length(dirs)
        current_dir = dirs[k]
        # Get files in a directory
        files_inputs = getfiles(string(dir_inputs,"/",current_dir))
        # Remove extensions from files
        filenames_inputs = remove_ext(files_inputs)
        # Push urls into accumulators
        for l = 1:length(files_inputs)
            push!(urls_inputs,string(dir_inputs,"/",files_inputs[l]))
            push!(labels,current_dir)
        end
    end
    return urls_inputs
end

# Imports images using urls
function load_images(urls::Vector{String})
    num = length(urls)
    imgs = Vector{Array{RGB{N0f8},2}}(undef,num)
    for i = 1:num
        imgs[i] = load(urls[i])
    end
    return imgs
end

# Convert images to grayscale Array{Float32,2}
function image_to_gray_float(image::Array{RGB{Normed{UInt8,8}},2})
    return collect(channelview(float.(Gray.(image))))
end

# Convert images to RGB Array{Float32,3}
function image_to_rgb_float(image::Array{RGB{Normed{UInt8,8}},2})
    return collect(channelview(float.(image)))
end

# Convert images to BitArray{3}
function label_to_bool(labelimg::Array{RGB{Normed{UInt8,8}},2},
        labels_color::Vector{Vector{Float64}},labels_incl::Vector{Vector{Int64}},
        border::Vector{Bool})
    colors = map(x->RGB((n0f8.(./(x,255)))...),labels_color)
    num = length(colors)
    num_borders = sum(border)
    inds_borders = findall(border)
    label = fill!(BitArray{3}(undef, size(labelimg)...,
        num + num_borders),0)
    # Find features based on colors
    for i=1:num
        label[:,:,i] = .==(labelimg,colors[i])
    end
    # Combine feature marked for that
    for i=1:num
        for j=1:length(labels_incl[i])
            label[:,:,i] = .|(label[:,:,i],
                label[:,:,labels_incl[i][j]])
        end
    end
    # Make features outlining object borders
    for j=1:length(inds_borders)
        dil = dilate(perim(label[:,:,inds_borders[j]]),5)
        label[:,:,length(colors)+j] = dil
    end
    return label
end

# Returns color for labels, whether should be combined with other
# labels and whether border data should be obtained
function get_feature_data(features::Vector{Feature})
    num = length(features)
    labels_color = Vector{Vector{Float64}}(undef,num)
    labels_incl = Vector{Vector{Int64}}(undef,num)
    border = Vector{Bool}(undef,num)
    feature_names = Vector{String}(undef,num)
    feature_parents = Vector{String}(undef,num)
    for i = 1:num
        feature_names[i] = features[i].name
        feature_parents[i] = features[i].parent
    end
    for i = 1:num
        feature = features[i]
        labels_color[i] = feature.color
        border[i] = feature.border
        inds = findall(feature_names[i].==feature_parents)
        labels_incl[i] = inds
    end
    return labels_color,labels_incl,border
end

# Removes rows and columns from image sides if they are uniformly black.
function correct_view(img::Array{Float32,2},label::Array{RGB{Normed{UInt8,8}},2})
    field = dilate(imfilter(img.<0.3, Kernel.gaussian(4)).>0.5,20)
    areaopen!(field,30000)
    field = .!(field)
    field_area = sum(field)
    field_perim = sum(perim(field))/1.25
    circularity = (4*pi*field_area)/(field_perim^2)
    if circularity>0.9
        row_bool = any(field,1)
        col_bool = any(field,2)
        col1 = findfirst(col_bool)[1]
        col2 = findlast(col_bool)[1]
        row1 = findfirst(row_bool)[1]
        row2 = findlast(row_bool)[1]
        img = img[row1:row2,col1:col2]
        label = label[row1:row2,col1:col2]
    end
    img = rescale(img,(0,1))
    return img,label
end

# Rotate Array{Float32}
function rotate_img(img::Array{Float32,2},angle_val::Float64)
    if angle!=0
        img_out = imrotate(img,angle_val,axes(img))
        replace_nan!(img_out)
        return(img_out)
    else
        return(img)
    end
end

# Rotate BitArray
function rotate_img(img::BitArray{3},angle_val::Float64)
    if angle!=0
        img_out = copy(img)
        for i = 1:size(img,3)
            temp = imrotate(img[:,:,i],angle_val,axes(img[:,:,i]))
            replace_nan!(temp)
            img_out[:,:,i] = temp.>0
        end
        return(img_out)
    else
        return(img)
    end
end

# Use border data to better separate objects
function apply_border_data_main(data_in::BitArray{3},model_data::Model_data)
    labels_color,labels_incl,border = get_feature_data(model_data.features)
    inds_border = findall(border)
    if inds_border==nothing
        return data_in
    end
    num_border = length(inds_border)
    num_feat = length(model_data.features)
    data = BitArray{3}(undef,size(data_in)[1:2]...,num_border)
    for i = 1:num_border
        ind_feat = inds_border[i]
        ind_border = num_feat + ind_feat
        data_feat_bool = data_in[:,:,ind_feat]
        data_feat = convert(Array{Float32},data_feat_bool)
        data_border = data_in[:,:,ind_border]
        border_bool = data_border
        skel = thinning(border_bool)
        components = label_components((!).(border_bool),conn(4))
        centroids = component_centroids(components)
        intensities = component_intensity(components,data_feat)
        bad_components = findall(intensities.<0.7)
        for i = 1:length(bad_components)
            components[components.==bad_components[i]] .= 0
        end
        objects = data_feat.!=0
        objects[skel] .= false
        segmented = segment_objects(components,objects)
        borders = mapwindow(x->!allequal(x), segmented, (3,3))
        segmented[borders] .= 0
        data[:,:,ind_feat] = segmented.>0
    end
    return data
end
apply_border_data(data_in) = apply_border_data_main(data_in,model_data)

#---
# Accuracy based on RMSE
function accuracy_regular(predicted::Union{Array,CuArray},actual::Union{Array,CuArray})
    dif = predicted - actual
    acc = 1-mean(mean.(map(x->abs.(x),dif)))
    return acc
end

# Weight accuracy using inverse frequency (CPU)
function accuracy_weighted(predicted::Array{Float32,4},actual::Array{Float32,4})
    # Get input dimensions
    array_size = size(actual)
    array_size12 = array_size[1:2]
    num_feat = array_size[3]
    num_batch = array_size[4]
    # Convert to BitArray
    actual_bool = actual.>0
    predicted_bool = predicted.>0.5
    # Calculate correct and incorrect feature pixels as a BitArray
    correct_bool = predicted_bool .& actual_bool
    dif_bool = xor.(predicted_bool,actual_bool)
    # Calculate correct and incorrect background pixels as a BitArray
    correct_background_bool = (!).(dif_bool .| actual_bool)
    dif_background_bool = dif_bool-actual_bool
    # Number of elements
    numel = prod(array_size12)
    # Count number of feature pixels
    pix_sum = sum(actual_bool,dims=(1,2,4))
    pix_sum_perm = permutedims(pix_sum,[3,1,2,4])
    feature_counts = pix_sum_perm[:,1,1,1]
    # Calculate weight for each pixel
    fr = feature_counts./numel./num_batch
    w = 1 ./fr
    w2 = 1 ./(1 .- fr)
    w_sum = w + w2
    w = w./w_sum
    w2 = w2./w_sum
    w_adj = w./feature_counts
    w2_adj = w2./(numel*num_batch .- feature_counts)
    # Initialize vectors for storing accuracies
    features_accuracy = Vector{Float32}(undef,num_feat)
    background_accuracy = Vector{Float32}(undef,num_feat)
    # Calculate accuracies
    for i = 1:num_feat
        # Calculate accuracy for a feature
        sum_correct = sum(correct_bool[:,:,i,:])
        sum_dif = sum(dif_bool[:,:,i,:])
        sum_comb = sum_correct*sum_correct/(sum_correct+sum_dif)
        features_accuracy[i] = w_adj[i]*sum_comb
        # Calculate accuracy for a background
        sum_correct = sum(correct_background_bool[:,:,i,:])
        sum_dif = sum(dif_background_bool[:,:,i,:])
        sum_comb = sum_correct*sum_correct/(sum_correct+sum_dif)
        background_accuracy[i] = w2_adj[i]*sum_comb
    end
    # Calculate final accuracy
    acc = mean(features_accuracy+background_accuracy)
    if acc>1.0
        acc = 1.0f0
    end
    return acc
end

# Weight accuracy using inverse frequency (GPU)
function accuracy_weighted(predicted::CuArray{Float32,4},actual::CuArray{Float32,4})
    # Get input dimensions
    array_size = size(actual)
    array_size12 = array_size[1:2]
    num_feat = array_size[3]
    num_batch = array_size[4]
    # Convert to BitArray
    actual_bool = actual.>0
    predicted_bool = predicted.>0.5
    # Calculate correct and incorrect feature pixels as a BitArray
    correct_bool = predicted_bool .& actual_bool
    dif_bool = xor.(predicted_bool,actual_bool)
    # Calculate correct and incorrect background pixels as a BitArray
    correct_background_bool = (!).(dif_bool .| actual_bool)
    dif_background_bool = dif_bool-actual_bool
    # Number of elements
    numel = prod(array_size12)
    # Count number of feature pixels
    pix_sum::Array{Float32,4} = collect(sum(actual_bool,dims=(1,2,4)))
    pix_sum_perm = permutedims(pix_sum,[3,1,2,4])
    feature_counts = pix_sum_perm[:,1,1,1]
    # Calculate weight for each pixel
    fr = feature_counts./numel./num_batch
    w = 1 ./fr
    w2 = 1 ./(1 .- fr)
    w_sum = w + w2
    w = w./w_sum
    w2 = w2./w_sum
    w_adj = w./feature_counts
    w2_adj = w2./(numel*num_batch .- feature_counts)
    # Initialize vectors for storing accuracies
    features_accuracy = Vector{Float32}(undef,num_feat)
    background_accuracy = Vector{Float32}(undef,num_feat)
    # Calculate accuracies
    for i = 1:num_feat
        # Calculate accuracy for a feature
        sum_correct = sum(correct_bool[:,:,i,:])
        sum_dif = sum(dif_bool[:,:,i,:])
        sum_comb = sum_correct*sum_correct/(sum_correct+sum_dif)
        features_accuracy[i] = w_adj[i]*sum_comb
        # Calculate accuracy for a background
        sum_correct = sum(correct_background_bool[:,:,i,:])
        sum_dif = sum(dif_background_bool[:,:,i,:])
        sum_comb = sum_correct*sum_correct/(sum_correct+sum_dif)
        background_accuracy[i] = w2_adj[i]*sum_comb
    end
    # Calculate final accuracy
    acc = mean(features_accuracy+background_accuracy)
    if acc>1.0
        acc = 1.0f0
    end
    return acc
end

# Returns an accuracy function
function get_accuracy_func(training::Training)
    if training.Options.General.weight_accuracy
        return accuracy_weighted
    else
        return accuracy_regular
    end
end
