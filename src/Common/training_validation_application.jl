
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
