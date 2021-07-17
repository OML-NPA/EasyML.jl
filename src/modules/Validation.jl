
module Validation

using Parameters, ColorTypes, FixedPointNumbers


#---Data----------------------------------------------------------------

@with_kw mutable struct ValidationImageClassificationResults
    original_images::Vector{Array{RGB{N0f8},2}} = Vector{Array{RGB{N0f8},2}}(undef,0)
    predicted_labels::Vector{String} = Vector{String}(undef,0)
    target_labels::Vector{String} = Vector{String}(undef,0)
    accuracy::Vector{Float32} = Vector{Float32}(undef,0)
    loss::Vector{Float32} = Vector{Float32}(undef,0)
end
validation_image_classification_results = ValidationImageClassificationResults()

@with_kw mutable struct ValidationImageRegressionResults
    original_images::Vector{Array{RGB{N0f8},2}} = Vector{Array{RGB{N0f8},2}}(undef,0)
    predicted_labels::Vector{Vector{Float32}}= Vector{Vector{Float32}}(undef,0)
    target_labels::Vector{Vector{Float32}} = Vector{Vector{Float32}}(undef,0)
    accuracy::Vector{Float32} = Vector{Float32}(undef,0)
    loss::Vector{Float32} = Vector{Float32}(undef,0)
end
validation_image_regression_results = ValidationImageRegressionResults()

@with_kw mutable struct ValidationImageSegmentationResults
    original_images::Vector{Array{RGB{N0f8},2}} = Vector{Array{RGB{N0f8},2}}(undef,0)
    predicted_data::Vector{Vector{Tuple{BitArray{2},Vector{N0f8}}}} = 
        Vector{Vector{Tuple{BitArray{2},Vector{N0f8}}}}(undef,0)
    target_data::Vector{Vector{Tuple{BitArray{2},Vector{N0f8}}}} = 
        Vector{Vector{Tuple{BitArray{2},Vector{N0f8}}}}(undef,0)
    error_data::Vector{Vector{Tuple{BitArray{3},Vector{N0f8}}}} = 
        Vector{Vector{Tuple{BitArray{3},Vector{N0f8}}}}(undef,0)
    accuracy::Vector{Float32} = Vector{Float32}(undef,0)
    loss::Vector{Float32} = Vector{Float32}(undef,0)
end
validation_image_segmentation_results = ValidationImageSegmentationResults()

@with_kw mutable struct ValidationUrls
    input_urls::Vector{String} = Vector{String}(undef,0)
    label_urls::Vector{String} = Vector{String}(undef,0)
    labels_classification::Vector{Int32} = Vector{Int32}(undef,0)
    labels_regression::Vector{Vector{Float32}} = Vector{Float32}(undef,0)
    url_inputs::String = ""
    url_labels::String = ""
end
validation_urls = ValidationUrls()

@with_kw mutable struct ValidationPlotData
    original_image::Array{RGB{N0f8},2} = Array{RGB{N0f8},2}(undef,0,0)
    label_image::Array{RGB{N0f8},2} = Array{RGB{N0f8},2}(undef,0,0)
    use_labels::Bool = false
end
validation_plot_data = ValidationPlotData()

@with_kw struct ValidationData
    PlotData::ValidationPlotData = validation_plot_data
    ImageClassificationResults::ValidationImageClassificationResults = validation_image_classification_results
    ImageRegressionResults::ValidationImageRegressionResults = validation_image_regression_results
    ImageSegmentationResults::ValidationImageSegmentationResults = validation_image_segmentation_results
    Urls::ValidationUrls = validation_urls
    tasks::Vector{Task} = Vector{Task}(undef,0)
end
validation_data = ValidationData()


#---Options----------------------------------------------------------------


@with_kw mutable struct AccuracyOptions
    weight_accuracy::Bool = true
    accuracy_mode::Symbol = :Auto
end
accuracy_options = AccuracyOptions()

@with_kw mutable struct ValidationOptions
    Accuracy::AccuracyOptions = accuracy_options
end
validation_options = ValidationOptions()


#---Export all--------------------------------------------------------------
for n in names(@__MODULE__; all=true)
    if Base.isidentifier(n) && n ∉ (Symbol(@__MODULE__), :eval, :include)
        @eval export $n
    end
end

end