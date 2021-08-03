
function assign_urls(some_data::Union{TrainingData,TestingData},urls)
    if isnothing(urls)
        return nothing
    else
        if problem_type()==:classification
            some_data.ClassificationData.Urls = urls
        elseif problem_type()==:regression
            some_data.RegressionData.Urls = urls
        else problem_type()==:segmentation
            some_data.SegmentationData.Urls = urls
        end
    end
end

function EasyML.DataPreparation.get_urls(url_inputs::String,some_data::Union{TrainingData,TestingData})
    urls = get_urls(url_inputs)
    assign_urls(some_data,urls)
    return nothing
end

function EasyML.DataPreparation.get_urls(url_inputs::String,url_labels::String,some_data::Union{TrainingData,TestingData})
    urls = get_urls(url_inputs,url_labels)
    assign_urls(some_data,urls)
    return nothing
end

function EasyML.DataPreparation.get_urls(some_data::Union{TrainingData,TestingData})
    urls = get_urls()
    assign_urls(some_data,urls)
    return nothing
end

function get_train_test_inds(num::Int64,fraction::Float64)
    inds = randperm(num)  # Get shuffled indices
    ind_last_test = convert(Int64,round(fraction*num))
    inds_train = inds[ind_last_test+1:end]
    inds_test = inds[1:ind_last_test]
    if isempty(inds_test)
        @error string("Fraction of ",fraction," from ",num,
        " files is 0. Increase the fraction of data used for testing to at least ",round(1/num,digits=2),".")
        return nothing,nothing
    end
    return inds_train,inds_test
end

function get_urls_testing_main(training_data::TrainingData,testing_data::TestingData,training_options::TrainingOptions)
    if training_options.Testing.data_preparation_mode==:manual
        urls = get_urls()
        if problem_type()==:classification
            testing_data.ClassificationData.Urls = urls
        elseif problem_type()==:regression
            testing_data.RegressionData.Urls = urls
        elseif problem_type()==:segmentation
            testing_data.SegmentationData.Urls = urls
        end
    else
        if problem_type()==:classification
            typed_training_data = training_data.ClassificationData
            typed_testing_data = testing_data.ClassificationData
            training_inputs = typed_training_data.Urls.input_urls
            testing_inputs = typed_testing_data.Urls.input_urls
            training_labels = typed_training_data.Urls.label_urls
            testing_labels = typed_testing_data.Urls.label_urls
        elseif problem_type()==:regression
            typed_training_data = training_data.RegressionData
            typed_testing_data = testing_data.RegressionData
            training_inputs = typed_training_data.Urls.input_urls
            testing_inputs = typed_testing_data.Urls.input_urls
            training_labels = typed_training_data.Urls.initial_data_labels
            testing_labels = typed_testing_data.Urls.initial_data_labels
        elseif problem_type()==:segmentation
            typed_training_data = training_data.SegmentationData
            typed_testing_data = testing_data.SegmentationData
            training_inputs = typed_training_data.Urls.input_urls
            testing_inputs = typed_testing_data.Urls.input_urls
            training_labels = typed_training_data.Urls.label_urls
            testing_labels = typed_testing_data.Urls.label_urls
        end
        if isempty(training_inputs) || isempty(training_labels)
            @error "Training data urls should be loaded first. Run 'get_urls_training'."
            return nothing
        end
        training_inputs_copy = copy(training_inputs)
        training_labels_copy = copy(training_labels)
        empty!(training_inputs)
        empty!(testing_inputs)
        empty!(training_labels)
        empty!(testing_labels)
        fraction = training_options.Testing.test_data_fraction
        if problem_type()==:classification
            nums = length.(training_inputs_copy)
            for i = 1:length(nums)
                num = nums[i]
                inds_train,inds_test = get_train_test_inds(num,fraction)
                if isnothing(inds_train)
                    return nothing
                end
                push!(training_inputs,training_inputs_copy[i][inds_train])
                push!(testing_inputs,training_inputs_copy[i][inds_test])
            end
            append!(training_labels,training_labels_copy)
            append!(testing_labels,training_labels_copy)
        elseif problem_type()==:regression || problem_type()==:segmentation
            num = length(training_inputs_copy)
            inds_train,inds_test = get_train_test_inds(num,fraction)
            if isnothing(inds_train)
                return nothing
            end
            append!(training_inputs,training_inputs_copy[inds_train])
            append!(testing_inputs,training_inputs_copy[inds_test])
            append!(training_labels,training_labels_copy[inds_train])
            append!(testing_labels,training_labels_copy[inds_test])
        end
    end
    return nothing
