
## Model data

A struct named `model_data` is exported and holds all information about your model.

```julia
mutable struct ModelData
    model::AbstractModel                                  # any of the supported models (currently only Flux.jl model).
    normalization::Normalization                          # a Normalization struct, which describes how to normalize input data
    loss::Function                                        # holds loss that is used during training and validation.
    input_size::Union{NTuple{2,Int64},NTuple{3,Int64}}    # model input size.
    output_size::Union{NTuple{2,Int64},NTuple{3,Int64}}   # model output size.
    input_type::Symbol                                    # type of input data (:image).
    problem_type::Symbol                                  # type of ML problem (:classification, :regression or :segmentation).
    classes::Vector{<:AbstractClass}                      # hold information about classes that a neural network outputs and what should be done with them.
    output_options::Vector{<:AbstractOutputOptions}      # hold information about output options for each class for application of the model.
    layers_info::Vector{AbstractLayerInfo}                # contains information for visualisation of layers.
end
```

`classes` and `output_options` type depends on a type of a problem.

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
    parents::Vector{String}    # up to two parents can be specified by their name. Objects from a child are added to its parent.
    overlap::Bool              # specifies that a class is an overlap of two classes and should be just added to specified parents.
    min_area::Int64            # minimum area of an object.
    BorderClass::BorderClass   # allows to train a neural network to recognize borders and, therefore, better separate objects during post-processing.
end

mutable struct BorderClass
    enabled::Bool
    thickness::Int64           # border thickness in pixels.
end

```

`ImageClassificationOutputOptions` and `ImageRegressionOutputOptions` are currently empty. New functionality can be added on request.

```julia
mutable struct ImageSegmentationOutputOptions<:AbstractOutputOptions
    Mask::OutputMask            # holds output mask options.
    Area::OutputArea            # holds area of objects options.
    Volume::OutputVolume        # holds volume of objects options.
end

mutable struct OutputMask
    mask::Bool                  # exports a mask after applying all processing except for border data.
    mask_border::Bool           # exports a mask with class borders if a class has border detection enabled.
    mask_applied_border::Bool   # exports a mask processed using border data.
end

mutable struct OutputArea
    area_distribution::Bool     # exports area distribution of detected objects as a histogram.
    obj_area::Bool              # exports area of each detected object.
    obj_area_sum::Bool          # exports sum of all areas for each class.
    binning::Symbol             # specifies a binning method (:auto, :number_of_bins, :bin_width).
    value::Float64              # number of bins or bin width depending on a previous settings.
    normalisation::Symbol       # normalisation type for a histogram (:none, :pdf, :density, :probability).
end

mutable struct OutputVolume
    volume_distribution::Bool   # exports volume distribution of detected objects as a histogram.
    obj_volume::Bool            # exports volume of each detected object.
    obj_volume_sum::Bool        # exports sum of all volumes for each class.
    binning::Symbol             # specifies a binning method (:auto, :number_of_bins, :bin_width).
    value::Float64              # number of bins or bin width depending on a previous settings.
    normalisation::Symbol       # normalisation type for a histogram (:none, :pdf, :density, :probability).
```

Example code for a segmentation problem.

```julia
class1 = ImageSegmentationClass(name = "Cell", weight = 1, color = [0,255,0], min_area = 5, BorderClass=BorderClass(true,5))
class2 = ImageSegmentationClass(name = "Vacuole", weight = 1, color = [255,0,0], parents = ["Cell",""], min_area = 5)

class_output_options1 = ImageSegmentationOutputOptions()
class_output_options2 = ImageSegmentationOutputOptions()

settings.problem_type = :segmentation
classes = [class1,class2]
output_options = [class_output_options1,class_output_options2]
model_data.classes = classes
model_data.OutputOptions = output_options
```

## Options

All options are located in `EasyML.options`.

```julia
mutable struct Options
    GlobalOptions::GlobalOptions
    DesignOptions::DesignOptions
    DataPreparationOptions::DataPreparationOptions
    TrainingOptions::TrainingOptions
    ValidationOptions::ValidationOptions = validation_options
    ApplicationOptions::ApplicationOptions
end
```

### Global options

```julia
mutable struct GlobalOptions
    Graphics::Graphics
    HardwareResources::HardwareResources
