
#--- Applying a neural network
# Getting a slice and its information
function prepare_data(input_data::Union{Array{Float32,4},CuArray{Float32,4}},ind_max::Int64,
        max_value::Int64,offset::Int64,num_slices::Int64,ind_split::Int64,j::Int64)
    start_ind = 1 + (j-1)*ind_split
    if j==num_slices
        end_ind = max_value
    else
        end_ind = start_ind + ind_split-1
    end
    correct_size = end_ind-start_ind+1
    start_ind = start_ind - offset
    start_ind = start_ind<1 ? 1 : start_ind
    end_ind = end_ind + offset
    end_ind = end_ind>max_value ? max_value : end_ind
    temp_data = input_data[:,start_ind:end_ind,:,:]
    max_dim_size = size(temp_data,ind_max)
    offset_add = Int64(ceil(max_dim_size/16)*16) - max_dim_size
    temp_data = pad(temp_data,(0,offset_add),same)
    output_data = (temp_data,correct_size,offset_add)
    return output_data
end

# Makes output mask to have a correct size for stiching
function fix_size(temp_predicted::Union{Array{Float32,4},CuArray{Float32,4}},
        num_slices::Int64,correct_size::Int64,ind_max::Int64,
        offset_add::Int64,j::Int64)
    temp_size = size(temp_predicted,ind_max)
    offset_temp = (temp_size - correct_size) - offset_add
    if offset_temp>0
        div_result = offset_add/2
        offset_add1 = Int64(floor(div_result))
        offset_add2 = Int64(ceil(div_result))
        if j==1
            temp_predicted = temp_predicted[:,
                (1+offset_add1):(end-offset_temp-offset_add2),:,:]
        elseif j==num_slices
            temp_predicted = temp_predicted[:,
                (1+offset_temp+offset_add1):(end-offset_add2),:,:]
        else
            temp = (temp_size - correct_size - offset_add)/2
            offset_temp = Int64(floor(temp))
            offset_temp2 = Int64(ceil(temp))
            temp_predicted = temp_predicted[:,
                (1+offset_temp+offset_add1):(end-offset_temp2-offset_add2),:,:]
        end
    elseif offset_temp<0
        throw(DomainError("offset_temp should be greater or equal to zero"))
    end
end

# Accumulates and stiches slices (CPU)
function accum_slices(model::Chain,input_data::Array{Float32,4},
        num_slices::Int64,offset::Int64)
    input_size = size(input_data)
    max_value = maximum(input_size)
    ind_max = findfirst(max_value.==input_size)
    ind_split = convert(Int64,floor(max_value/num_slices))
    predicted = Vector{Array{Float32,4}}(undef,0)
    for j = 1:num_slices
        temp_data,correct_size,offset_add =
            prepare_data(input_data,ind_max,max_value,num_slices,offset,ind_split,j)
        temp_predicted::Array{Float32,4} = model(temp_data)
        temp_predicted = fix_size(temp_predicted,num_slices,correct_size,ind_max,offset_add,j)
        push!(predicted,temp_predicted)
    end
    if ind_max==1
        predicted_out = reduce(vcat,predicted)
    else
        predicted_out = reduce(hcat,predicted)
    end
    return predicted_out
end

# Accumulates and stiches slices (GPU)
function accum_slices(model::Chain,input_data::CuArray{Float32,4},
        num_slices::Int64,offset::Int64)
    input_size = size(input_data)
    max_value = maximum(input_size)
    ind_max = findfirst(max_value.==input_size)
    ind_split = convert(Int64,floor(max_value/num_slices))
    predicted = Vector{CuArray{Float32,4}}(undef,0)
    for j = 1:num_slices
        temp_data,correct_size,offset_add =
            prepare_data(input_data,ind_max,max_value,offset,num_slices,ind_split,j)
        temp_predicted = model(temp_data)
        temp_predicted = fix_size(temp_predicted,num_slices,correct_size,ind_max,offset_add,j)
        push!(predicted,collect(temp_predicted))
    end
    if ind_max==1
        predicted_out = reduce(vcat,predicted)
    else
        predicted_out = reduce(hcat,predicted)
    end
    return predicted_out
end

"""
forward(model::Chain, input_data::Array{Float32}; num_slices::Int64=1, offset::Int64=20, use_GPU::Bool=false)

The function takes in a model and input data and returns output from that model. `num_slices` specifies in how many 
slices should an array be run thorugh a neural network. Allows to process images that otherwise cause an out of memory error.
`offset` specifies the size of an overlap that should be taken from the left and right side of each slice to allow for 
an absense of a seam. `use_GPU` enables or disables GPU usage.
"""
function forward(model::Chain,input_data::Array{Float32};
        num_slices::Int64=1,offset::Int64=20,use_GPU::Bool=false)
    if use_GPU
        input_data_gpu = CuArray(input_data)
        model = gpu(model)
        if num_slices==1
            predicted = collect(model(input_data_gpu))
        else
            predicted = collect(accum_slices(model,input_data_gpu,num_slices,offset))
        end
    else
        if num_slices==1
            predicted = model(input_data)
        else
            predicted = accum_slices(model,input_data,num_slices,offset)
        end
    end
    return predicted
