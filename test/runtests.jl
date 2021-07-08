
using EasyMLDataPreparation

EasyMLDataPreparation.unit_test.state = true

modify(data_preparation_options)


set_problem_type(:Classification)
load_model("models/classification.model")
make_classes()
url_input = "examples\\classification\\test"
get_urls(url_input)
results = prepare_data()


set_problem_type(:Regression)
load_model("models/regression.model")
make_classes()
url_input = "examples/regression/test"
url_label = "examples/regression/test.csv"
get_urls(url_input,url_label)
results = prepare_data()


set_problem_type(:Segmentation)
load_model("models/segmentation.model")
make_classes()
url_input = "examples/segmentation/images"
url_label = "examples/segmentation/labels"
get_urls(url_input,url_label)
results = prepare_data()

save_model("models/segmentation.model")

load_model()
load_options()