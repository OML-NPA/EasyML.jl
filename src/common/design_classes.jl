
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