end

"""
    apply_border_data(input_data::BitArray{3},classes::Vector{ImageSegmentationClass})

Used for segmentation. Uses borders of objects that a neural network detected in order 
to separate objects from each other. Output from a neural network should be fed after 
converting to BitArray.
"""
function apply_border_data(input_data::BitArray{3},classes::Vector{ImageSegmentationClass})
    class_inds,_,_,border,border_thickness = get_class_data(classes)
    inds_border = findall(border)
    if isnothing(inds_border)
        return input_data
    end
    num_border = length(inds_border)
    num_classes = length(class_inds)
    data = BitArray{3}(undef,size(input_data)[1:2]...,num_border)
    for i = 1:num_border
        border_num_pixels = border_thickness[i]
        ind_classes = inds_border[i]
        ind_border = num_classes + ind_classes
        data_classes_bool = input_data[:,:,ind_classes]
        data_classes = convert(Array{Float32},data_classes_bool)
        data_border = input_data[:,:,ind_border]
        border_bool = data_border
        background1 = erode(data_classes_bool .& border_bool,border_num_pixels)
        background2 = outer_perim(border_bool)
        background2[data_classes_bool] .= false
        background2 = dilate(background2,border_num_pixels+1)
        background = background1 .| background2
        skel = thinning(border_bool)
        background[skel] .= true
        if classes[i].BorderClass.enabled
            components = label_components((!).(border_bool),conn(4))
            intensities = component_intensity(components,data_classes)
            bad_components = findall(intensities.<0.7)
            for i = 1:length(bad_components)
                components[components.==bad_components[i]] .= 0
            end
            objects = data_classes.!=0
            objects[skel] .= false
            segmented = segment_objects(components,objects)
            borders = mapwindow(x->!allequal(x), segmented, (3,3))
            segmented[borders] .= 0
            data[:,:,ind_classes] = segmented.>0
        else
            data_classes_bool[background] .= false
            data[:,:,i] = data_classes_bool
        end
    end
    return data
end


#---Padding
same(sizes::NTuple{N,Int64},vect::Array{T}) where {N,T} = ones(T,sizes).*vect
same(sizes::NTuple{N,Int64},vect::CUDA.CuArray{T}) where {N,T} = CUDA.ones(T,sizes).*vect

function pad(array::A,padding::NTuple{2,Int64},fun::typeof(same)) where A<:AbstractArray{<:AbstractFloat, 4}
    div_result = padding./2
    leftpad = Int64.(floor.(div_result))
    rightpad = Int64.(ceil.(div_result))
    if padding[1]!=0
        accum = Vector{A}(undef,0)
        for i in 1:size(array,3)
            temp_array = array[:,:,i,:,:]
            vec1 = collect(temp_array[1,:]')
            vec2 = collect(temp_array[end,:]')
            s_ar2 = size(temp_array,2)
            s1 = (leftpad[1],s_ar2,1,1)
            s2 = (rightpad[1],s_ar2,1,1)
            output_array = vcat(fun(s1,vec1),temp_array,fun(s2,vec2))
            push!(accum,output_array)
        end
        final_array = reduce(cat3,accum)
    else
        final_array = array
    end
    if padding[2]!=0
        accum = Vector{A}(undef,0)
        for i in 1:size(final_array,3)   
            temp_array = final_array[:,:,i,:,:]
            vec1 = temp_array[:,1]
            vec2 = temp_array[:,end]
            s_ar1 = size(temp_array,1)
            s1 = (s_ar1,leftpad[2],1,1)
            s2 = (s_ar1,rightpad[2],1,1)
            output_array = hcat(fun(s1,vec1),temp_array,fun(s2,vec2))
            push!(accum,output_array)
        end
        final_array = reduce(cat3,accum)
    end
    return final_array
end

function pad(array::A,padding::NTuple{2,Int64},
        fun::Union{typeof(zeros),typeof(ones)}) where {T<:AbstractFloat,A<:AbstractArray{T, 4}}
    div_result = padding./2
    leftpad = Int64.(floor.(div_result))
    rightpad = Int64.(ceil.(div_result))
    if padding[1]!=0
        accum = Vector{A}(undef,0)
        for i in 1:size(array,3)
            temp_array = array[:,:,i,:,:]
            s_ar2 = size(temp_array,2)
            s1 = (leftpad[1],s_ar2,1,1)
            s2 = (rightpad[1],s_ar2,1,1)
            output_array = vcat(fun(T,s1),temp_array,fun(T,s2))
            push!(accum,output_array)
        end
        final_array = reduce(cat3,accum)
    else
        final_array = array
    end
    if padding[2]!=0
        accum = Vector{A}(undef,0)
        for i in 1:size(final_array,3)   
            temp_array = final_array[:,:,i,:,:]
            s_ar1 = size(temp_array,1)
            s1 = (s_ar1,leftpad[2],1,1)
            s2 = (s_ar1,rightpad[2],1,1)
            output_array = hcat(fun(T,s1),temp_array,fun(T,s2))
            push!(accum,output_array)
        end
        final_array = reduce(cat3,accum)
    end
    return final_array
end