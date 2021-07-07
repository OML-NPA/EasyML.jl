
#---Set up----------------------------------------------------------------------

model_count() = length(model_data.layers_info)

function get_max_id_main(model_data::ModelData)
    if length(model_data.layers_info)>0
        ids = map(x-> x.id, model_data.layers_info)
        return maximum(ids)
    else
        return 0
    end
end
get_max_id() = get_max_id_main(model_data)

model_properties(index) = string.(collect(fieldnames(typeof(model_data.layers_info[Int64(index)]))))

function model_get_layer_property_main(model_data::ModelData,index,property_name)
    layer_info = model_data.layers_info[Int64(index)]
    property = getfield(layer_info,Symbol(property_name))
    if typeof(property) <: Tuple
        return collect(property)
    end
    return property
end
model_get_layer_property(index,property_name) =
    model_get_layer_property_main(model_data,index,property_name)


function reset_layers_main(design_data::DesignData)
    empty!(design_data.ModelData.layers_info)
    return nothing
end
reset_layers() = reset_layers_main(design_data::DesignData)


#---Model import form QML----------------------------------------------------------------

function get_layer_info(layer_name::String)
    if layer_name=="Input"
        return InputInfo()
    elseif layer_name=="Output"
        return OutputInfo()
    elseif layer_name=="Convolution"
        return ConvInfo()
    elseif layer_name=="Transposed convolution"
        return TConvInfo()
    elseif layer_name=="Dense"
        return DenseInfo()
    elseif layer_name=="Drop-out"
        return DropoutInfo()  
    elseif layer_name=="Batch normalisation"
        return BatchNormInfo()
    elseif layer_name=="Leaky ReLU"
        return LeakyReLUInfo()
    elseif layer_name=="ELU"
        return ELUInfo()  
    elseif layer_name=="Max pooling" || layer_name=="Average pooling"
        return PoolInfo()
    elseif layer_name=="Addition"
        return AdditionInfo()  
    elseif layer_name=="Join"
        return JoinInfo()  
    elseif layer_name=="Split"
        return SplitInfo()  
    elseif layer_name=="Upsample"
        return UpsampleInfo()  
    else 
        return GenericInfo()
    end
end

function update_layers_main(design_data::DesignData,fields,values)
    layers_info = design_data.ModelData.layers_info
    fields = fix_QML_types(fields)
    values = fix_QML_types(values)
    layer_info = get_layer_info(values[8])
    for i = 1:length(fields)
        value_raw = values[i]
        field = Symbol(fields[i])
        type = typeof(getfield(layer_info,field))
        if type <: Tuple
            eltypes = type.parameters
            l = length(eltypes)
            if layer_info isa InputInfo
                if length(value_raw)==2
                    push!(value_raw,1)
                end
            elseif length(eltypes)!=length(value_raw)
                if value_raw isa Array
                    value_raw = repeat(value_raw,l)
                else
                    value_raw = repeat([value_raw],l)
                end
            end
            value_array = map((T,x)->convert(T,x),eltypes,value_raw)
            value = Tuple(value_array)
        elseif (type<:Number) && (value_raw isa String)
            value = parse(type,value_raw)
        else
            value = convert(type,value_raw)
        end
        setfield!(layer_info,field,value)
    end
    push!(layers_info,layer_info)
    return nothing
end
update_layers(fields,values) = update_layers_main(design_data::DesignData,
    fields,values)


#---Topology constructors----------------------------------------------------------------

function topology_linear(layers_arranged::Vector,inds_arranged::Vector,
        layers::Vector{AbstractLayerInfo},connections::Vector{Array{Vector{Int64}}},
        types::Vector{String},ind)
    push!(layers_arranged,layers[ind])
    push!(inds_arranged,ind)
    ind = connections[ind]
    return ind
end

