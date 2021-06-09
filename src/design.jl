
#---Layer constructors
function getlinear(type::String, d, in_size::Tuple{Int64,Int64,Int64})
    if type == "Convolution"
        layer = Conv(
            d["filtersize"],
            in_size[3] => d["filters"],
            pad = SamePad(),
            stride = d["stride"],
            dilation = d["dilationfactor"]
        )
        out = outdims(layer, (in_size...,1))[1:3]
        return (layer, out)
    elseif type == "Transposed convolution"
        layer = ConvTranspose(
            d["filtersize"],
            in_size[3] => d["filters"],
            pad = SamePad(),
            stride = d["stride"],
            dilation = d["dilationfactor"],
        )
        out = outdims(layer, (in_size...,1))[1:3]
        return (layer, out)
    elseif type == "Dense"
        layer = Dense(in_size, d["filters"])
        out = (d["filters"], in[2:3])
        return (layer, out)
    end
end

function getnorm(type::String, d, in_size::Tuple{Int64,Int64,Int64})
    if type == "Drop-out"
        return Dropout(d["probability"])
    elseif type == "Batch normalisation"
        return BatchNorm(in_size[end], ϵ = Float32(d["epsilon"]))
    end
end

function getactivation(type::String, d, in_size::Tuple{Int64,Int64,Int64})
    if type == "RelU"
        return Activation(relu)
    elseif type == "Laeky RelU"
        return Activation(leakyrelu)
    elseif type == "ElU"
        return Activation(elu)
    elseif type == "Tanh"
        return Activation(tanh)
    elseif type == "Sigmoid"
        return Activation(sigmoid)
    end
end

function getpooling(type::String, d, in_size::Tuple{Int64,Int64,Int64})
    poolsize = d["poolsize"]
    stride = d["stride"]
    temp_layer = MaxPool(poolsize, stride=2)
    out = outdims(Chain(temp_layer),(in_size...,1))[1:3]
    dif = Int64.(in_size[1:2]./2 .- out[1:2])
    if type == "Max pooling"
        layer = MaxPool(poolsize, stride=stride, pad=(0,dif[1],dif[2],0))
    elseif type == "Average pooling"
        layer = MeanPool(poolsize, stride=stride, pad=(0,dif[1],dif[2],0))
    end
    return (layer,out)
end

function getresizing(type::String, d, in_size)
    if type == "Addition"
        out = (in_size[1][1], in_size[1][2], in_size[1][3])
        return (Addition(), out)
    elseif type == "Join"
        new_size = Array{Int64}(undef, length(in_size))
        dim = d["dimension"]
        for i = 1:length(in_size)
            new_size[i] = in_size[i][dim]
        end
        new_size = sum(new_size)
        if dim == 1
            out = (new_size, in_size[1][2], in_size[1][3])
        elseif dim == 2
            out = (in_size[1][1], new_size, in_size[1][3])
        elseif dim == 3
            out = (in_size[1][1], in_size[1][2], new_size)
        end
        return (Join(dim), out)
    elseif type == "Split"
        dim = d["dimension"]
        nout = d["outputs"]
        out = Array{Tuple{Int64,Int64,Int64}}(undef, nout)
        if dim == 1
            for i = 1:nout
                out[i] = (in_size[1] / nout, in_size[2:3]...)
            end
        elseif dim == 2
            for i = 1:nout
                out[i] = (in_size[1], in_size[2] / nout, in_size[3])
            end
        elseif dim == 3
            for i = 1:nout
                out[i] = (in_size[1], in_size[2], in_size[3] / nout)
            end
        end
        return (Split(nout, dim), out)
    elseif type == "Upsample"
        multiplier = d["multiplier"]
        dims = d["dimensions"]
        out = [in_size...]
        for i in dims
            out[i] = out[i] * multiplier
        end
        out = (out...,)
        return (Upsample(scale = multiplier), out)
    elseif type == "Flattening"
        out = (prod(size(x)), 1, 1)
        return (x -> Flux.flatten(x), out)
    end
end

function getlayer(layer, in_size)
    if layer["group"] == "linear"
        layer_f, out = getlinear(layer["type"], layer, in_size)
    elseif layer["group"] == "norm"
        layer_f = getnorm(layer["type"], layer, in_size)
        out = in_size
    elseif layer["group"] == "activation"
        layer_f = getactivation(layer["type"], layer, in_size)
        out = in_size
    elseif layer["group"] == "pooling"
        layer_f, out = getpooling(layer["type"], layer, in_size)
    elseif layer["group"] == "resizing"
        layer_f, out = getresizing(layer["type"], layer, in_size)
    end
    return (layer_f, out)
end

#---Topology constructors
function topology_linear(layers_arranged::Vector,inds_arranged::Vector,
        layers::Vector{Dict{String,Any}},connections::Vector{Array{Vector{Int64}}},
        types::Vector{String},ind)
    push!(layers_arranged,layers[ind])
    push!(inds_arranged,ind)
    ind = connections[ind]
    return ind
