
using EasyMLDesign

EasyMLDesign.unit_test.state = true

set_savepath("models/test.model")
set_problem_type(:Classification)

load_model("models/test.model")

design_model()

save_model("models/test.model")
load_options()
save_options()