function topology_split(layers_arranged::Vector,inds_arranged::Vector,
        layers::Vector{AbstractLayerInfo},connections::Vector{Array{Vector{Int64}}},
        connections_in::Vector{Vector{Int64}},types::Vector{String},ind)
    types_all = map(i -> types[i],ind)
    joining_types_bool = map(type -> all(type=="Join") || all(type=="Addition"),types_all)
    num = length(ind)
    par_inds = []
    inds_return = []
    par_layers_arranged = []
    next_connections = connections[ind]
    unique_connections = unique(next_connections)
    if (length(unique_connections)!=length(ind)) && length(unique_connections)>1
        ind_new = Vector{Vector}(undef, 0)
        joining_types_bool_new = []
        con = unique_connections[1]
        for con in unique_connections
            bool_inds = map(next_con -> next_con==con,next_connections)
            new_cons = ind[bool_inds]
            push!(ind_new,new_cons)
            push!(joining_types_bool_new,joining_types_bool[bool_inds][1])
        end
        ind = ind_new
        joining_types_bool = joining_types_bool_new
        num = length(ind_new)
    end
    for i = 1:num
        layers_temp = []
        inds_temp = []
        if joining_types_bool[i] && !allcmp(next_connections)
            push!(inds_return,[ind[i]])
            push!(inds_temp,0)
        else
            if ind isa Vector{<:Vector}
                ind_temp = [ind[i]]
            else
                ind_temp = [[ind[i]]]
            end
            ind_out = get_topology_branches(layers_temp,inds_temp,layers,
            connections,connections_in,types,ind_temp)[1]
            push!(inds_return,ind_out)
            type = types[inds_return[i][1]]
            if type != "Join" && type != "Addition"
                return
                # Do not support this
            end
        end
        push!(par_layers_arranged,layers_temp)
        push!(par_inds,inds_temp)
    end
    push!(layers_arranged,par_layers_arranged)
    push!(inds_arranged,par_inds)
    return inds_return
end

function get_topology_branches(layers_arranged::Vector,inds_arranged::Vector,
        layers::Vector{AbstractLayerInfo},connections::Vector{Array{Vector{Int64}}},
        connections_in::Vector{Vector{Int64}},types::Vector{String},ind)
    while !isempty.([ind])[1]
        numk = length(ind)
        if numk==1
            if any(map(x -> x.=="Join" || x.=="Addition",types[vcat(vcat(ind...)...)]))
                if length(ind)==1 && length(ind[1])>1 
                    ind = topology_split(layers_arranged,inds_arranged,layers,
                        connections,connections_in,types,ind[1])
                elseif length(ind)>1 && allcmp(ind[1])
                    ind_in_actual = connections_in[ind[1][1]]
                    ind_in_arranged = vcat(vcat(inds_arranged[end]...)...)
                    ind_0 = findfirst(ind_in_arranged.==0)
                    if !isempty(ind_0)
                        ind_in_arranged[ind_0] = vcat(vcat(inds_arranged[end-1]...)...)
                    end
                    inds_to_use = map(x -> findfirst(x.==ind_in_actual),ind_in_arranged)
                    if inds_to_use!=1:length(inds_to_use)
                        layers_arranged[end] = layers_arranged[end][inds_to_use]
                        inds_arranged[end] = inds_arranged[end][inds_to_use]
                    end
                    ind = topology_linear(layers_arranged,inds_arranged,
                            layers,connections,types,ind[1][1])
                else
                    return ind
                end
            else
                if length(ind[1])==1
                    ind = topology_linear(layers_arranged,inds_arranged,
                        layers,connections,types,ind[1][1])
                else
                    ind = topology_split(layers_arranged,inds_arranged,layers,
                        connections,connections_in,types,ind[1])
                end
            end
        else
            if any(map(x -> x.=="Join" || x.=="Addition",types[vcat(vcat(ind...)...)]))
                if length(ind)>1 && allcmp(ind)
                    ind_in_actual = connections_in[ind[1][1]]
                    ind_in_arranged_raw = inds_arranged[end]
                    ind_in_arranged = Vector{Int64}(undef,length(ind_in_actual))
                    for i = 1:length(ind_in_actual)
                        ind_current = ind_in_arranged_raw[i]
                        while true
                            if ind_current isa Vector
                                ind_current = ind_current[end]
                            else
                                break
                            end
                        end
                        ind_in_arranged[i] = ind_current
                    end
                    ind_0 = findfirst(ind_in_arranged.==0)
                    if !isnothing(ind_0)
                        ind_in_arranged[ind_0] = vcat(vcat(inds_arranged[end-1]...)...)[1]
                    end
                    inds_to_use = map(x -> findfirst(x.==ind_in_actual),ind_in_arranged)
                    if inds_to_use!=1:length(inds_to_use)
                        layers_arranged[end] = layers_arranged[end][inds_to_use]
                        inds_arranged[end] = inds_arranged[end][inds_to_use]
                    end
                    ind = topology_linear(layers_arranged,inds_arranged,
                                layers,connections,types,ind[1][1])
                elseif all(length.(ind).==1)
                    ind = topology_split(layers_arranged,inds_arranged,layers,
                        connections,connections_in,types,vcat(ind...))
                else
                    return
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
    end
    return ind
