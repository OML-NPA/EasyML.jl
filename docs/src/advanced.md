
## Classes

A struct named `model_data` is exported and holds all information about your model.

```julia
mutable struct ModelData
    model::Chain                                       # Flux.jl model.
    layers_info::Vector{AbstractLayerInfo}             # contains information for visualisation of layers.
    loss::Function                                     # holds loss that is used during training and validation.
    input_size::NTuple{3,Int64}                        # model input size.
    output_size::Union{Tuple{Int64},NTuple{3,Int64}}   # model output size.
    classes::Vector{<:AbstractClass}                   # hold information about classes that a neural network outputs and what should be done with them.
    OutputOptions::Vector{<:AbstractOutputOptions}     # hold information about output options for each class for application of the model.
end
```
`loss`, `classes` and `OutputOptions` fields can be modified manually if needed.

`loss` can be any function.

`classes` can be of different types depending on a type of a problem.

```julia
mutable struct ImageClassificationClass<:AbstractClass
    name::String                # name of a class.
    weight::Float32             # weight of a class used for weighted accuracy calculation.
end

mutable struct ImageRegressionClass<:AbstractClass
    name::String                # name of a class.
end

mutable struct ImageSegmentationClass<:AbstractClass
    name::String               # name of a class. It is just for your convenience.
    weight::Float32            # weight of a class used for weighted accuracy calculation.
    color::Vector{Float64}     # RGB color of a class, which should correspond to its color on your images. Uses 0-255 range.
    border::Bool               # allows to train a neural network to recognize borders and, therefore, better separate objects during post-processing.
    border_thickness::Int64    # border thickness in pixels.
    border_remove_objs::Bool   # removes objects that do not have closed borders.
    min_area::Int64            # minimum area of an object.
    parents::Vector{String}    # up to two parents can be specified by their name. Objects from a child are added to its parent.
    not_class::Bool            # specifies that a class is an overlap of two classes and should be just added to specified parents.
end
```

`OutputOptions` should also be chosen accordingly to a type of a problem one has.

`ImageClassificationOutputOptions` and `ImageRegressionOutputOptions` are currently empty. New functionality can be added on request.

```julia
@with_kw mutable struct ImageSegmentationOutputOptions<:AbstractOutputOptions
    Mask::OutputMask            # holds output mask options.
    Area::OutputArea            # holds area of objects options.
    Volume::OutputVolume        # holds volume of objects options.
end

mutable struct OutputMask
    mask::Bool                  #  exports a mask after applying all processing except for border data.
    mask_border::Bool           # exports a mask with class borders if a class has border detection enabled.
    mask_applied_border::Bool   # exports a mask processed using border data.
end

@with_kw mutable struct OutputArea
    area_distribution::Bool     # exports area distribution of detected objects as a histogram.
    obj_area::Bool              # exports area of each detected object.
    obj_area_sum::Bool          # exports sum of all areas for each class.
    binning::Int64              # specifies a binning method; 0 - automatic, 1 - number of bins, 2 - bin width.
    value::Float64              # number of bins or bin width depending on a previous settings.
    normalisation::Int64        # normalisation type for a histogram, 0 - pdf, 1 - Density, 2 - Probability, 3 - None.
end

@with_kw mutable struct OutputVolume
    volume_distribution::Bool   # exports volume distribution of detected objects as a histogram.
    obj_volume::Bool            # exports volume of each detected object.
    obj_volume_sum::Bool        # exports sum of all volumes for each class.
    binning::Int64              # specifies a binning method; 0 - automatic, 1 - number of bins, 2 - bin width.
    value::Float64              # number of bins or bin width depending on a previous settings.
    normalisation::Int64        # normalisation type for a histogram, 0 - pdf, 1 - Density, 2 - Probability, 3 - None.
end
```

Example code for a segmentation problem.

```julia
class1 = ImageSegmentationClass(name = "Cell", weight = 1, color = [0,255,0], border = true, 
    border_thickness = 5, border_remove_objs = true, min_area = 50)
class2 = ImageSegmentationClass(name = "Vacuole", weight = 1, color = [255,0,0], border = false, 
    border_thickness = 5, border_remove_objs = true, min_area = 5, parents = ["Cell",""])

class_output_options1 = ImageSegmentationOutputOptions()
class_output_options2 = ImageSegmentationOutputOptions()

settings.problem_type = :Segmentation
classes = [class1,class2]
output_options = [class_output_options1,class_output_options2]
model_data.classes = classes
model_data.OutputOptions = output_options
```

## A custom loop

A custom loop can be written using `forward`.


Example code for a segmentation problem.
```julia
model = model_data.model
data = [ones(Float32,160,160,3,1)]   # vector with your data goes here
results = Vector{BitArray{3}}(undef,0)
for i = 1:length(data)
    output_raw = forward(model,data[i])
    output_bool = output_raw[:,:,:].>0.5
    output = apply_border_data(output_bool,model_data.classes)   # can be removed if your model does not detect borders
    push!(results,output)
end
```

```@docs
forward
```

```@docs
apply_border_data
```




