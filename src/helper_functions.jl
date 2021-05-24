
#---Struct related functions
function dict_to_struct!(obj,dict::Dict;skip=[])
    ks = [keys(dict)...]
    for i = 1:length(ks)
        ks_cur = ks[i]
        sym = Symbol(ks_cur)
        value = dict[ks_cur]
        if value isa Dict
            dict_to_struct!(getproperty(obj,sym),value;skip=skip)
        else
            if !(ks_cur in skip) && hasfield(typeof(obj),sym)
                setproperty!(obj,sym,value)
            end
        end
    end
end

function copystruct!(struct1,struct2)
  ks = fieldnames(typeof(struct1))
  for i = 1:length(ks)
    value = getproperty(struct2,ks[i])
    if value isa AbstractArray || value isa Tuple ||
            value isa Number || value isa AbstractString
        setproperty!(struct1,ks[i],value)
    else
        copystruct!(getproperty(struct1,ks[i]),
            getproperty(struct2,ks[i]))
    end
  end
end

#---Padding
same(el_type::Type,row::Int64,col::Int64,vect::Array) = ones(el_type,row,col).*vect
same(el_type::Type,row::Int64,col::Int64,vect::CUDA.CuArray) =
    CUDA.ones(el_type,row,col).*vect
function pad(array::Array,padding::Vector,fun::Union{typeof(zeros),typeof(ones)})
    el_type = eltype(array)
    div_result = padding./2
    leftpad = Int64.(floor.(div_result))
    rightpad = Int64.(ceil.(div_result))
    if padding[1]!=0
        array = vcat(fun(el_type,leftpad[1],size(array,2)),
            array,fun(el_type,rightpad[1],size(array,2)))
    end
    if padding[2]!=0
        array = hcat(fun(el_type,size(array,1),leftpad[2]),
            array,fun(el_type,size(array,1),rightpad[2]))
    end
end
function pad(array::Union{AbstractArray{Float32},AbstractArray{Float64}},
        padding::Vector{Int64},fun::Union{typeof(same),typeof(zeros),typeof(ones)})
    el_type = eltype(array)
    div_result = padding./2
    leftpad = Int64.(floor.(div_result))
    rightpad = Int64.(ceil.(div_result))
    if padding[1]!=0
        vec1 = array[1,:,:,:]'
        vec2 = array[end,:,:,:]'
        array = vcat(fun(el_type,leftpad[1],size(array,2),vec1),
            array,fun(el_type,rightpad[1],size(array,2),vec2))
    else       
        vec1 = array[:,1,:,:]
        vec2 = array[:,end,:,:]
        array = hcat(fun(el_type,size(array,1),leftpad[2],vec1),
            array,fun(el_type,size(array,1),rightpad[2],vec2))
    end
    return array
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


#---Other boolean things
function allequal(itr::Union{Array,Tuple})
    return length(itr)==0 || all( ==(itr[1]), itr)
end

function allcmp(inds)
    for i = 1:length(inds)
        if inds[1][1] != inds[i][1]
            return false
        end
    end
    return true
end

function anydim(array::BitArray,dim::Int64)
    vec = BitArray(undef, size(array,dim), 1)
    if dim==1
        for i=1:length(vec)
            vec[i] = any(array[i,:])
        end
    elseif dim==2
        for i=1:length(vec)
            vec[i] = any(array[:,i])
        end
    elseif dim==3
        for i=1:length(vec)
            vec[i] = any(array[:,:,i])
        end
    end
    return vec
end

anynan(x) = any(isnan.(x))

#---Other
function arsplit(ar::AbstractArray,dim::Int64)
    type = typeof(ar[1])
    ar_out = Vector{Vector{type}}(undef,size(ar,dim))
    if dim==1
        for i=1:size(ar,dim)
            push!(ar_out,ar[i,:])
        end
    else
        for i=1:size(ar,dim)
            push!(ar_out,ar[:,i])
        end
    end
    return ar_out
end

# Text of form "[n,n,...,n]", where n is a number to a tuple (n,n...,n)
function str2tuple(type::Type,str::String)
    if occursin("[",str)
        str2 = split(str,"")
        str2 = join(str2[2:end-1])
        ar = parse.(Int64, split(str2, ","))
    else
        ar = parse.(type, split(str, ","))
    end
    return (ar...,)
end

# Tuple from array
function make_tuple(array::AbstractArray)
    return (array...,)
end

function replace_nan!(x)
    type = typeof(x[1])
    for i = eachindex(x)
        if isnan(x[i])
            x[i] = zero(type)
        end
    end
end

function getdirs(dir)
    return filter(x -> isdir(joinpath(dir, x)),readdir(dir))
end

function getfiles(dir)
    return filter(x -> !isdir(joinpath(dir, x)),
        readdir(dir))
end

function remove_ext(files::Vector{String})
    filenames = copy(files)
    for i=1:length(files)
        chars = collect(files[i])
        ind = findfirst(chars.=='.')
        filenames[i] = String(chars[1:ind-1])
    end
    return filenames
end

function intersect_inds(ar1,ar2)
    inds1 = Array{Int64,1}(undef, 0)
    inds2 = Array{Int64,1}(undef, 0)
    for i=1:length(ar1)
        inds_log = ar2.==ar1[i]
        if any(inds_log)
            push!(inds1,i)
            push!(inds2,findfirst(inds_log))
        end
    end
    return (inds1, inds2)
end

function num_cores()
    return Threads.nthreads()
end

function time()
      date = string(now())
      date = date[1:19]
      date = replace(date,"T"=>" ")
      return date
end

function get_random_color(seed)
    Random.seed!(seed)
    rand(RGB{N0f8})
end

# Allows to use @info from GUI
function info(fields)
    @info get_data(fields)
end

cat3(A::AbstractArray) = cat(A; dims=Val(3))
cat3(A::AbstractArray, B::AbstractArray) = cat(A, B; dims=Val(3))
cat3(A::AbstractArray...) = cat(A...; dims=Val(3))

cat4(A::AbstractArray) = cat(A; dims=Val(4))
cat4(A::AbstractArray, B::AbstractArray) = cat(A, B; dims=Val(4))
cat4(A::AbstractArray...) = cat(A...; dims=Val(4))

gc() = GC.gc()

# Works as fill!, but does not use a reference
function fill_no_ref!(target::AbstractArray,el)
    for i = 1:length(target)
        target[i] = copy(el)
    end
end

enable_finalizers(on::Bool) = ccall(:jl_gc_enable_finalizers, Cvoid, (Ptr{Cvoid}, Int32,), Core.getptls(), on)

# Clears workspace
macro clear()
    return quote
        var_list = names(Main)
        count = 0
        for var in var_list
            types = (AbstractArray,Number,String,Bool)
            var_type = typeof(eval(var))
            if any((<:).(var_type,types))
                eval(Meta.parse(string(var," = nothing")))
                count+=1
            end
        end
        GC.gc()
        str = string("Cleared ",count," variables")
        @info str
    end
end