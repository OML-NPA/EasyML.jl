
"""
    change(data_preparation_options::DataPreparationOptions) 

Allows to change `data_preparation_options` in a GUI.
"""
function Common.change(data::DataPreparationOptions)
    @qmlfunction(
        # Options
        get_options,
        set_options,
        save_options,
        # Model data
        set_model_data,
        get_model_data,
        rm_model_data,
        # Other
        unit_test
    )
    path_qml = string(@__DIR__,"/gui/DataPreparationOptions.qml")
    gui_dir = string("file:///",replace(@__DIR__, "\\" => "/"),"/gui/")
    text = add_templates(path_qml)
    loadqml(QByteArray(text), gui_dir = gui_dir)
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
    if problem_type()==:classification || problem_type()==:segmentation
        if !isdir(url_labels)
            @error string(url_labels," does not exist.")
            return nothing
        end
    elseif problem_type()==:regression
        if !isfile(url_labels)
            @error string(url_labels," does not exist.") 
            return nothing
        end
    end
    urls = get_urls_main(model_data,preparation_data)
    return urls
end

"""
    get_urls(url_inputs::String,url_labels::String)

Gets URLs to all files present in both folders (or a folder and a file) 
specified by `url_inputs` and `url_labels`. URLs are automatically saved to `EasyML.preparation_data`.
"""
get_urls(url_inputs,url_labels) = get_urls(url_inputs,url_labels,preparation_data)


function get_urls(url_inputs::String,preparation_data::PreparationData)
    if problem_type()!=:classification
        @error "Label data directory URL was not given."
        return nothing
    end
    url_inputs = replace(url_inputs, '\\'=>'/')
    preparation_data.Urls.url_inputs = url_inputs
    if !isdir(url_inputs)
        @error string(url_inputs," does not exist.")
        return nothing
    end
    urls = get_urls_main(model_data,preparation_data)
    return urls
end
"""
    get_urls(url_inputs::String)

Used for classification. Gets URLs to all files present in folders located at a folder specified by `url_inputs` 
for training. Folders should have names identical to the name of classes. URLs are automatically saved to `EasyML.preparation_data`.
"""
get_urls(url_inputs) = get_urls(url_inputs,preparation_data)

function get_urls(preparation_data::PreparationData)
    dir = pwd()
    @info "Select a directory with input data."
    path = get_folder(dir)
    if !isempty(path)
        preparation_data.Urls.url_inputs = path
        @info string(preparation_data.Urls.url_inputs, " was selected.")
    else
        @error "Input data directory URL is empty."
        return nothing
    end
    if problem_type()==:classification
    
    elseif problem_type()==:regression
        @info "Select a file with label data."
        name_filters = ["*.csv","*.xlsx"]
        path = get_file(dir,name_filters)
        if !isempty(path)
            preparation_data.Urls.url_labels = path
            @info string(preparation_data.Urls.url_labels, " was selected.")
        else
            @error "Label data file URL is empty."
            return nothing
        end
    elseif problem_type()==:segmentation
        @info "Select a directory with label data."
        path = get_folder(dir)
        if !isempty(path)
            preparation_data.Urls.url_labels = path
            @info string(preparation_data.Urls.url_labels, " was selected.")
        else
            @error "Label data directory URL is empty."
            return nothing
        end
    end
    urls = get_urls_main(model_data,preparation_data)
    return urls
end
"""
    get_urls()

Opens a folder/file dialog or dialogs to choose folders or folder and a file containing inputs 
and labels. URLs are automatically saved to `EasyML.preparation_data`.
"""
get_urls() = get_urls(preparation_data)

function prepare_data(model_data::ModelData,preparation_data::PreparationData)
    if isempty(model_data.classes)
        @error "Classes are empty."
        return nothing
    end
    fields = [:data_input,:data_labels]
    for i in fields
        empty!(getfield(preparation_data.ClassificationData.Data,i))
        empty!(getfield(preparation_data.RegressionData.Data,i))
        empty!(getfield(preparation_data.SegmentationData.Data,i))
    end
    empty_channel(:data_preparation_progress)
    if input_type()==:image
        if problem_type()==:classification 
            empty!(preparation_data.SegmentationData.Urls.input_urls)
            empty!(preparation_data.SegmentationData.Urls.label_urls)
            empty!(preparation_data.RegressionData.Urls.input_urls)
            if isempty(preparation_data.ClassificationData.Urls.input_urls)
                @error "No input urls. Run 'get_url'."
                return nothing
            end
        elseif problem_type()==:regression
            empty!(preparation_data.ClassificationData.Urls.input_urls)
            empty!(preparation_data.ClassificationData.Urls.label_urls)
            empty!(preparation_data.SegmentationData.Urls.input_urls)
            empty!(preparation_data.SegmentationData.Urls.label_urls)
            if isempty(preparation_data.RegressionData.Urls.input_urls)
                @error "No input urls. Run 'get_url'."
                return nothing
            end
        elseif problem_type()==:segmentation
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
    if problem_type()==:classification
        return preparation_data.ClassificationData.Data
    elseif problem_type()==:regression
        return preparation_data.RegressionData.Data
    else # problem_type()==:segmentation
        return preparation_data.SegmentationData.Data
    end
end
"""
    prepare_data() 

Prepares images and corresponding labels for training using URLs loaded previously using 
`get_urls`. Saves data to EasyML.PreparedDarta.
"""
prepare_data() = prepare_data(model_data,preparation_data)

"""
    remove_urls()

Removes urls.
"""
function remove_urls(preparation_data::PreparationData)
    if problem_type()==:classification
        preparation_data.ClassificationData.Urls = ClassificationUrlsData()
    elseif problem_type()==:regression
        preparation_data.RegressionData.Urls = RegressionUrlsData()
    else # problem_type()==:segmentation
        preparation_data.SegmentationData.Urls = SegmentationUrlsData()
    end
end
remove_urls() = remove_urls(preparation_data)