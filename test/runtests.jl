
using EasyMLDesign

EasyMLDesign.unit_test.state = true

set_savepath("models/test.model")
set_problem_type(:Classification)

# Empty model
design_model()

# Flatten error model
load_model("models/flatten_error_test.model")
design_model()

# No output error model
load_model("models/no_output_error_test.model")
design_model()

# All layers test model
load_model("models/all_test.model")
design_model()

# Losses
load_model("models/minimal_test.model")
losses = ["MAE","MSE","MSLE","Huber","Crossentropy","Logit crossentropy","Binary crossentropy",
    "Logit binary crossentropy","Kullback-Leiber divergence","Poisson","Hinge","Squared hinge",
    "Dice coefficient","Tversky"]
for i = 1:length(losses)
    model_data.layers_info[end].loss = (losses[i],i+1)
    design_model()
end

# QML other
set_problem_type(0)
set_problem_type(1)
set_problem_type(2)

fields = ["DesignOptions","width"]
value = 340
set_options_main(options,fields,args...)

# Other
save_model("models/test.model")
load_options()
save_options()

try
    load_model("my_model")
catch e
    if !(e isa ErrorException)
        error("Wrong error returned.")
    end
end
