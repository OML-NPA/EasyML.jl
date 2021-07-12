
#---make_classes functions---------------------------------------

function set_problem_type(ind)
    ind = fix_QML_types(ind)
    if ind==0 
        model_data.problem_type = Classification
    elseif ind==1
        model_data.problem_type = Regression
    else # ind==2
        model_data.problem_type = Segmentation
    end
    return nothing
end

function get_problem_type()
    if problem_type()==Classification
        return 0
    elseif problem_type()==Regression
        return 1
    else # problem_type()==Segmentation
        return 2
    end
end

function get_input_type()
    return 0
end

function reset_classes_main(model_data)
    if problem_type()==Classification
        model_data.classes = Vector{ImageClassificationClass}(undef,0)
    elseif problem_type()==Regression
        model_data.classes = Vector{ImageRegressionClass}(undef,0)
    elseif problem_type()==Segmentation
        model_data.classes = Vector{ImageSegmentationClass}(undef,0)
    end
    return nothing
end
reset_classes() = reset_classes_main(model_data::ModelData)

function append_classes_main(model_data::ModelData,data)
    data = fix_QML_types(data)
    type = eltype(model_data.classes)
    if problem_type()==Classification
        class = ImageClassificationClass()
        class.name = data[1]
    elseif problem_type()==Regression
        class = ImageRegressionClass()
        class.name = data[1]
    elseif problem_type()==Segmentation
        class = ImageSegmentationClass()
        class.name = String(data[1])
        class.color = Int64.([data[2],data[3],data[4]])
        class.parents = data[5]
        class.overlap = Bool(data[6])
        class.min_area = Int64(data[7])
        class.BorderClass.enabled = Bool(data[8])
        class.BorderClass.thickness = Int64(data[9])
    end
    push!(model_data.classes,class)
    return nothing
end
append_classes(data) = append_classes_main(model_data,data)

function num_classes_main(model_data::ModelData)
    return length(model_data.classes)
end
num_classes() = num_classes_main(model_data::ModelData)

function get_class_main(model_data::ModelData,index,fieldname)
    fieldname = fix_QML_types(fieldname)
    index = Int64(index)
    if fieldname isa Vector
        fieldnames = Symbol.(fieldname)
        data = model_data.classes[index]
        for field in fieldnames
            data = getproperty(data,field)
        end
        return data
    else
        return getproperty(model_data.classes[index],Symbol(fieldname))
    end
end
get_class_field(index,fieldname) = get_class_main(model_data,index,fieldname)

function get_class_data(classes::Vector{ImageSegmentationClass})
    num = length(classes)
    class_names = Vector{String}(undef,num)
    class_parents = Vector{Vector{String}}(undef,num)
    labels_color = Vector{Vector{Float64}}(undef,num)
    labels_incl = Vector{Vector{Int64}}(undef,num)
    for i=1:num
        class = classes[i]
        class_names[i] = classes[i].name
        class_parents[i] = classes[i].parents
        labels_color[i] = class.color
    end
    for i=1:num
        labels_incl[i] = findall(any.(map(x->x.==class_parents[i],class_names)))
    end
    class_inds = Vector{Int64}(undef,0)
    for i = 1:num
        if !classes[i].overlap
            push!(class_inds,i)
        end
    end
    num = length(class_inds)
    border = Vector{Bool}(undef,num)
    border_thickness = Vector{Int64}(undef,num)
    for i in class_inds
        class = classes[i]
        border[i] = class.BorderClass.enabled
        border_thickness[i] = class.BorderClass.thickness
    end
    return class_inds,labels_color,labels_incl,border,border_thickness
end