
function Images.dilate!(array::BitArray{2},num::Int64)
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


function replace_nan!(x)
    type = eltype(x)
    for i = eachindex(x)
        if isnan(x[i])
            x[i] = zero(type)
        end
    end
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

function conn(num::Int64)
    if num==4
        kernel = [false true false
                  true true true
                  false true false]
    else
        kernel = [true true true
                  true true true
                  true true true]
    end
    return kernel
end

function component_intensity(components::Array{Int64},image::Array{Float32})
    num = maximum(components)
    intensities = Vector{Float32}(undef,num)
    for i = 1:num
        intensities[i] = mean(image[components.==i])
    end
    return intensities
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

function allequal(itr::Union{Array,Tuple})
    return length(itr)==0 || all( ==(itr[1]), itr)
end