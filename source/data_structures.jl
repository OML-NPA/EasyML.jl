
#---Channels
@with_kw struct Channels
    training_progress::RemoteChannel = RemoteChannel(()->Channel{Any}(Inf))
    training_results::RemoteChannel = RemoteChannel(()->Channel{Any}(Inf))
    training_modifiers::RemoteChannel = RemoteChannel(()->Channel{Any}(Inf))
    validation_progress::RemoteChannel = RemoteChannel(()->Channel{Any}(Inf))
    validation_results::RemoteChannel = RemoteChannel(()->Channel{Any}(Inf))
    validation_modifiers::RemoteChannel = RemoteChannel(()->Channel{Any}(Inf))
    training_labels_colors::RemoteChannel = RemoteChannel(()->Channel{Any}(Inf))
    analysis_progress::RemoteChannel = RemoteChannel(()->Channel{Any}(Inf))
    analysis_modifiers::RemoteChannel = RemoteChannel(()->Channel{Any}(Inf))
end
channels = Channels()

#---Model data
@with_kw mutable struct Output_mask
    mask::Bool = false
    mask_border::Bool = false
    mask_applied_border::Bool = false
end
output_mask = Output_mask()

@with_kw mutable struct Output_area
    area_distribution::Bool = false
    individual_obj_area::Bool = false
    binning::Int64 = 0
    value::Float64 = 10
    normalisation::Int64 = 0
end
output_area = Output_area()

@with_kw mutable struct Output_volume
    volume_distribution::Bool = false
    individual_obj_volume::Bool = false
    binning::Int64 = 0
    value::Float64 = 10
    normalisation::Int64 = 0
end
output_volume = Output_volume()

@with_kw mutable struct Output_options
    Mask::Output_mask = output_mask
    Area::Output_area = output_area
    Volume::Output_volume = output_volume
end
output_options = Output_options()

@with_kw mutable struct Feature
    name::String = ""
    color::Vector{Float64} = Vector{Float64}(undef,3)
    border::Bool = false
    parent::String = ""
    Output::Output_options = output_options
end
feature = Feature()

@with_kw mutable struct Model_data
    input_size::Tuple{Int64,Int64,Int64} = (160,160,1)
    model::Chain = Chain()
    layers::Vector{Dict{String,Any}} = []
    features::Vector{Feature} = []
    loss::Function = Losses.crossentropy
end
model_data = Model_data()

#---Master data
@with_kw mutable struct Training_plot_data
    loss::Union{Vector{Float32},Vector{Float64}} = Vector{Float32}(undef,0)
    accuracy::Union{Vector{Float32},Vector{Float64}} = Vector{Float32}(undef,0)
    test_accuracy::Union{Vector{Float32},Vector{Float64}} = Vector{Float32}(undef,0)
    test_loss::Union{Vector{Float32},Vector{Float64}} = Vector{Float32}(undef,0)
    test_iteration::Vector{Int64} = Vector{Int64}(undef,0)
    iteration::Int64 = 0
    epoch::Int64 = 0
    iterations_per_epoch::Int64 = 0
    starting_time::DateTime = now()
    max_iterations::Int64 = 0
    learning_rate_changed::Bool = false
end
training_plot_data = Training_plot_data()

#---Master data

@with_kw mutable struct Validation_plot_data
    data_input_orig::Vector{Array{RGB{Normed{UInt8,8}},2}} =
        Vector{Array{RGB{Normed{UInt8,8}},2}}(undef,1)
    data_labels_orig::Vector{Array{RGB{Normed{UInt8,8}},2}} =
        Vector{Array{RGB{Normed{UInt8,8}},2}}(undef,1)
    data_predicted::Vector{Vector{Array{RGB{Float32},2}}} =
        Vector{Vector{Array{RGB{Float32},2}}}(undef,1)
    data_error::Vector{Vector{Array{RGB{Float32},2}}} =
        Vector{Vector{Array{RGB{Float32},2}}}(undef,1)
    data_target::Vector{Vector{Array{RGB{Float32},2}}} =
        Vector{Vector{Array{RGB{Float32},2}}}(undef,1)
end
validation_plot_data = Validation_plot_data()

@with_kw mutable struct Validation_results_data
    loss_std::Union{Float32,Float64} = 0.0f0
    accuracy_std::Union{Float32,Float64} = 0.0f0
    loss::Union{Vector{Float32},Vector{Float64}} = Vector{Float32}(undef,0)
    accuracy::Union{Vector{Float32},Vector{Float64}} = Vector{Float32}(undef,0)
end
validation_results_data = Validation_results_data()

@with_kw mutable struct Validation_data
    Validation_plot_data::Validation_plot_data = validation_plot_data
    Validation_results_data::Validation_results_data = validation_results_data
end
validation_data = Validation_data()

