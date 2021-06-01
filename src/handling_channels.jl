
# Return values from progress channels without taking the values
function check_progress_main(channels::Channels,field)
    field::String = fix_QML_types(field)
    if field=="Training data preparation"
        channel_temp = channels.training_data_progress
    elseif field=="Validation data preparation"
        channel_temp = channels.validation_data_progress
    elseif field=="Training"
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
    if field=="Training data preparation"
        channel_temp = channels.training_data_progress
    elseif field=="Validation data preparation"
        channel_temp = channels.validation_data_progress
    elseif field=="Application data preparation"
        channel_temp = channels.application_data_progress
    elseif field=="Training"
        channel_temp = channels.training_progress
    elseif field=="Validation"
        channel_temp = channels.validation_progress
    elseif field=="Application"
        channel_temp = channels.application_progress
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
    features = model_data.features
    if field=="Training data preparation"
        if isready(channels.training_data_results)
            data = take!(channels.training_data_results)
            if features isa Vector{Classification_feature}
                classification_data = master_data.Training_data.Classification_data
                classification_data.data_input = data[1]
                classification_data.data_labels = data[2]
            elseif features isa Vector{Segmentation_feature}
                segmentation_data = master_data.Training_data.Segmentation_data
                segmentation_data.data_input = data[1]
                segmentation_data.data_labels = data[2]
            end
            return true
        else
            return false
        end
    elseif field=="Training"
        if isready(channels.training_results)
            data = take!(channels.training_results)
            if !isnothing(data)
                training_results_data = master_data.Training_data.Results
                model_data.model = data[1]
                training_results_data.accuracy = data[2]
                training_results_data.loss = data[3]
                training_results_data.test_accuracy = data[4]
                training_results_data.test_loss = data[5]
                training_results_data.test_iteration = data[6]
                save_model(training.model_url)
            end
            return true
        else
            return false
        end
    elseif field=="Validation"
        if isready(channels.validation_results)
            if model_data.features isa Vector{Segmentation_feature}
                data = take!(channels.validation_results)
                validation_results = master_data.Validation_data.Results_segmentation
                image_data = data[1]
                other_data = data[2]
                original = data[3]
                push!(validation_results.original,original)
                push!(validation_results.predicted_data,image_data[1])
                push!(validation_results.target_data,image_data[2])
                push!(validation_results.error_data,image_data[3])
                push!(validation_results.other_data,other_data)
            end
            return [other_data...]
        else
            return false
        end
    elseif field=="Labels colors"
        if isready(channels.training_labels_colors)
            data = take!(channels.training_labels_colors)
            return data
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
    if field=="Training data preparation"
        channel_temp = channels.training_data_progress
    elseif field=="Validation data preparation"
        channel_temp = channels.validation_data_progress
    elseif field=="Application data preparation"
        channel_temp = channels.application_data_progress
    elseif field=="Training data preparation modifiers"
        channel_temp = channels.training_data_modifiers
    elseif field=="Validation data preparation modifiers"
        channel_temp = channels.validation_data_modifiers
    elseif field=="Training"
        channel_temp = channels.training_progress
    elseif field=="Validation"
        channel_temp = channels.validation_progress
    elseif field=="Application"
        channel_temp = channels.application_progress
    elseif field=="Training modifiers"
        channel_temp = channels.training_modifiers
    elseif field=="Validation modifiers"
        channel_temp = channels.validation_modifiers
    elseif field=="Application modifiers"
        channel_temp = channels.application_modifiers
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
    if field=="Training data preparation"
        channel_temp = channels.training_data_results
    elseif field=="Validation data preparation"
        channel_temp = channels.validation_data_results
    elseif field=="Application data preparation"
        channel_temp = channels.application_data_results
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
    if field=="Training data preparation"
        put!(channels.training_data_modifiers,value)
    elseif field=="Validation data preparation"
        put!(channels.validation_data_modifiers,value)
    elseif field=="Training"
        put!(channels.training_modifiers,value)
    elseif field=="Validation"
        put!(channels.validation_modifiers,value)
    end
end
put_channel(field,value) = put_channel_main(channels,field,value)
