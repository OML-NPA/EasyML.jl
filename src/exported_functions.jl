
"""
    modify(data_preparation_options::DataPreparationOptions) 

Allows to modify `data_preparation_options` in a GUI.
"""
function modify(data::DataPreparationOptions)
    @qmlfunction(
        # Options
        get_options,
        set_options,
        save_options,
        # Other
        set_model_data,
        unit_test
    )
    path_qml = string(@__DIR__,"/gui/DataPreparationOptions.qml")
    loadqml(path_qml)
    exec()
    return nothing
end

function get_urls(url_inputs::String,url_labels::String,preparation_data::PreparationData)
    url_inputs = replace(url_inputs, '\\'=>'/')
    url_labels = replace(url_labels, '\\'=>'/')
    preparation_data.Urls.url_inputs = url_inputs
    preparation_data.Urls.url_labels = url_labels
    if !isdir(url_inputs)
        @error string(url_inputs," does not exist.")
        return nothing
    end
    if problem_type()==Classification || problem_type()==Segmentation
        if !isdir(url_labels)
            @error string(url_labels," does not exist.")
            return nothing
        end
    elseif problem_type()==Regression
        if !isfile(url_labels)
            @error string(url_labels," does not exist.")
            return nothing
        end
    end
    get_urls_main(model_data,preparation_data)
    return nothing
end

"""
    get_urls(url_inputs::String,url_labels::String)

Gets URLs to all files present in both folders (or a folder and a file) 
specified by `url_inputs` and `url_labels`. URLs are automatically saved to `EasyML.preparation_data`.
"""
get_urls(url_inputs,url_labels) = get_urls(url_inputs,url_labels,preparation_data)


function get_urls(url_inputs::String,preparation_data::PreparationData)
    if problem_type()!=Classification
        @error "Label data directory URL was not given."
        return nothing
    end
    url_inputs = replace(url_inputs, '\\'=>'/')
    preparation_data.Urls.url_inputs = url_inputs
    if !isdir(url_inputs)
        @error string(url_inputs," does not exist.")
        return nothing
    end
    get_urls_main(model_data,preparation_data)
    return nothing
end
"""
    get_urls(url_inputs::String)

Used for classification. Gets URLs to all files present in folders located at a folder specified by `url_inputs` 
for training. Folders should have names identical to the name of classes. URLs are automatically saved to `EasyML.preparation_data`.
"""
get_urls(url_inputs) = get_urls(url_inputs,preparation_data)

function get_urls(preparation_data::PreparationData)
    url_out = String[""]
    observe() = url_out[1]
    dir = pwd()
    @info "Select a directory with input data."
    @qmlfunction(observe,unit_test)
    path_qml = string(@__DIR__,"/common/gui/UniversalFolderDialog.qml")
    loadqml(path_qml,currentfolder = dir)
    exec()
    if unit_test()
        url_out[1] = unit_test.url_pusher()
    end
    if !isempty(url_out[1])
        preparation_data.Urls.url_inputs = url_out[1]
        @info string(preparation_data.Urls.url_inputs, " was selected.")
    else
        @error "Input data directory URL is empty."
        return nothing
    end
    if problem_type()==Classification
    
    elseif problem_type()==Regression
        @info "Select a file with label data."
        name_filters = ["*.csv","*.xlsx"]
        @qmlfunction(observe,unit_test)
        path_qml = string(@__DIR__,"/common/gui/UniversalFileDialog.qml")
        loadqml(path_qml,
            name_filters = name_filters)
        exec()
        if unit_test()
            url_out[1] = unit_test.url_pusher()
        end
        if !isempty(url_out[1])
            preparation_data.Urls.url_labels = url_out[1]
            @info string(preparation_data.Urls.url_labels, " was selected.")
        else
            @error "Label data file URL is empty."
            return nothing
        end
    elseif problem_type()==Segmentation
        @info "Select a directory with label data."
        @qmlfunction(observe,unit_test)
        path_qml = string(@__DIR__,"/common/gui/UniversalFolderDialog.qml")
        loadqml(path_qml,currentfolder = dir)
        exec()
        if unit_test()
            url_out[1] = unit_test.url_pusher()
        end
        if !isempty(url_out[1])
            preparation_data.Urls.url_labels = url_out[1]
            @info string(preparation_data.Urls.url_labels, " was selected.")
        else
            @error "Label data directory URL is empty."
            return nothing
        end
    end
    get_urls_main(model_data,preparation_data)
    return nothing
