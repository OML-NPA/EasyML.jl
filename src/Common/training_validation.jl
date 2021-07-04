

#---
function accuracy_classification(predicted::A,actual::A) where {T<:Float32,A<:AbstractArray{T,2}}
    acc = Vector{Float32}(undef,0)
    for i in 1:size(predicted,2)
        _ , actual_ind = collect(findmax(actual[:,i]))
        _ , predicted_ind = collect(findmax(predicted[:,i]))
        if actual_ind==predicted_ind
            push!(acc,1)
        else
            push!(acc,0)
        end
    end
    return mean(acc)
end

function accuracy_classification_weighted(predicted::A,actual::A,ws::Vector{T}) where {T<:Float32,A<:AbstractArray{T,2}}
    l = size(predicted,2)
    acc = Vector{Float32}(undef,l)
    w = Vector{Float32}(undef,l)
    for i = 1:l
        _ , actual_ind = collect(findmax(actual[:,i]))
        _ , predicted_ind = collect(findmax(predicted[:,i]))
        w[i] = ws[actual_ind]
        if actual_ind==predicted_ind
            acc[i] = 1
        else
            acc[i] = 0
        end
    end
    return mean(acc,StatsBase.weights(w))
end

function accuracy_regression(predicted::A,actual::A) where {T<:Float32,A<:AbstractArray{T}}
    err = abs.(actual .- predicted)
    err_relative = mean(err./actual)
    acc = 1/(1+err_relative)
    return acc
end

function accuracy_segmentation(predicted::A,actual::A) where {T<:Float32,A<:AbstractArray{T,4}}
    # Convert to BitArray
    actual_bool = actual.>0
    predicted_bool = predicted.>0.5
    # Calculate accuracy
    correct_bool = predicted_bool .& actual_bool
    num_correct = convert(Float32,sum(correct_bool))
    acc = num_correct/prod(size(predicted))
    return acc
end

# Weight accuracy using inverse frequency
function accuracy_segmentation_weighted(predicted::A,actual::A,ws::Vector{T}) where {T<:Float32,A<:AbstractArray{T,4}}
    # Convert to BitArray
    actual_bool = actual.>0
    predicted_bool = predicted.>0.5
    # Calculate correct and incorrect class pixels as a BitArray
    correct_bool = predicted_bool .& actual_bool
    dif_bool = xor.(predicted_bool,actual_bool)
    # Calculate class accuracies
    sum_correct_int_dim4 = collect(sum(correct_bool, dims = [1,2,4]))
    sum_dif_int_dim4 = collect(sum(dif_bool, dims = [1,2,4]))
    sum_correct_int = collect(Iterators.flatten(sum_correct_int_dim4))
    sum_dif_int = collect(Iterators.flatten(sum_dif_int_dim4))
    sum_correct = convert(Vector{Float32},sum_correct_int)
    sum_dif = convert(Vector{Float32},sum_dif_int)
    classes_accuracy = sum_correct./(sum_correct.+sum_dif)
    acc = sum(ws.*classes_accuracy)
    return acc
end

# Returns an accuracy function
function get_accuracy_func(weights::Vector{Float32},options::Options)
    weight = options.TrainingOptions.Accuracy.weight_accuracy
    if problem_type()==:Classification
        if weight
            return (x,y) -> accuracy_classification_weighted(x,y,weights)
        else
            return accuracy_classification
        end
    elseif problem_type()==:Regression
        return accuracy_regression
    elseif problem_type()==:Segmentation
        if weight
            return  (x,y) -> accuracy_segmentation_weighted(x,y,weights)
        else
            return accuracy_segmentation
        end
    end
end

function calculate_weights(counts::Vector{Int64})
    frequencies = counts./sum(counts)
    inv_frequencies = 1 ./frequencies
    weights64 = inv_frequencies./sum(inv_frequencies)
    weights = convert(Vector{Float32},weights64)
    return weights
end

function get_weights(classification_data::ClassificationData)
    data_labels = classification_data.data_labels
    num = classification_data.max_labels
    counts = zeros(Int64,num)
    for data in data_labels
        counts[data] += 1
    end
    weights = calculate_weights(counts)
    return weights
end

function get_weights(regression_data::RegressionData)
    weights = Vector{Float32}(undef,0)
    return weights
end

function get_weights(segmentation_data::SegmentationData)
    data_labels = segmentation_data.data_labels
    num = size(data_labels[1],3)
    counts = zeros(Int64,num)
    for data in data_labels
        counts .+= collect(Iterators.flatten(sum(data,dims = [1,2])))
    end
    weights = calculate_weights(counts)
    return weights
end