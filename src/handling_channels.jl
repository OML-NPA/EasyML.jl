
# Return values from progress channels without taking the values
function check_progress_main(channels::Channels,field)
    field::String = fix_QML_types(field)
    if field=="Training data preparation"
        channel_temp = channels.training_data_progress
    elseif field=="Testing data preparation"
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
    elseif field=="Testing data preparation"
        channel_temp = channels.testing_data_progress
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
        value_raw = take!(channel_temp)
        if value_raw isa Tuple
            value = [value_raw...]
        else
            value = value_raw
        end
        return value
    else
        return false
    end
end
get_progress(field) = get_progress_main(channels,field)

# Return values from results channels by taking the values
function get_results_main(channels::Channels,all_data::AllData,
        model_data::ModelData,field)
    field::String = fix_QML_types(field)
    if field=="Training data preparation"
        if isready(channels.training_data_results)
            data = take!(EasyML.channels.training_data_results)
            typeof(data)
            if problem_type()==:Classification
                classification_data = all_data.TrainingData.ClassificationData
                classification_data.data_input = data[1]
                classification_data.data_labels = data[2]
            elseif problem_type()==:Regression
                regression_data = all_data.TrainingData.RegressionData
                regression_data.data_input = data[1]
                regression_data.data_labels = data[2]
            elseif problem_type()==:Segmentation
                segmentation_data = all_data.TrainingData.SegmentationData
                segmentation_data.data_input = data[1]
                segmentation_data.data_labels = data[2]
            end
            return true
        else
            return false
        end
    elseif field=="Testing data preparation"
        if isready(channels.testing_data_results)
            data = take!(EasyML.channels.testing_data_results)
            if problem_type()==:Classification
                classification_data = all_data.TestingData.ClassificationData
                classification_data.data_input = data[1]
                classification_data.data_labels = data[2]
            elseif problem_type()==:Regression
                regression_data = all_data.TestingData.RegressionData
                regression_data.data_input = data[1]
                regression_data.data_labels = data[2]
            elseif problem_type()==:Segmentation
                segmentation_data = all_data.TestingData.SegmentationData
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
                training_results_data = all_data.TrainingData.Results
                model_data.model = data[1]
                training_results_data.accuracy = data[2]
                training_results_data.loss = data[3]
                training_results_data.test_accuracy = data[4]
                training_results_data.test_loss = data[5]
                training_results_data.test_iteration = data[6]
                save_model(all_data.model_url)
            end
            return true
        else
            return false
        end
    elseif field=="Validation"
        if isready(channels.validation_results)
            data = take!(channels.validation_results)
            if all_data.input_type==:Image
                image_data = data[1]
                other_data = data[2]
                original = data[3]
                if problem_type()==:Classification
                    validation_results = all_data.ValidationData.ImageClassificationResults
                    push!(validation_results.original,original)
                    push!(validation_results.predicted_labels,image_data[1])
                    push!(validation_results.target_labels,image_data[2])
                    push!(validation_results.accuracy,other_data[1])
                    push!(validation_results.loss,other_data[2])
                elseif problem_type()==:Regression
                    validation_results = all_data.ValidationData.ImageRegressionResults
                    push!(validation_results.original,original)
                    push!(validation_results.predicted_labels,image_data[1])
                    push!(validation_results.target_labels,image_data[2])
                    push!(validation_results.accuracy,other_data[1])
                    push!(validation_results.loss,other_data[2])
                elseif problem_type()==:Segmentation
                    validation_results = all_data.ValidationData.ImageSegmentationResults
                    push!(validation_results.original,original)
                    push!(validation_results.predicted_data,image_data[1])
                    push!(validation_results.target_data,image_data[2])
                    push!(validation_results.error_data,image_data[3])
                    push!(validation_results.accuracy,other_data[1])
                    push!(validation_results.loss,other_data[2])
                end
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
get_results(field) = get_results_main(channels,all_data,model_data,field)

#---
# Empties progress channels
function empty_progress_channel_main(channels::Channels,field)
    field::String = fix_QML_types(field)
    if field=="Training data preparation"
        channel_temp = channels.training_data_progress
    elseif field=="Testing data preparation"
        channel_temp = channels.testing_data_progress
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
    elseif field=="Testing data preparation"
        channel_temp = channels.testing_data_progress
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
    field = fix_QML_types(field)
    value_raw = [2.0,10.0]
    value_raw::Vector{Float64} = fix_QML_types(value)
    value1 = convert(Int64,value_raw[1])
    value2 = convert(Float64,value_raw[2])
    value = (value1,value2)
    if field=="Training data preparation"
        put!(channels.training_data_modifiers,value)
    elseif field=="Testing data preparation"
        put!(channels.testing_data_modifiers,value)
    elseif field=="Validation data preparation"
        put!(channels.validation_data_modifiers,value)
    elseif field=="Training"
        put!(channels.training_modifiers,value)
    elseif field=="Validation"
        put!(channels.validation_modifiers,value)
    end
end
put_channel(field,value) = put_channel_main(channels,field,value)
