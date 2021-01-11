
#---Layers
# Parallel layer
struct Parallel
    layers::Tuple
end
function Parallel(x::Array{Float32,4},layers::Tuple)
    result::Tuple{Array{Float32,4},Array{Float32,4}} = map(fun -> fun(x), layers)
    return result
end
function Parallel(x::CuArray{Float32,4},layers::Tuple)
    result::Tuple{CuArray{Float32,4},CuArray{Float32,4}} = map(fun -> fun(x), layers)
    return result
end
(m::Parallel)(x) = Parallel(x, m.layers)
Flux.@functor Parallel

# Concatenation layer
struct Catenation
    dims::Int64
end
(m::Catenation)(x) = cat(x..., dims = m.dims)

# Deconcatenation layer
struct Decatenation
    outputs::Int64
    dims::Int64
end
function Decatenation_func(x::Array{Float32},
        outputs::Int64, dims::Int64)
    x_out = Array{Array{Float32,4}}(undef, outputs)
    step_var = Int64(size(x, dims) / outputs)
    if dims == 1
        for i = 1:outputs
            x_out[i] = x[(1+(i-1)*step_var):(i)*step, :, :,:]
        end
    elseif dims == 2
        for i = 1:outputs
            x_out[i] = x[:, (1+(i-1)*step_var):(i)*step, :,:]
        end
    elseif dims == 3
        for i = 1:outputs
            x_out[i] = x[:, :, (1+(i-1)*step_var):(i)*step_var,:]
        end
    end
    return x_out
end
function Decatenation_func(x::CuArray{Float32,4},
        outputs::Int64, dims::Int64)
    x_out = Array{CuArray{Float32,4}}(undef, outputs)
    step_var = Int64(size(x, dims) / outputs)
    if dims == 1
        for i = 1:outputs
            x_out[i] = x[(1+(i-1)*step_var):(i)*step, :, :,:]
        end
    elseif dims == 2
        for i = 1:outputs
            x_out[i] = x[:, (1+(i-1)*step_var):(i)*step, :,:]
        end
    elseif dims == 3
        for i = 1:outputs
            x_out[i] = x[:, :, (1+(i-1)*step_var):(i)*step_var,:]
        end
    end
    return x_out
end
(m::Decatenation)(x) = Decatenation_func(x, m.outputs, m.dims)

# Addition layer
struct Addition end
(m::Addition)(x) = sum(x)

# Upscaling layer
struct Upscaling
    multiplier::Float64
    new_size::Tuple{Int64,Int64,Int64}
    dims::Union{Int64,Tuple{Int64,Int64},Tuple{Int64,Int64,Int64}}
end
function Upscaling_func(x::Union{CuArray{Float32,4},Array{Float32,4}}, multiplier::Float64,
        new_size::Tuple{Int64,Int64,Int64},
        dims::Union{Int64,Tuple{Int64,Int64},Tuple{Int64,Int64,Int64}})
    multiplier = Int64(multiplier)
    if dims == 1
        ratio = (multiplier,1,1,1)
    elseif dims == 2
        ratio = (1,multiplier,1,1)
    elseif dims == 3
        ratio = (1,1,multiplier,1)
    elseif dims == (1,2)
         ratio = (multiplier,multiplier,1,1)
    elseif dims == (1,2,3)
        ratio = (multiplier,multiplier,multiplier,1)
    end
    return upscale(x,ratio)
end
function upscale(x::Array{Float32,4},ratio::Tuple{Int64,Int64,Int64,Int64})
    s = size(x)
    h,w,c,n = s
    y = fill(1.0f0, (ratio[1], 1, ratio[2], 1, ratio[3], 1))
    z = reshape(x, (1, h, 1, w, 1, c, n))  .* y
    new_x = reshape(z, s .* ratio)
    return new_x
end
function upscale(x::CuArray{Float32,4},ratio::Tuple{Int64,Int64,Int64,Int64})
    s = size(x)
    h,w,c,n = s
    y = gpu(fill(1.0f0, (ratio[1], 1, ratio[2], 1, ratio[3], 1)))
    z = reshape(x, (1, h, 1, w, 1, c, n))  .* y
    new_x = reshape(z, s .* ratio)
    return new_x
end
(m::Upscaling)(x) = Upscaling_func(x,cpu(m.multiplier),
    cpu(m.new_size),cpu( m.dims))

# Activation layer
struct Activation
    f::Function
end
(m::Activation)(x) = m.f.(x)

struct Identity
end
(m::Identity)(x) = x