end

function get_topology(model_data::ModelData)
    layers = model_data.layers_info
    types = [layers[i].type for i = 1:length(layers)]
    ind_vec = findall(types .== "Input")
    if isempty(ind_vec)
        msg = "No input layer."
        @error msg
        push!(design_data.warnings,msg)
        return nothing,nothing
    elseif length(ind_vec)>1
        msg = "More than one input layer."
        @error msg
        push!(design_data.warnings,msg)
        return nothing,nothing
    end
    connections = Vector{Array{Vector{Int64}}}(undef,0)
    connections_in = Vector{Vector{Int64}}(undef,0)
    for i = 1:length(layers)
        push!(connections,layers[i].connections_down)
        push!(connections_in,layers[i].connections_up)
    end
    ind = ind_vec[1]
    layers_arranged = []
    inds_arranged = []
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


#---Model visual representation constructors-----------------------------------------------

function arrange_layer(coordinates::Array,coordinate::Array{Float64},
    design_options::DesignOptions)
    coordinate[2] = coordinate[2] + design_options.min_dist_y + design_options.height
    push!(coordinates,coordinate)
    return coordinate
end

function arrange_branches(coordinates,coordinate::Vector{Float64},
        design_options::DesignOptions,layers)
    num = layers isa AbstractLayerInfo ? 1 : length(layers)
    if num==1
        coordinate = arrange_layer(coordinates,copy(coordinate),design_options)
    else
        max_num = ones(Int64,num)
        for i = 1:length(layers)
            temp1 = layers[i]
            for temp2 in temp1
                if temp2 isa Vector
                    width = length(temp2)
                    if width>max_num[i]
                        max_num[i] = width
                    end
                end
            end
        end
        par_coordinates = []
        x_coordinates = []
        push!(x_coordinates,coordinate[1])
        for i=2:num
            prev_layer_right = x_coordinates[end] .+ max_num[i-1]*design_options.width .+ (max_num[i-1]-1)*design_options.min_dist_x
            current_layer_left = prev_layer_right .+ (max_num[i]-1)*design_options.width .+ max_num[i]*design_options.min_dist_x
            push!(x_coordinates,current_layer_left)
        end
        x_coordinates = x_coordinates .-
            (mean([x_coordinates[1],x_coordinates[end]])-coordinate[1])
        for i = 1:num
            temp_coordinates = []
            temp_coordinate = [x_coordinates[i],coordinate[2]]
            if isempty(layers[i])
                push!(temp_coordinates,[x_coordinates[i],coordinate[2]])
            else
                for j = 1:length(layers[i])
                    temp_coordinate = arrange_branches(temp_coordinates,temp_coordinate,
                        design_options,layers[i][j])
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

function arrange_main(design_data::DesignData,design_options::DesignOptions)
    layers_arranged,inds_arranged = get_topology(design_data.ModelData)
    coordinates = []
    coordinate = [layers_arranged[1].x,layers_arranged[1].y]
    push!(coordinates,coordinate)
    for i = 2:length(inds_arranged)
        layers = layers_arranged[i]
        coordinate = arrange_branches(coordinates,
            coordinate,design_options,layers)
    end
    coordinates_flattened = []
    get_values!(coordinates_flattened,coordinates,
        x-> x isa Array && x[1] isa Array)
    inds_flattened = []
    get_values!(inds_flattened,inds_arranged,x-> x isa Array)
    true_elements = inds_flattened.>0
    coordinates_flattened = coordinates_flattened[true_elements]
    inds_flattened = inds_flattened[true_elements]
    return [coordinates_flattened,inds_flattened.-1]
