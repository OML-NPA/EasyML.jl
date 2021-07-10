
using EasyMLClasses

EasyMLClasses.unit_test.state = true

load_model("models/classification.model")
make_classes()

load_model("models/regression.model")
make_classes()

load_model("models/segmentation.model")
make_classes()
save_model("models/segmentation.model")