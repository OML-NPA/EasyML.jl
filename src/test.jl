
using MLGUI
cd("C:/Users/a_ill/Documents/GitHub/MLGUI.jl/src")

# Design

load_model("models/new.model")

# save_model("models/new.model")

feature1 = Segmentation_feature(name = "Cell", color = [0,255,0], border = true, 
    border_thickness = 5, border_remove_objs = true, min_area = 50)
feature2 = Segmentation_feature(name = "Vacuole",color = [255,0,0], border = false, 
    border_thickness = 5, border_remove_objs = true, min_area = 5, parents = ["Cell",""])
features = [feature1,feature2]
model_data.features = features

modify(model_data.features[1])

design_network()

# Training
modify(training_options)

input_dir = "C:/Users/a_ill/Documents/GitHub/MLGUI.jl/src/Examples/Training/Images"
label_dir = "C:/Users/a_ill/Documents/GitHub/MLGUI.jl/src/Examples/Training/Labels"
get_urls_training(input_dir,label_dir)

prepare_training_data()

results = train()

# Validation
input_dir = "C:/Users/a_ill/Documents/GitHub/MLGUI.jl/src/Examples/Training/Images"
label_dir = "C:/Users/a_ill/Documents/GitHub/MLGUI.jl/src/Examples/Training/Labels"
get_urls_validation(input_dir,label_dir)

results = validate()

# Application
modify(application_options)

modify_output(model_data.features[2])

input_dir = "C:/Users/a_ill/Documents/GitHub/MLGUI.jl/src/Examples/Training/Images"
get_urls_application(input_dir)

apply()

# Custom
model = model_data.model
data = [ones(Float32,160,160,1,1)]
results = Vector{BitArray{3}}(undef,0)
for i = 1:length(data)
    output_raw = forward(model,data[i],num_parts=1)
    output_bool = output_raw[:,:,:].>0.5
    output = apply_border_data(output_bool,model_data.features)
    push!(results,output)
end