end

function topology_split(layers_arranged::Vector,inds_arranged::Vector,
        layers::Vector{Dict{String,Any}},connections::Vector{Array{Vector{Int64}}},
        connections_in::Vector{Vector{Int64}},types::Vector{String},ind)
    num = length(ind)
    par_inds = Vector(undef,num)
    fill!(par_inds,[])
    inds_return = Array{Array}(undef, num)
    par_layers_arranged = Vector(undef,num)
    fill!(par_layers_arranged,[])
    for i = 1:num
        layers_temp = Vector(undef,0)
        inds_temp = Vector(undef,0)
        ind_temp = [[ind[i]]]
        inds_return[i] = get_topology_branches(layers_temp,inds_temp,layers,
            connections,connections_in,types,ind_temp)[1]
        type = types[inds_return[i][1]]
        if isempty(inds_temp)
            inds_temp = [0]
        end
        if (type=="Join" || type=="Addition") && isnothing(inds_temp[1])
            # Happens if one of input nodes is empty
        else
            par_layers_arranged[i] = layers_temp
            par_inds[i] = inds_temp
        end
    end
    push!(layers_arranged,par_layers_arranged)
    push!(inds_arranged,par_inds)
    return inds_return
end

function get_topology_branches(layers_arranged::Vector,inds_arranged::Vector,
        layers::Vector{Dict{String,Any}},connections::Vector{Array{Vector{Int64}}},
        connections_in::Vector{Vector{Int64}},types::Vector{String},ind)
    while !isempty.([ind])[1]
        numk = length(ind)
        if any(map(x -> x.=="Join" ||
                x.=="Addition",types[vcat(vcat(ind...)...)]))
            if all(length.(ind).==1) && allcmp(ind) &&
                    length(ind)==length(connections_in[ind[1][1][1]])
                prev_ind = ind[1][1][1]
                to_arrange_inds = map(x->x[end],inds_arranged[end])
                inds_zero = findall(map(x-> x[1]==0,to_arrange_inds))
                if length(inds_zero)>0
                    to_arrange_inds[inds_zero] .= inds_arranged[end-1]
                end
                input_inds = connections_in[prev_ind]

                inds_rearrange = map(x->
                    findfirst(x.==input_inds),to_arrange_inds)
                inds_arranged[end] = inds_arranged[end][inds_rearrange]
                layers_arranged[end] = layers_arranged[end][inds_rearrange]
                push!(layers_arranged,layers[prev_ind])
                push!(inds_arranged,prev_ind)
                ind = connections[prev_ind]
                continue
            elseif length(ind[1])==1
                return ind
            end
        end
        if numk==1
            if length(ind[1])==1
                ind = topology_linear(layers_arranged,inds_arranged,
                    layers,connections,types,ind[1][1])
            else
                ind = topology_split(layers_arranged,inds_arranged,layers,
                    connections,connections_in,types,ind[1])
            end
        else
            if all(length.(ind).==1)
                ind = topology_split(layers_arranged,inds_arranged,layers,
                    connections,connections_in,types,vcat(ind...))
            else
                return ind
            end
        end
    end
    return ind
end

function get_topology_main(model_data::ModelData)
    layers = model_data.layers
    types = [layers[i]["type"] for i = 1:length(layers)]
    connections = Vector{Array{Vector{Int64}}}(undef,0)
    connections_in = Vector{Vector{Int64}}(undef,0)
    for i = 1:length(layers)
        push!(connections,layers[i]["connections_down"])
        push!(connections_in,layers[i]["connections_up"])
    end
    ind = findfirst(types .== "Input")
    if isempty(ind)
        @info "no input layer"
        return "no input layer"
    elseif length(ind)>1
        @info "more than one input layer"
        return "more than one input layer"
    end
    ind_output = findfirst(types .== "Output")
    if ind_output!==nothing && length(ind_output)>1
        @info "more than one output layer"
        return "more than one output layer"
    end
    layers_arranged = Vector(undef,0)
    inds_arranged = Vector(undef,0)
    push!(layers_arranged,layers[ind])
    push!(inds_arranged,ind)
    ind = connections[ind]
    ind = get_topology_branches(layers_arranged,inds_arranged,layers,
        connections,connections_in,types,ind)
    if isempty(inds_arranged[end])
        inds_arranged = inds_arranged[1:end-1]
    end
    return layers_arranged, inds_arranged
end
get_topology() = get_topology_main(model_data)

#---Model constructors
function getbranch(layer_params,in_size)
    num = layer_params isa Dict ? 1 : length(layer_params)
    if num==1
        layer, in_size = getlayer(layer_params, in_size)
    else
        par_layers = []
        par_size = []
        for i = 1:num
            if in_size isa Array
                temp_size = in_size[i]
            else
                temp_size = in_size
            end
            if isempty(layer_params[i])
                temp_layers = [Identity()]
            else
                temp_layers = []
                for j = 1:length(layer_params[i])
                    layer,temp_size = getbranch(layer_params[i][j],temp_size)
                    push!(temp_layers,layer)
                end
            end
            if length(temp_layers)>1
                push!(par_layers,Chain(temp_layers...))
            else
                push!(par_layers,temp_layers[1])
            end
            push!(par_size,temp_size)
        end
        layer = Parallel(tuple,(par_layers...,))
        if allcmp(par_size)
            in_size = par_size
        else
            return @info "incorrect size"
        end
    end
    return layer,in_size
