
function set_problem_type(ind)
    ind = fix_QML_types(ind)
    if ind==0 
        model_data.problem_type = :classification
    elseif ind==1
        model_data.problem_type = :regression
    else # ind==2
        model_data.problem_type = :segmentation
    end
    return nothing
end

function get_problem_type()
    if problem_type()==:classification
        return 0
    elseif problem_type()==:regression
        return 1
    else # problem_type()==:segmentation
        return 2
    end
end

function get_input_type()
    return 0
end