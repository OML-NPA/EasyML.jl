
# Start a distributed process
using Distributed
if nprocs() < 2
    addprocs(1)
end
# Add MLGUI module to all workers
@everywhere include("MLGUI.jl")
@everywhere using .MLGUI

load_model("models/yeast.model")

feature1 = Feature(name = "Cell", color = [0,255,0], border = true, parent = "")
feature2 = Feature(name = "Vacuole", color = [255,0,0], border = false, parent = "Cell")
features = [feature1,feature2]
model_data.features = features

design_network()

url_inputs = "C:/Users/a_ill/Documents/GitHub/MLGUI.jl/source/Batch/Training/Images"
url_labels = "C:/Users/a_ill/Documents/GitHub/MLGUI.jl/source/Batch/Training/Labels"
urls_inputs, urls_labels = get_urls(url_inputs,url_labels)

data_inputs, data_labels = prepare_training_data(urls_inputs,urls_labels)

results = train(data_inputs,data_labels)

data = prepare_validation_data(urls_inputs,urls_labels)

results = validate(data)

data = prepare_analysis_data(urls_inputs)

model = model_data.model
results = Vector{BitArray{3}}(undef,0)
for i = 1:length(data)
    output_raw = forward(model,data[i],num_parts=10)
    output_bool = output_raw[:,:,:].>0.5
    output = MLGUI.apply_border_data(output_bool)
    push!(results,output)
end