end
arrange() = arrange_main(design_data,design_options)


#---Model constructors--------------------------------------------------------------------

function getlinear(type::String, layer_info, in_size::Tuple{Int64,Int64,Int64})
    if type == "Convolution"
        layer = Conv(
            layer_info.filter_size,
            in_size[3] => layer_info.filters,
            pad = SamePad(),
            stride = layer_info.stride,
            dilation = layer_info.dilation_factor
        )
        out = outputsize(layer, (in_size...,1))[1:3]
        return (layer, out)
    elseif type == "Transposed convolution"
        layer = ConvTranspose(
            layer_info.filter_size,
            in_size[3] => layer_info.filters,
            pad = SamePad(),
            stride = layer_info.stride,
            dilation = layer_info.dilation_factor,
        )
        out = outputsize(layer, (in_size...,1))[1:3]
        return (layer, out)
    elseif type == "Dense"
        layer = Dense(in_size[1], layer_info.filters)
        out = (layer_info.filters, in_size[2:3]...)
        return (layer, out)
    end
end

function getnorm(type::String, layer_info, in_size::Tuple{Int64,Int64,Int64})
    if type == "Drop-out"
        return Dropout(layer_info.probability)
    elseif type == "Batch normalisation"
        return BatchNorm(in_size[end], ϵ = Float32(layer_info.epsilon))
    end
end

function getactivation(type::String, layer_info, in_size::Tuple{Int64,Int64,Int64})
    if type == "ReLU"
        return Activation(relu)
    elseif type == "Laeky ReLU"
        return Activation(leakyrelu)
    elseif type == "ELU"
        return Activation(elu)
    elseif type == "Tanh"
        return Activation(tanh)
    elseif type == "Sigmoid"
        return Activation(sigmoid)
    end
end

function getpooling(type::String, layer_info, in_size::Tuple{Int64,Int64,Int64})
    poolsize = layer_info.poolsize
    stride = layer_info.stride
    temp_layer = MaxPool(poolsize, stride=2)
    if type == "Max pooling"
        layer = MaxPool(poolsize, stride=stride, pad=SamePad())
    elseif type == "Average pooling"
        layer = MeanPool(poolsize, stride=stride, pad=SamePad())
    end
    out12 = in_size./stride
    out = (Int64(out12[1]),Int64(out12[2]),in_size[3])
    return (layer,out)
end

function getresizing(type::String, layer_info, in_size)
    if type == "Addition"
        out = (in_size[1][1], in_size[1][2], in_size[1][3])
        return (Addition(), out)
    elseif type == "Join"
        new_size = Array{Int64}(undef, length(in_size))
        dim = layer_info.dimension
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
        dim = layer_info.dimension
        nout = layer_info.outputs
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
        multiplier = layer_info.multiplier
        dims = layer_info.dimensions
        out = [in_size...]
        for i in dims
            out[i] = out[i] * multiplier
        end
        out = (out...,)
        return (Upsample(scale = multiplier), out)
    elseif type == "Flatten"
        out = (prod(in_size), 1, 1)
        return (Flatten(), out)
    end
end

function getlayer(layer, in_size)
    if layer.group == "linear"
        layer_f, out = getlinear(layer.type, layer, in_size)
    elseif layer.group == "norm"
        layer_f = getnorm(layer.type, layer, in_size)
        out = in_size
    elseif layer.group == "activation"
        layer_f = getactivation(layer.type, layer, in_size)
        out = in_size
    elseif layer.group == "pooling"
        layer_f, out = getpooling(layer.type, layer, in_size)
    elseif layer.group == "resizing"
        layer_f, out = getresizing(layer.type, layer, in_size)
    end
    return (layer_f, out)
end

function getbranch(layer_params,in_size)
    num = layer_params isa AbstractLayerInfo ? 1 : length(layer_params)
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
                    if isnothing(layer)
                        return nothing,nothing
                    end
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
            msg = "Inputs to a parallel layer have different sizes."
            @error msg
            push!(design_data.warnings,msg)
            return nothing,nothing
        end
    end
    return layer,in_size
end