@with_kw mutable struct Training_results_data
    loss::Union{Vector{Float32},Vector{Float64}} = Vector{Float32}(undef,0)
    accuracy::Union{Vector{Float32},Vector{Float64}} = Vector{Float32}(undef,0)
    test_accuracy::Union{Vector{Float32},Vector{Float64}} = Vector{Float32}(undef,0)
    test_loss::Union{Vector{Float32},Vector{Float64}} = Vector{Float32}(undef,0)
    test_iterations::Vector{Int64} = Vector{Int64}(undef,0)
end
training_results_data = Training_results_data()

@with_kw mutable struct Training_data
    Training_results_data::Training_results_data = training_results_data
    Validation_results_data::Validation_results_data = validation_results_data
    url_imgs::Vector{String} = Vector{String}(undef,0)
    url_labels::Vector{String} = Vector{String}(undef,0)
end
training_data = Training_data()

@with_kw mutable struct Analysis_data
    url_imgs::Vector{String} = Vector{String}(undef,0)
    folders::Vector{String} = Vector{String}(undef,0)
    data_input::Vector{Array{Float32,4}} = Vector{Array{Float32,4}}(undef,1)
end
analysis_data = Analysis_data()

@with_kw mutable struct Master_data
    Training_data::Training_data = training_data
    Validation_data::Validation_data = validation_data
    Analysis_data::Analysis_data = analysis_data
    image::Array{RGB{Float32},2} = Array{RGB{Float32},2}(undef,10,10)
end
master_data = Master_data()

#---Settings
# Main
@with_kw mutable struct Main_s
    a::Int = 0
end
main = Main_s()

# Options
@with_kw mutable struct Hardware_resources
    allow_GPU::Bool = true
    num_cores::Int64 = Threads.nthreads()
end
hardware_resources = Hardware_resources()
@with_kw mutable struct Options
    Hardware_resources::Hardware_resources = hardware_resources
end
options = Options()

# Training
@with_kw mutable struct Processing_training
    mirroring::Bool = true
    num_angles::Int64 = 2
    min_fr_pix::Float64 = 0
end
processing_training = Processing_training()

@with_kw mutable struct Hyperparameters_training
    optimiser::Tuple{String,Int64} = ("ADAM",5)
    optimiser_params::Vector{Vector{Float64}} = [[],[0.9],[0.9],[0.9],
      [0.9,0.999],[0.9,0.999],[0.9,0.999],[],[0.9],[0.9,0.999],
      [0.9,0.999],[0.9,0.999,0]]
    optimiser_params_names::Vector{Vector{String}} = [[],["ρ"],
      ["ρ"],["ρ"],
      ["β1","β2"],
      ["β1","β2"],
      ["β1","β2"],[],
      ["ρ"],["β1","β2"],
      ["β1","β2"],
      ["β1","β2","Weight decay"]]
    learning_rate::Float64 = 1e-3
    epochs::Int64 = 1
    batch_size::Int64 = 10
    savepath::String = "./"
end
hyperparameters_training = Hyperparameters_training()

@with_kw mutable struct General_training
    weight_accuracy::Bool = true
    test_data_fraction::Float64 = 0
    testing_frequency::Float64 = 5
end
general_training = General_training()

@with_kw mutable struct Training_options
    General::General_training = general_training
    Processing::Processing_training = processing_training
    Hyperparameters::Hyperparameters_training = hyperparameters_training
end
training_options = Training_options()

@with_kw mutable struct Design
    width::Float64 = 340
    height::Float64 = 100
    min_dist_x::Float64 = 40
    min_dist_y::Float64 = 40
end
design = Design()

@with_kw mutable struct Training
    Options::Training_options = training_options
    Design::Design = design
    problem_type::Tuple{String,Int64} = ("Classification",0)
    input_type::Tuple{String,Int64} = ("Image",0)
    template::String = ""
    images::String = ""
    labels::String = ""
    name::String = "new"
    type::String = "segmentation"
end
training = Training()

# Analysis
@with_kw mutable struct Analysis_options
    savepath::String = ""
    analyse_by::Tuple{String,Int64} = ("file",0)
    data_type::Int64 = 0
    image_type::Int64 = 0
    downsize::Int64 = 0
    skip_frames::Int64 = 0
    scaling::Float64 = 1
    minibatch_size::Int64 = 1
end
analysis_options = Analysis_options()

@with_kw mutable struct Analysis
    Options::Analysis_options = analysis_options
    folder_url::String = ""
    model_url::String = ""
    checked_folders::Vector{String} = String[]
end
analysis = Analysis()

# Visualisation
@with_kw mutable struct Visualisation
    a::Int = 0
end
visualisation = Visualisation()

# Settings
@with_kw mutable struct Settings
    Main::Main_s = main
    Options::Options = options
    Training::Training = training
    Analysis::Analysis = analysis
    Visualisation::Visualisation = visualisation
end
settings = Settings()