end
"""
    get_urls()

Opens a folder/file dialog or dialogs to choose folders or folder and a file containing inputs 
and labels. URLs are automatically saved to `EasyML.preparation_data`.
"""
get_urls() = get_urls(preparation_data)

function prepare_data(model_data::ModelData,preparation_data::PreparationData)
    if isempty(model_data.classes)
        @error "Empty classes."
        return nothing
    end
    fields = [:data_input,:data_labels]
    for i in fields
        empty!(getfield(preparation_data.ClassificationData.Results,i))
        empty!(getfield(preparation_data.RegressionData.Results,i))
        empty!(getfield(preparation_data.SegmentationData.Results,i))
    end
    empty_channel(:data_preparation_progress)
    if input_type()==Image
        if problem_type()==Classification 
            empty!(preparation_data.SegmentationData.Urls.input_urls)
            empty!(preparation_data.SegmentationData.Urls.label_urls)
            empty!(preparation_data.RegressionData.Urls.input_urls)
            if isempty(preparation_data.ClassificationData.Urls.input_urls)
                @error "No input urls. Run 'get_url'."
                return nothing
            end
        elseif problem_type()==Regression
            empty!(preparation_data.ClassificationData.Urls.input_urls)
            empty!(preparation_data.ClassificationData.Urls.label_urls)
            empty!(preparation_data.SegmentationData.Urls.input_urls)
            empty!(preparation_data.SegmentationData.Urls.label_urls)
            if isempty(preparation_data.RegressionData.Urls.input_urls)
                @error "No input urls. Run 'get_url'."
                return nothing
            end
        elseif problem_type()==Segmentation
            empty!(preparation_data.ClassificationData.Urls.input_urls)
            empty!(preparation_data.ClassificationData.Urls.label_urls)
            empty!(preparation_data.RegressionData.Urls.input_urls)
            if isempty(preparation_data.SegmentationData.Urls.input_urls)
                @error "No input urls. Run 'get_url'."
                return nothing
            end
        end
    end

    t = prepare_data_main(model_data,preparation_data,channels)
    max_value = 0
    value = 0
    p = Progress(0)
    while true
        if max_value!=0
            temp_value = get_progress(:data_preparation_progress)
            if temp_value!=false
                value += temp_value
                # handle progress here
                next!(p)
            elseif value==max_value
                break
            else
                state,error = check_task(t)
                if state==:error
                    throw(error)
                    return nothing
                end
                sleep(0.1)
            end
        else
            temp_value = get_progress(:data_preparation_progress)
            if temp_value!=false
                if temp_value!=0
                    max_value = temp_value
                    p.n = max_value
                else
                    @error "No data to process."
                    break
                end
            else
                state,error = check_task(t)
                if state==:error
                    throw(error)
                    return nothing
                end
                sleep(0.1)
            end
        end
    end
    if problem_type()==Classification
        return preparation_data.ClassificationData.Results
    elseif problem_type()==Regression
        return preparation_data.RegressionData.Results
    else # problem_type()==Segmentation
        return preparation_data.SegmentationData.Results
    end
end
"""
    prepare_data() 

Prepares images and corresponding labels for training using URLs loaded previously using 
`get_urls`. Saves data to EasyML.PreparedDarta.
"""
prepare_data() = prepare_data(model_data,preparation_data)
