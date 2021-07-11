
using EasyMLValidation

EasyMLValidation.unit_test.state = true

modify(global_options)
modify(validation_options)

# Classification
load_model("models/classification.model")
#make_classes()
url_data = "examples/with labels/classification/test"
get_urls_validation(url_data)
results = validate()
remove_validation_data()
remove_validation_results()

# Regression
load_model("models/regression.model")
#make_classes()
url_input = "examples/with labels/regression/test"
url_labels = "examples/with labels/regression/test.csv"
get_urls_validation(url_input,url_labels)
results = validate()
remove_validation_data()
remove_validation_results()

# Segmentation
load_model("models/segmentation.model")
# make_classes()
url_input = "examples/with labels/segmentation/images"
url_labels = "examples/with labels/segmentation/labels"
get_urls_validation(url_input,url_labels)
results = validate()
remove_validation_data()
remove_validation_results()

# Other

EasyMLValidation.unit_test.urls = ["models/classification.model"]
load_model()
load_options()