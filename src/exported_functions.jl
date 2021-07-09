
"""
    make_classes()

Opens a GUI for addition or modification of classes.
"""
function make_classes()
    classes = model_data.classes
    if length(classes)==0
        ids = [0]
        JindTree = -1
    else
        ids = 1:length(classes)
        JindTree = 0
    end
    @qmlfunction(
        # Classes
        get_class_field,
        num_classes,
        append_classes,
        reset_classes,
        # Problem
        get_problem_type,
        set_problem_type,
        # Options
        get_options,
        set_options,
        save_options,
        # Other
        unit_test
    )
    path_qml = string(@__DIR__,"/gui/ClassDialog.qml")
    loadqml(path_qml,JindTree = JindTree, ids = ids)
    exec()
    return nothing
end

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
    path_qml = string(@__DIR__,"/GUI/DataPreparationOptions.qml")
    loadqml(path_qml)
    exec()
    return nothing
end

function get_urls(url_inputs::String,url_labels::String,prepared_data::PreparedData)
    url_inputs = replace(url_inputs, '\\'=>'/')
    url_labels = replace(url_labels, '\\'=>'/')
    prepared_data.url_inputs = url_inputs
    prepared_data.url_labels = url_labels
    if !isdir(url_inputs)
        @error string(url_inputs," does not exist.")
        return nothing
    end
    if problem_type()==:Classification || problem_type()==:Segmentation
        if !isdir(url_labels)
            @error string(url_labels," does not exist.")
            return nothing
        end
    elseif problem_type()==:Regression
        if !isfile(url_labels)
            @error string(url_labels," does not exist.")
            return nothing
        end
    end
    get_urls_main(model_data,prepared_data)
    return nothing
end

"""
    get_urls(url_inputs::String,url_labels::String)

Gets URLs to all files present in both folders (or a folder and a file) 
specified by `url_inputs` and `url_labels`. URLs are automatically saved to `EasyML.prepared_data`.
"""
get_urls(url_inputs,url_labels) = get_urls(url_inputs,url_labels,prepared_data)


function get_urls(url_inputs::String,prepared_data::PreparedData)
    if problem_type()!=:Classification
        @error "Label data directory URL was not given."
        return nothing
    end
    url_inputs = replace(url_inputs, '\\'=>'/')
    prepared_data.url_inputs = url_inputs
    if !isdir(url_inputs)
        @error string(url_inputs," does not exist.")
        return nothing
    end
    get_urls_main(model_data,prepared_data)
    return nothing
end
"""
    get_urls(url_inputs::String)

Used for classification. Gets URLs to all files present in folders located at a folder specified by `url_inputs` 
for training. Folders should have names identical to the name of classes. URLs are automatically saved to `EasyML.prepared_data`.
"""
get_urls(url_inputs) = get_urls(url_inputs,prepared_data)

function get_urls(prepared_data::PreparedData)
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
        prepared_data.url_inputs = url_out[1]
        @info string(prepared_data.url_inputs, " was selected.")
    else
        @error "Input data directory URL is empty."
        return nothing
    end
    if problem_type()==:Classification
    
    elseif problem_type()==:Regression
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
            prepared_data.url_labels = url_out[1]
            @info string(prepared_data.url_labels, " was selected.")
        else
            @error "Label data file URL is empty."
            return nothing
        end
    elseif problem_type()==:Segmentation
        @info "Select a directory with label data."
        @qmlfunction(observe,unit_test)
        path_qml = string(@__DIR__,"/common/gui/UniversalFolderDialog.qml")
        loadqml(path_qml,currentfolder = dir)
        exec()
        if unit_test()
            url_out[1] = unit_test.url_pusher()
        end
        if !isempty(url_out[1])
            prepared_data.url_labels = url_out[1]
            @info string(prepared_data.url_labels, " was selected.")
        else
            @error "Label data directory URL is empty."
            return nothing
        end
    end
    get_urls_main(model_data,prepared_data)
    return nothing
end
"""
    get_urls()

Opens a folder/file dialog or dialogs to choose folders or folder and a file containing inputs 
and labels. URLs are automatically saved to `EasyML.prepared_data`.
"""
get_urls() = get_urls(prepared_data)

function prepare_data(model_data::ModelData,prepared_data::PreparedData)
    if isempty(model_data.classes)
        @error "Empty classes."
        return nothing
    end
    fields = [:data_input,:data_labels]
    for i in fields
        empty!(getfield(prepared_data.ClassificationData.Results,i))
        empty!(getfield(prepared_data.RegressionData.Results,i))
        empty!(getfield(prepared_data.SegmentationData.Results,i))
    end
    empty_channel(:data_preparation_progress)
    if input_type()==:Image
        if problem_type()==:Classification 
            empty!(prepared_data.SegmentationData.Urls.input_urls)
            empty!(prepared_data.SegmentationData.Urls.label_urls)
            empty!(prepared_data.RegressionData.Urls.input_urls)
            if isempty(prepared_data.ClassificationData.Urls.input_urls)
                @error "No input urls. Run 'get_url'."
                return nothing
            end
        elseif problem_type()==:Regression
            empty!(prepared_data.ClassificationData.Urls.input_urls)
            empty!(prepared_data.ClassificationData.Urls.label_urls)
            empty!(prepared_data.SegmentationData.Urls.input_urls)
            empty!(prepared_data.SegmentationData.Urls.label_urls)
            if isempty(prepared_data.RegressionData.Urls.input_urls)
                @error "No input urls. Run 'get_url'."
                return nothing
            end
        elseif problem_type()==:Segmentation
            empty!(prepared_data.ClassificationData.Urls.input_urls)
            empty!(prepared_data.ClassificationData.Urls.label_urls)
            empty!(prepared_data.RegressionData.Urls.input_urls)
            if isempty(prepared_data.SegmentationData.Urls.input_urls)
                @error "No input urls. Run 'get_url'."
                return nothing
            end
        end
    end

    t = prepare_data_main(model_data,prepared_data,channels)
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
    if problem_type()==:Classification
        return prepared_data.ClassificationData.Results
    elseif problem_type()==:RegressionData
        return prepared_data.RegressionData.Results
    else # problem_type()==:Segmentation
        return prepared_data.SegmentationData.Results
    end
end
"""
    prepare_data() 

Prepares images and corresponding labels for training using URLs loaded previously using 
`get_urls`. Saves data to EasyML.prepared_data.
"""
prepare_data() = prepare_data(model_data,prepared_data)