end

"""
    get_urls_training(url_inputs::String,url_labels::String)

Gets URLs to all files present in both folders (or a folder and a file) 
specified by `url_inputs` and `url_labels` for training. URLs are automatically saved to `EasyML.training_data`.
"""
get_urls_training(url_inputs,url_labels) = get_urls(url_inputs,url_labels,training_data)

"""
    get_urls_testing(url_inputs::String,url_labels::String)
    
Gets URLs to all files present in both folders (or a folder and a file) 
specified by `url_inputs` and `url_labels` for testing. URLs are automatically saved to `EasyML.testing_data`.
"""
get_urls_testing(url_inputs,url_labels) = get_urls(url_inputs,url_labels,testing_data)

"""
    get_urls_training(url_inputs::String)

Used for classification. Gets URLs to all files present in folders located at a folder specified by `url_inputs` 
for training. Folders should have names identical to the name of classes. URLs are automatically saved to `EasyML.training_data`.
"""
get_urls_training(url_inputs) = get_urls(url_inputs,training_data)

"""
    get_urls_testing(url_inputs::String)

Used for classification. Gets URLs to all files present in folders located at a folder specified by `url_inputs` 
for testing. Folders should have names identical to the name of classes. URLs are automatically saved to `EasyML.testing_data`.
"""
get_urls_testing(url_inputs) = get_urls(url_inputs,testing_data)


"""
    get_urls_training()

Opens a folder/file dialog or dialogs to choose folders or folder and a file containing inputs 
and labels. URLs are automatically saved to `EasyML.training_data`.
"""
get_urls_training() = get_urls(training_data)

"""
    get_urls_testing()

If testing data preparation in `modify(training_options)` is set to auto, then a percentage 
of training data also specified there is reserved for testing. If testing data 
preparation is set to manual, then it opens a folder/file dialog or dialogs to choose folders or a folder and a file containing inputs 
and labels. URLs are automatically saved to `EasyML.testing_data`.
"""
get_urls_testing() = get_urls_testing_main(training_data,testing_data,training_options)

function EasyML.DataPreparation.prepare_data(some_data::Union{TrainingData,TestingData})
    if some_data isa TrainingData
        println("Training data preparation:")
        channel_name = "Training data preparation"
        error_message = "No input urls. Run 'get_urls_training'."
    else
        println("Testing data preparation:")
        channel_name = "Testing data preparation"
        error_message = "No input urls. Run 'get_urls_testing'."
    end
    if any(model_data.input_size.<1)
        @error "All dimension sizes of 'model_data.input_size' should be a positive number."
        return nothing
    end
    if input_type()==:image
        if problem_type()==:classification 
            if isempty(some_data.ClassificationData.Urls.input_urls)
                @error error_message
                return nothing
            end
        elseif problem_type()==:regression
            if isempty(some_data.RegressionData.Urls.input_urls)
                @error error_message
                return nothing
            end
        elseif problem_type()==:segmentation
            if isempty(some_data.SegmentationData.Urls.input_urls)
                @error error_message
                return nothing
            end
        end
    end

    results = prepare_data()
    if problem_type()==:classification
        some_data.ClassificationData.Data = results
    elseif problem_type()==:regression
        some_data.RegressionData.Data = results
    else # problem_type()==:segmentation
        some_data.SegmentationData.Data = results
    end
    return nothing
end
"""
    prepare_training_data()

Prepares images and corresponding labels for training using URLs loaded previously using 
`get_urls_training`. Saves data to EasyML.training_data.
"""
prepare_training_data() = prepare_data(training_data)
"""
    prepare_testing_data()

Prepares images and corresponding labels for testing using URLs loaded previously using 
`get_urls_testing`. Saves data to `EasyML.testing_data`.
"""
prepare_testing_data() = prepare_data(testing_data)