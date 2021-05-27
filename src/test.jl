
using EasyML
cd("C:/Users/a_ill/Documents/GitHub/EasyML.jl/src")

# Design

load_model("models/classification.model")
# save_model("models/classification.model")

# load_model("models/segmentation.model")
# save_model("models/segmentation.model")


feature1 = Segmentation_feature(name = "Cell", color = [0,255,0], border = true, 
    border_thickness = 5, border_remove_objs = true, min_area = 50)
feature2 = Segmentation_feature(name = "Vacuole",color = [255,0,0], border = false, 
    border_thickness = 5, border_remove_objs = true, min_area = 5, parents = ["Cell",""])
features = [feature1,feature2]
model_data.features = features

features = Vector{Classification_feature}(undef,0)
for i in 0:9
    push!(features,Classification_feature(name = string(i)))
end
model_data.features = features

modify_feature(1)

design_network()

# Training
modify(training_options)

input_dir = "C:/Users/a_ill/Documents/GitHub/EasyML.jl/src/Examples/Segmentation/Train/Images"
label_dir = "C:/Users/a_ill/Documents/GitHub/EasyML.jl/src/Examples/Segmentation/Train/Labels"
get_urls_training(input_dir,label_dir)

input_dir = "C:/Users/a_ill/Documents/GitHub/EasyML.jl/src/Examples/Classification/Train"


prepare_training_data()

results = train()

# Validation
input_dir = "C:/Users/a_ill/Documents/GitHub/EasyML.jl/src/Examples/Segmentation/Test/Images"
label_dir = "C:/Users/a_ill/Documents/GitHub/EasyML.jl/src/Examples/Segmentation/Test/Labels"
get_urls_validation(input_dir,label_dir)

results = validate()

# Application
modify(application_options)

modify_output(model_data.features[2])

input_dir = "C:/Users/a_ill/Documents/GitHub/EasyML.jl/src/Examples/Segmentation/Test/Images"
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

data_input = EasyML.training_data.Classification_data.data_input
for i in 1:length(data_input)
    if !isassigned(data_input,i)
        @info i
        return
    end
end