function make_model_main(design_data::DesignData)
    model_data_design = design_data.ModelData
    layers_arranged,_ = get_topology(model_data_design)
    if isnothing(layers_arranged)
        msg = "Something went wrong during model topology analysis."
        @error msg
        push!(design_data.warnings, msg)
        return false
    elseif layers_arranged[end].type!="Output"
        msg = "No output layer."
        @error msg
        push!(design_data.warnings, msg)
        return false
    end
    in_size = (layers_arranged[1].size...,)
    model_data_design.input_size = in_size
    popfirst!(layers_arranged)
    loss_name = layers_arranged[end].loss[1]
    model_data_design.loss = get_loss(loss_name)
    pop!(layers_arranged)
    model_layers = []
    for i = 1:length(layers_arranged)
        layer_params = layers_arranged[i]
        layer,in_size = getbranch(layer_params,in_size)
        if isnothing(layer)
            msg = "Something went wrong during Flux model creation."
            @error msg
            push!(design_data.warnings, msg)
            return false
        end
        push!(model_layers,layer)
    end
    model_data_design.model = Chain(model_layers...)
    return true
end
make_model() = make_model_main(design_data)

function check_model_main(design_data::DesignData)
    model_data_design = design_data.ModelData
    input = zeros(Float32,model_data.input_size...,1)
    try
        output = model_data_design.model(input)
        output_size = size(output)[1:end-1]
        model_data_design.output_size = output_size
        if problem_type()==:Classification && length(output_size)!=1
            @error "Use flatten before an output. Otherwise, the model will not function correctly."
            push!(design_data.warnings,"Use flatten before an output. Otherwise, the model will not function correctly.")
            return false
        end
    catch e
        @error e
        push!(design_data.warnings,"Something is wrong with your model.")
        return false
    end
end
check_model() = check_model_main(design_data)

function move_model_main(model_data::ModelData,design_data::DesignData)
    model_data2 = design_data.ModelData
    model_data.model = deepcopy(model_data2.model)
    model_data.layers_info = deepcopy(model_data2.layers_info)
    model_data.input_size = model_data2.input_size
    model_data.output_size = model_data2.output_size
    model_data.loss = model_data2.loss
    design_data.ModelData = ModelData()
end
move_model() = move_model_main(model_data,design_data)


#---Losses---------------------------------------------------------------------

function get_loss(loss_name::String)
    if loss_name == "MAE"
        return Losses.mae
    elseif loss_name == "MSE"
        return Losses.mse
    elseif loss_name == "MSLE"
        return Losses.msle
    elseif loss_name == "Huber"
        return Losses.huber_loss
    elseif loss_name == "Crossentropy"
        return Losses.crossentropy
    elseif loss_name == "Logit crossentropy"
        return Losses.logitcrossentropy
    elseif loss_name == "Binary crossentropy"
        return Losses.binarycrossentropy
    elseif loss_name == "Logit binary crossentropy"
        return Losses.logitbinarycrossentropy
    elseif loss_name == "Kullback-Leiber divergence"
        return Losses.kldivergence
    elseif loss_name == "Poisson"
        return Losses.poisson_loss
    elseif loss_name == "Hinge"
        return Losses.hinge_loss
    elseif loss_name == "Squared hinge"
        return squared_hinge_loss
    elseif loss_name == "Dice coefficient"
        return Losses.dice_coeff_loss
    elseif loss_name == "Tversky"
        return Losses.tversky_loss
    end
end


#---Problem type handling-------------------------------------------------------------

function set_problem_type(ind)
    ind = fix_QML_types(ind)
    if ind==0 
        model_data.problem_type = :Classification
    elseif ind==1
        model_data.problem_type = :Regression
    elseif ind==2
        model_data.problem_type = :Segmentation
    end
    return nothing
end

function get_problem_type()
    if problem_type()==:Classification
        return 0
    elseif problem_type()==:Regression
        return 1
    elseif problem_type()==:Segmentation
        return 2
    end
end


#---Other----------------------------------------------------------------------

# Make urls QML compatible
function fix_slashes(url)
    url::String = fix_QML_types(url)
    url = replace(url, "\\" => "/")
    url = string(uppercase(url[1]),url[2:end])
end

source_dir() = fix_slashes(pwd())

function allcmp(inds)
    for i = 1:length(inds)
        if inds[1][1] != inds[i][1]
            return false
        end
    end
    return true
end
