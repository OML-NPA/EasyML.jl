
# Return values from progress channels without taking the values
function check_progress_main(channels::Channels,field)
    field::String = fix_QML_types(field)
    if field=="Training"
        channel_temp = channels.training_progress
    elseif field=="Validation"
        channel_temp = channels.validation_progress
    end
    if isready(channel_temp)
        return fetch(channel_temp)
    else
        return false
    end
end
check_progress(field) = check_progress_main(channels,field)

# Return values from progress channels by taking the values
function get_progress_main(channels::Channels,field)
    field::String = fix_QML_types(field)
    if field=="Training"
        channel_temp = channels.training_progress
    elseif field=="Validation"
        channel_temp = channels.validation_progress
    elseif field=="Analysis"
        channel_temp = channels.analysis_progress
    end
    if isready(channel_temp)
        return take!(channel_temp)
    else
        return false
    end
end
get_progress(field) = get_progress_main(channels,field)

# Return values from results channels by taking the values
function get_results_main(channels::Channels,master_data::Master_data,
        model_data::Model_data,field)
    field::String = fix_QML_types(field)
    if field=="Training"
        if isready(channels.training_results)
            data = take!(channels.training_results)
            if data!=nothing
                model_data.model = data[1]
                training_results_data.accuracy = data[2]
                training_results_data.loss = data[3]
                training_results_data.test_accuracy = data[4]
                training_results_data.test_loss = data[5]
                training_results_data.test_iterations = data[6]
            end
            return true
        else
            return false
        end
    elseif field=="Validation"
        if isready(channels.validation_results)
            data = take!(channels.validation_results)
            validation_plot_data.data_predicted = data[1]
            validation_plot_data.data_error = data[2]
            validation_plot_data.data_target = data[3]
            validation_results_data.accuracy = data[4]
            validation_results_data.loss = data[5]
            validation_results_data.accuracy_std = data[6]
            validation_results_data.loss_std = data[7]
            return [data[4],data[5],mean(data[4]),mean(data[5]),data[6],data[7]]
        else
            return false
        end
    end
    return
end
get_results(field) = get_results_main(channels,master_data,model_data,field)

#---
# Empties progress channels
function empty_progress_channel_main(channels::Channels,field)
    field::String = fix_QML_types(field)
    if field=="Training"
        channel_temp = channels.training_progress
    elseif field=="Validation"
        channel_temp = channels.validation_progress
    elseif field=="Analysis"
        channel_temp = channels.analysis_progress
    elseif field=="Training modifiers"
        channel_temp = channels.training_modifiers
    elseif field=="Validation modifiers"
        channel_temp = channels.validation_modifiers
    elseif field=="Analysis modifiers"
        channel_temp = channels.analysis_modifiers
    elseif field=="Labels colors"
        channel_temp = channels.training_labels_colors
    end
    while true
        if isready(channel_temp)
            take!(channel_temp)
        else
            return
        end
    end
end
empty_progress_channel(field) = empty_progress_channel_main(channels,field)

# Empties results channels
function empty_results_channel_main(channels::Channels,field)
    field::String = fix_QML_types(field)
    if field=="Analysis data preparation"
        channel_temp = channels.analysis_data_results
    elseif field=="Training"
        channel_temp = channels.training_results
    elseif field=="Validation"
        channel_temp = channels.validation_results
    end
    while true
        if isready(channel_temp)
            take!(channel_temp)
        else
            return nothing
        end
    end
end
empty_results_channel(field) = empty_results_channel_main(channels,field)

#---
# Puts data into modifiers channels
function put_channel_main(channels::Channels,field,value)
    field::String = fix_QML_types(field)
    value = fix_QML_types(value)
    if field=="Training"
        put!(channels.training_modifiers,value)
    elseif field=="Validation"
        put!(channels.validation_modifiers,value)
    end
end
put_channel(field,value) = put_channel_main(channels,field,value)
