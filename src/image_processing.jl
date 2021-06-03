
function areaopen!(im::BitArray{2},area::Int64)
    im_segm = label_components(im)
    num = maximum(im_segm)
    @floop ThreadedEx() for i=1:num
        mask = im_segm.==i
        if sum(mask)<area
            im[mask] .= false
        end
    end
    return
end

function areaopen!(im_segm::Array{Int64},area::Int64)
    num = maximum(im_segm)
    @floop ThreadedEx() for i=1:num
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

function component_intensity(components::Array{Int64},image::Array{Float32})
    num = maximum(components)
    intensities = Vector{Float32}(undef,num)
    for i = 1:num
        intensities[i] = mean(image[components.==i])
    end
    return intensities
end

function erode(array::BitArray{2},num::Int64)
    array2 = copy(array)
    for _ = 1:num
        erode!(array2)
    end
    return(array2)
end

function dilate(array::BitArray{2},num::Int64)
    array2 = copy(array)
    for _ = 1:num
        dilate!(array2)
    end
    return(array2)
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

function rescale(array,r::Tuple)
    r = convert(Float32,r)
    min_val = minimum(array)
    max_val = maximum(array)
    array = array.*((r[2]-r[1])/(max_val-min_val)).-min_val.+r[1]
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
