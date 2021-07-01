
#---Struct related functions
function struct_to_dict!(dict,obj)
    ks = fieldnames(typeof(obj))
    for k in ks
        value = getproperty(obj,k)
        type = typeof(value)
        if parentmodule(type)==EasyMLDesign
            dict_current = Dict{Symbol,Any}()
            dict[k] = dict_current
            struct_to_dict!(dict_current,value)
        elseif value isa Vector && !isempty(value) && parentmodule(eltype(type))==EasyMLDesign
            types = typeof.(value)
            dict_vec = Vector{Dict{Symbol,Any}}(undef,0)
            for obj_for_vec in value
                dict_for_vec = Dict{Symbol,Any}()
                struct_to_dict!(dict_for_vec,obj_for_vec)
                push!(dict_vec,dict_for_vec)
            end
            data_tuple = (vector_type = type, types = types, values = dict_vec)
            dict[k] = data_tuple
        else
            dict[k] = value
        end
    end
    return nothing
end

function dict_to_struct!(obj,dict::Dict)
    ks = [keys(dict)...]
    for i = 1:length(ks)
        ks_cur = ks[i]
        sym = Symbol(ks_cur)
        value = dict[ks_cur]
        obj_property = getproperty(obj,sym)
        obj_type = typeof(obj_property)
        if value isa Dict
            dict_to_struct!(obj_property,value)
        elseif obj_property isa Vector && parentmodule(eltype(obj_type))==EasyMLDesign
            if !isempty(value)
                vector_type = getindex(value,:vector_type) 
                types = getindex(value,:types) 
                values = getindex(value,:values) 
                struct_vec = vector_type(undef,0)
                for j = 1:length(types)
                    obj_for_vec = types[j]()
                    dict_for_vec = values[j]
                    dict_to_struct!(obj_for_vec,dict_for_vec)
                    push!(struct_vec,obj_for_vec)
                end
                setproperty!(obj,sym,struct_vec)
            end
        else
            if hasfield(typeof(obj),sym)
                setproperty!(obj,sym,value)
            end
        end
    end
    return nothing
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
    type = eltype(ar)
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
    type = eltype(x)
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

function make_dir(target_dir::String)
    dirs = split(target_dir,('/','\\'))
    for i=1:length(dirs)
        temp_path = join(dirs[1:i],'\\')
        if !isdir(temp_path)
            mkdir(temp_path)
        end
    end
    if !isdir(target_dir)
        mkdir(target_dir)
    end
    return nothing
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

function max_num_threads()
    return length(Sys.cpu_info())
end

function check_task(t::Task)
    if istaskdone(t)
        if t.:_isexception
            return :error, t.:result
        else
            return :done, nothing
        end
    else
        return :running, nothing
    end
end