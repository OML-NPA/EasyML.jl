
#---make_classes functions---------------------------------------

function set_problem_type(ind)
    ind = fix_QML_types(ind)
    if ind==0 
        model_data.problem_type = :Classification
    elseif ind==1
        model_data.problem_type = :Regression
    else # ind==2
        model_data.problem_type = :Segmentation
    end
    return nothing
end

function get_problem_type()
    if problem_type()==:Classification
        return 0
    elseif problem_type()==:Regression
        return 1
    else # problem_type()==:Segmentation
        return 2
    end
end

function reset_classes_main(model_data)
    if problem_type()==:Classification
        model_data.classes = Vector{ImageClassificationClass}(undef,0)
    elseif problem_type()==:Regression
        model_data.classes = Vector{ImageRegressionClass}(undef,0)
    elseif problem_type()==:Segmentation
        model_data.classes = Vector{ImageSegmentationClass}(undef,0)
    end
    return nothing
end
reset_classes() = reset_classes_main(model_data::ModelData)

function append_classes_main(model_data::ModelData,data)
    data = fix_QML_types(data)
    type = eltype(model_data.classes)
    if problem_type()==:Classification
        class = ImageClassificationClass()
        class.name = data[1]
    elseif problem_type()==:Regression
        class = ImageRegressionClass()
        class.name = data[1]
    elseif problem_type()==:Segmentation
        class = ImageSegmentationClass()
        class.name = String(data[1])
        class.color = Int64.([data[2],data[3],data[4]])
        class.parents = data[5]
        class.overlap = Bool(data[6])
        class.BorderClass.enabled = Bool(data[7])
        class.BorderClass.thickness = Int64(data[8])
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
        @info data
        return data
    else
        return getproperty(model_data.classes[index],Symbol(fieldname))
    end
end
get_class_field(index,fieldname) = get_class_main(model_data,index,fieldname)
