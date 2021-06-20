# EasyML.jl
[![Donate](https://img.shields.io/badge/Donate-PayPal-blue.svg)](https://www.paypal.com/donate/?hosted_button_id=EJ2J3BVKYPJPY)

This package allows to use machine learning in Julia through a graphical user interface.

NB! This is a an alpha version. Bugs and rapid changes should be expected!

### Features
Flux.jl neural network library is used. Currently it is possible to:
  - Design a neural network
  - Train a neural network
  - Validate a neural network
  - Apply a neural network to new data
  
Classification, regression and segmentation on images are currently supported.

### Usage 

#### Setting up
Add the package from this repository to Julia using 

`] add https://github.com/OML-NPA/EasyML.jl`

and then write

`using EasyML`

NB! Add `QML` dependency using `] add QML#master` because the package relies on recent changes that were not released yet.

#### Model creation
A struct named `model_data` is exported.

- `model::Chain`: Flux.jl model.

- `layers_info::Vector{AbstractLayerInfo}`: contains information for visualisation of layers.

- `loss::Function`: holds loss that is used during training.

- `input_size::Tuple{Int64,Int64,Int64}`: model input size.

- `input_size::Union{Tuple{Int64},Tuple{Int64,Int64,Int64}}`: model output size.

- `classes::Vector{<:AbstractClass}`: hold information about classes that a neural network outputs and what should be done with them.

-  `OutputOptions::Vector{<:AbstractOutputOptions}`: hold information about output options for each class for application of the model.

It is suggested to modify the fields using a GUI. 

`modify_classes()` allows to add and modify classes.

`modify_output()` allows to modify output options.

`design_network()` opens a GUI for neural network creation. Click a save icon to save your network.

<img  src="docs/screenshots/design.png" height = 340em>

NB! A number of neurons for the final layer should equal to the number of classes plus the number of borders that should be detected in case of segmentation.

`save_model(url::String)`: saves your model. Use `.model` extension.

`load_model(url::String)`: loads your model.

#### Training

Training parameters can be changed by running `modify(training_options)`.

`get_urls_training(url_inputs::String,url_labels::String)`: gets URLs to all files present in both folders (a folder and a file) specified 
by `url_inputs` and `url_labels`. URLs are automatically saved to `EasyML.training_data`.

`get_urls_training()` opens folder dialogs where you can choose directories with input and label data.

`prepare_training_data()`: prepares your images and corresponding labels for training using URLs loaded previously. Saves data to `EasyML.training_data`.

`results = train()`: opens a training window and trains your neural network. Returns a struct containing loss, accuracy and iterations at which tests were performed.

<img  src="docs/screenshots/training.png" height = 340em>

#### Validation

`get_urls_validation(url_inputs::String,url_labels::String)`: gets URLs to all files present in both folders (or a folder and a file) specified 
by `url_inputs` and `url_labels`. URLs are automatically saved to `EasyML.validation_data`.

`get_urls_validation(url_inputs::String)`: gets URLs to all files present in a folder specified by `url_inputs`. 
URLs are automatically saved to `EasyML.validation_data`. Does not require labels.

`get_urls_validation()` opens folder dialogs where you can choose directories with input and label data (if available).

`prepare_validation_data()`: prepares your data for validation. Saves it to `EasyML.validation_data`. Progress is reported to REPL.

`results = validate()`: opens a validation window and returns results with predicted masks, target masks and masks with differences between them.

<img  src="docs/screenshots/validation.png" height = 340em>

#### Application

Application settings can be changed by running `modify(application_options)`.

`get_urls_application(url_inputs::String)`: gets URLs to all files present in a folder specified by `url_inputs`. 
URLs are automatically saved to `EasyML.application_data`.

`get_urls_application()` opens a folder dialog where you can choose a directory with input data.

`apply()`: starts application of your model. Progress is reported to REPL. Results are saved to a folder specified in `application_options`.

#### Other

Settings from the last run are automatically imported provided that a file `config.bson` is in a current directory. 
If that was not the case, the settings can be imported manually using `load_settings()` after switching the current directory. 

#### Custom

##### Assigning classes

Classes can be modified manually.

Create a new class using `ImageClassificationClass()`, `ImageRegressionClass()` or `ImageSegmentationClass()`.

Classes can be of different types depending on a type of a problem.

`ImageClassificationClass` contains

- `name::String`: name of a class.

- `Output::ImageClassificationOutputOptions`: holds settings for output of application of a model to new data.

`ImageRegressionClass` contains

- `name::String`: name of a class.

- `Output::ImageRegressionOutputOptions`: holds settings for output of application of a model to new data.

`ImageSegmentationClass` contains

- `name::String`: name of a class.

- `color::Vector{Float64}`: RGB color of a class, which should correspond to its color on your images. Use 0-255 range.

- `border::Bool`: allows to train a neural network to recognize borders and better separate objects during post-processing.

- `border_thickness::Int64`: border thickness in pixels.

- `min_area::Int64`: minimum area of an object.

- `parents::Vector{String}`: up to two parents can be specified by their name. Objects from a child are added to its parent.

- `Output::ImageSegmentationOutputOptions`: holds settings for output of application of a model to new data.

Put your classes into a vector and write `model_data.classes = your_classes`.

You can forward any suitable input data through a neural network using the following code

##### Custom loop

An example loop for segmentation:
```
model = model_data.model
data_example = [ones(Float32,160,160,1,1),ones(Float32,160,160,1,1)]
results = Vector{BitArray{3}}(undef,0)
for i = 1:length(data_example)
    output_raw = forward(model,data_example[i],num_parts=1)
    output_bool = output_raw[:,:,:].>0.5
    output = apply_border_data(output_bool,model_data.classes) 
    push!(results,output)
end
```
`num_parts` specifies in how many parts should an array be run thorugh a neural network. 
Allows to process images that otherwise cause out of memory error.

`apply_border_data` uses borders of objects that a neural network detected in order to separate objects from each other.