end
```
Can be accessed as `EasyML.global_options`.

```julia
mutable struct HardwareResources
    allow_GPU::Bool      # allows to use a GPU if a compatible one is installed.
    num_threads::Int64   # a number of CPU threads that will be used.
    num_slices::Int64    # allows to process images during validation and application that otherwise cause an out of memory error by slicing them into multiple parts. Used only for segmentation.
    offset::Int64        # offsets each slice by a given number of pixels to allow for an absence of a seam. 
end
```

```julia
mutable struct Graphics
    scaling_factor::Float64   # scales GUI by a given factor.
end
```

### Design options

```julia
mutable struct DesignOptions
    width::Float64        # width of layers
    height::Float64       # height of layers
    min_dist_x::Float64   # minimum horizontal distance between layers
    min_dist_y::Float64   # minimum vertical distance between layers
end
```
Can be accessed as `EasyML.design_options`.


### Training options

```julia
mutable struct TrainingOptions
    Accuracy::AccuracyOptions
    Testing::TestingOptions
    Hyperparameters::HyperparametersOptions
end
```
Can be accessed as `EasyML.training_options`.

```julia
mutable struct AccuracyOptions 
    weight_accuracy::Bool   # uses weight accuracy where applicable.
    accuracy_mode::Symbol   # either :auto or :manual. :manual allows to specify weights manually for each class.
end
```

```julia
mutable struct TestingOptions
    test_data_fraction::Float64     # a fraction of data from training data to be used for testing if data preparation mode is set to :Auto.
    num_tests::Float64              # a number of tests to be done each epoch at equal intervals.
    data_preparation_mode::Symbol   # Either :Auto or :Manual. Auto takes a specified fraction of training data to be used for testing. Manual allows to use other data as testing data.
end
```

```julia
mutable struct HyperparametersOptions
    optimiser::Symbol                   # an optimiser that should be used during training. ADAM usually works well for all cases.
    optimiser_params::Vector{Float64}   # parameters specific for each optimiser. Default ones can be found in EasyML.training_options_data
    learning_rate::Float64              # pecifies how fast a model should train. Lower values - more stable, but slower. Higher values - less stable, but faster. Should be decreased as training progresses.
    epochs::Int64                       # a number of rounds for which a model should be trained.
    batch_size::Int64                   # a number of data that should be batched together during training.
end
```

### Data preparation options

```julia
struct DataPreparationOptions
    Images::ImagePreparationOptions = image_preparation_options
end
```
Can be accessed as `data_preparation_options`.

```julia
@with_kw mutable struct ImagePreparationOptions
    grayscale::Bool = false      # converts images to grayscale for training, validation and application.
    mirroring::Bool = false      # augments data by producing horizontally mirrored images.
    num_angles::Int64 = 1        # augments data by rotating images using a specified number of angles. 1 means no rotation, only an angle of 0.
    min_fr_pix::Float64 = 0.0    # if supplied images are bigger than a model's input size, then an image is broken into chunks with a correct size. This option specifies the minimum number of labeled pixels for these chunks to be kept.
    BackgroundCropping::BackgroundCroppingOptions = background_cropping_options   # crops image to removed uniformly black backgorund.
end
```

```julia
@with_kw mutable struct BackgroundCroppingOptions
    enabled::Bool = false
    threshold::Float64 = 0.3   # creates a mask from values less than threshold.
    closing_value::Int64 = 1   # value for morphological closing which is used to smooth the mask.
end
```

### Validation options

```julia
mutable struct ValidationOptions
    Accuracy::AccuracyOptions = accuracy_options
end
```
Can be accessed as `validation_options`

```julia
mutable struct AccuracyOptions
    weight_accuracy::Bool   # uses weight accuracy where applicable.
    accuracy_mode::Symbol   # either :auto or :manual. :manual allows to specify weights manually for each class.
end
```

### Application options

```julia
mutable struct ApplicationOptions
    savepath::String     # specifies where results are saved.
    apply_by::Symbol     # either :file or :folder. If :folder is chosen, then results of files in the same folder are combined.
    data_type::Symbol    # output data type (:csv,:xlsx,:json,:bson).
    image_type::Symbol   # output image type (:png,:tiff,:json,:bson).
    scaling::Float64     # multiplies results by a specified factor
end
```
Can be accessed as `application_options`.

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
EasyML.forward
```

```@docs
EasyML.apply_border_data
```

## Manual training data assignment

```@docs
EasyML.set_training_data
```

```@docs
EasyML.set_testing_data
```

```@docs
EasyML.set_weights
```
