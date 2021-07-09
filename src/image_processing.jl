
function areaopen!(im::BitArray{2},area::Int64)
    im_segm = label_components(im)
    num = maximum(im_segm)
    chunk_size = convert(Int64,round(num/num_threads()))
    @floop ThreadedEx(basesize = chunk_size) for i=1:num
        mask = im_segm.==i
        if sum(mask)<area
            im[mask] .= false
        end
    end
    return
end

function areaopen!(im_segm::Array{Int64},area::Int64)
    num = maximum(im_segm)
    chunk_size = convert(Int64,round(num/num_threads()))
    @floop ThreadedEx(basesize = chunk_size) for i=1:num
        mask = im_segm.==i
        if sum(mask)<area
            im[mask] .= false
        end
    end
    return
end

function remove_spurs!(img::BitArray{2})
    img_float = convert(Array{Float32,2},img)
    kernel = centered(ones(Float32,3,3))
    spurs = imfilter(img_float,kernel)
    spurs = (spurs.<2) .& (img.!=0)
    inds = findall(spurs)
    for i=1:length(inds)
        ind = inds[i]
        while true
            img[ind] = false
            ind_tuple = Tuple(ind)
            neighbors = img[ind_tuple[1]-1:ind_tuple[1]+1,
                            ind_tuple[2]-1:ind_tuple[2]+1]
            inds_temp = findall(neighbors)
            if length(inds_temp)==0 || length(inds_temp)>1
                break
            else
                inds_temp = Tuple(inds_temp[1]) .-2
                ind = CartesianIndex(ind_tuple .+ inds_temp)
            end
        end
    end
end


function erode(array::BitArray{2},num::Int64)
    array2 = copy(array)
    for _ = 1:num
        ImageMorphology.erode!(array2)
    end
    return(array2)
end

function dilate(array::BitArray{2},num::Int64)
    array2 = copy(array)
    for _ = 1:num
        ImageMorphology.dilate!(array2)
    end
    return(array2)
end

function closing(array::BitArray{2},num::Int64)
    array2 = copy(array)
    dilate!(array2,num)
    erode!(array2,num)
    return array2
end


function dilate!(array::BitArray{2},num::Int64)
    for _ = 1:num
        ImageMorphology.dilate!(array)
    end
    return(array)
end

function erode!(array::BitArray{2},num::Int64)
    for _ = 1:num
        ImageMorphology.erode!(array)
    end
    return(array)
end

function closing!(array::BitArray{2},num::Int64)
    dilate!(array,num)
    erode!(array,num)
    return array
end


function outer_perim(array::BitArray{2})
    array2 = copy(array)
    dil = dilate(array2,1)
    return xor.(dil,array2)
end

function inner_perim(array::BitArray{2})
    array2 = copy(array)
    array2[1:end,1] .= 0
    array2[1:end,end] .= 0
    array2[1,1:end] .= 0
    array2[end,1:end] .= 0
    er = erode(array2,1)
    return xor.(array2,er)
end


function rotate_img(img::AbstractArray{Real,2},angle_val::Float64)
    if angle!=0
        img_out = imrotate(img,angle_val,axes(img))
        replace_nan!(img_out)
        return(img_out)
    else
        return(img)
    end
end

function rotate_img(img::AbstractArray{T,3},angle_val::Float64) where T<:AbstractFloat
    if angle!=0
        img_out = copy(img)
        for i = 1:size(img,3)
            slice = img[:,:,i]
            temp = imrotate(slice,angle_val,axes(slice))
            replace_nan!(temp)
            img_out[:,:,i] = convert.(T,temp)
        end
        return(img_out)
    else
        return(img)
    end
end

function rotate_img(img::BitArray{3},angle_val::Float64)
    if angle!=0
        img_out = copy(img)
        for i = 1:size(img,3)
            slice = img[:,:,i]
            temp = imrotate(slice,angle_val,axes(slice))
            replace_nan!(temp)
            img_out[:,:,i] = temp.>0
        end
        return(img_out)
    else
        return(img)
    end
end


function segment_objects(components::Array{Int64,2},objects::BitArray{2})
    img_size = size(components)[1:2]
    initial_indices = findall(components.!=0)
    operations = [(0,1),(1,0),(0,-1),(-1,0),(1,-1),(-1,1),(-1,-1),(1,1)]
    new_components = copy(components)
    indices_out = initial_indices

    while length(indices_out)!=0
        indices_in = indices_out
        indices_accum = Vector{Vector{CartesianIndex{2}}}(undef,0)
        for i = 1:4
            target = repeat([operations[i]],length(indices_in))
            new_indices = broadcast((x,y) -> x .+ y,
                Tuple.(indices_in),target)
            objects_values = objects[indices_in]
            target = repeat([(0,0)],length(new_indices))
            nonzero_bool = broadcast((x,y) -> all(x .> y),
                new_indices,target)
            target = repeat([img_size],length(new_indices))
            correct_size_bool = broadcast((x,y) -> all(x.<img_size),
                new_indices,target)
            remove_incorrect = nonzero_bool .&
                correct_size_bool .& objects_values
            new_indices = new_indices[remove_incorrect]
            values = new_components[CartesianIndex.(new_indices)]
            new_indices_0_bool = values.==0
            new_indices_0 = map(x-> CartesianIndex(x),
                new_indices[new_indices_0_bool])
            indices_prev = indices_in[remove_incorrect][new_indices_0_bool]
            prev_values = new_components[CartesianIndex.(indices_prev)]
            new_components[new_indices_0] .= prev_values
            push!(indices_accum,new_indices_0)
        end
        indices_out = reduce(vcat,indices_accum)
    end
    return new_components
end

function component_intensity(components::Array{Int64},image::Array{Float32})
    num = maximum(components)
    intensities = Vector{Float32}(undef,num)
    for i = 1:num
        intensities[i] = mean(image[components.==i])
    end
    return intensities
end

function alldim(array::BitArray{2},dim::Int64)
    vec = BitArray(undef, size(array,dim))
    if dim==1
        for i=1:length(vec)
            vec[i] = all(array[i,:])
        end
    elseif dim==2
        for i=1:length(vec)
            vec[i] = all(array[:,i])
        end
    end
    return vec
end

# Removes rows and columns from image sides if they are uniformly black.
function crop_background(img::Array{Float32,3},label::BitArray{3},
        threshold::Float64,closing_value::Int64)
    img_temp = mean(img,dims=3)[:,:]
    field = closing(imfilter(img_temp.<threshold, Kernel.gaussian(4)).>0.5,closing_value)
    row_bool = (!).(alldim(field,1))
    col_bool = (!).(alldim(field,2))
    col1 = findfirst(col_bool)
    col2 = findlast(col_bool)
    row1 = findfirst(row_bool)
    row2 = findlast(row_bool)
    col1 = isnothing(col1) ? 1 : col1
    col2 = isnothing(col1) ? 1 : col2
    row1 = isnothing(col1) ? 1 : row1
    row1 = isnothing(col1) ? 1 : row2
    img = img[row1:row2,col1:col2,:]
    label = label[row1:row2,col1:col2,:]
    return img,label
end


