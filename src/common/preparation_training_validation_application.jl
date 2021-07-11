
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