
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
    dilate!(array2,1)
    return xor.(array2,array)
end


function rotate_img(img::AbstractArray{T,3},angle_val::Float64) where T<:AbstractFloat
    if angle_val!=0
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
    if angle_val!=0
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
    field = imfilter(img_temp.<threshold, Kernel.gaussian(4)).>0.5
    field = closing!(field,closing_value)
    row_bool = (!).(alldim(field,1))
    col_bool = (!).(alldim(field,2))
    col1 = findfirst(col_bool)
    col2 = findlast(col_bool)
    row1 = findfirst(row_bool)
    row2 = findlast(row_bool)
    col1 = isnothing(col1) ? 1 : col1
    col2 = isnothing(col2) ? size(img,1) : col2
    row1 = isnothing(row1) ? 1 : row1
    row2 = isnothing(row2) ? size(img,2) : row2
    img = img[row1:row2,col1:col2,:]
    label = label[row1:row2,col1:col2,:]
    return img,label
end