end

function make_model_main(model_data::ModelData)
    layers_arranged,_ = get_topology()
    if layers_arranged isa String
        return @info "not supported"
    end
    in_size = (layers_arranged[1]["size"]...,)
    model_data.input_size = in_size
    popfirst!(layers_arranged)
    loss_name = layers_arranged[end]["loss"][1]
    model_data.loss = get_loss(loss_name)
    pop!(layers_arranged)
    model_layers = []
    for i = 1:length(layers_arranged)
        layer_params = layers_arranged[i]
        layer,in_size = getbranch(layer_params,in_size)
        push!(model_layers,layer)
    end
    model_data.model = Chain(model_layers...)
    return nothing
end
make_model() = make_model_main(model_data)

#---Model visual representation constructors
function arrange_layer(coordinates::Array,coordinate::Array{Float64},
    parameters::Design)
    coordinate[2] = coordinate[2] + parameters.min_dist_y + parameters.height
    push!(coordinates,copy(coordinate))
    return coordinate
end

function arrange_branches(coordinates,coordinate::Vector{Float64},
        parameters::Design,layers_arranged)
    num = layers_arranged isa Dict ? 1 : length(layers_arranged)
    if num==1
        coordinate = arrange_layer(coordinates,coordinate,parameters)
    else
        par_coordinates = []
        x_coordinates = []
        push!(x_coordinates,coordinate[1])
        num2 = num-1
        for i=1:num2
            push!(x_coordinates,coordinate[1].+
                (i+1+(i-1))*parameters.min_dist_x+i*parameters.width)
        end
        x_coordinates = x_coordinates .-
            (mean([x_coordinates[1],x_coordinates[end]])-coordinate[1])
        for i = 1:num
            temp_coordinates = []
            temp_coordinate = [x_coordinates[i],coordinate[2]]
            if isempty(layers_arranged[i])
                push!(temp_coordinates,[x_coordinates[i],coordinate[2]])
            else
                for j = 1:length(layers_arranged[i])
                    temp_coordinate = arrange_branches(temp_coordinates,temp_coordinate,
                        parameters,layers_arranged[i][j])
                end
            end
            push!(par_coordinates,temp_coordinates)
        end
        push!(coordinates,copy(par_coordinates))
        coordinate = [coordinate[1],
            maximum(map(x-> x[end],map(x -> x[end],par_coordinates)))]
    end
    return coordinate
end

function get_values!(values::Array,array::Array,cond_fun)
    for i=1:length(array)
        temp = array[i]
        if cond_fun(temp)
            get_values!(values,temp,cond_fun)
        else
            push!(values,temp)
        end
    end
    return nothing
end

function arrange_main(design::Design)
    parameters = design
    layers_arranged,inds_arranged = get_topology()
    coordinates = []
    coordinate = [layers_arranged[1]["x"],layers_arranged[1]["y"]-
        (design.height+design.min_dist_y)]
    for i = 1:length(inds_arranged)
        coordinate = arrange_branches(coordinates,
            coordinate,parameters,layers_arranged[i])
    end
    coordinates_flattened = []
    get_values!(coordinates_flattened,coordinates,
        x-> x isa Array && x[1] isa Array)
    inds_flattened = []
    get_values!(inds_flattened,inds_arranged,x-> x isa Array)
    coordinates_flattened = coordinates_flattened[inds_flattened.>0]
    inds_flattened = inds_flattened[inds_flattened.>0]
    return [coordinates_flattened,inds_flattened.-1]
end
arrange() = arrange_main(design)

#---Losses
function get_loss(name::String)
    if name == "MAE"
        return Losses.mae
    elseif name == "MSE"
        return Losses.mse
    elseif name == "MSLE"
        return Losses.msle
    elseif name == "Huber"
        return Losses.huber_loss
    elseif name == "Crossentropy"
        return Losses.crossentropy
    elseif name == "Logit crossentropy"
        return Losses.logitcrossentropy
    elseif name == "Binary crossentropy"
        return Losses.binarycrossentropy
    elseif name == "Logit binary crossentropy"
        return Losses.logitbinarycrossentropy
    elseif name == "Kullback-Leiber divergence"
        return Losses.kldivergence
    elseif name == "Poisson"
        return Losses.poisson_loss
    elseif name == "Hinge"
        return Losses.hinge_loss
    elseif name == "Squared hinge"
        return squared_hinge_loss
    elseif name == "Dice coefficient"
        return Losses.dice_coeff_loss
    elseif name == "Tversky"
        return Losses.tversky_loss
    end
end