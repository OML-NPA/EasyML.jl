
using EasyMLValidation

EasyMLValidation.unit_test.state = true

modify(global_options)
modify(validation_options)

for i = 1:2
    if i==2
        validation_options.Accuracy.weight_accuracy = false
        global_options.HardwareResources.num_slices = 5
    end

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
    save_model("models/segmentation.model")
end

#---Other QML---------------------------------------------------------

EasyMLValidation.unit_test.urls = ["models/classification.model"]
load_model()
load_options()

EasyMLValidation.set_options(["GlobalOptions","Graphics","scaling_factor"],1)

EasyMLValidation.unit_test.urls = ["models/test.model"]
save_model()

@info "Testing get_urls_validation()"
set_problem_type(:Classification)
EasyMLValidation.unit_test.urls = ["examples/with labels/classification/test"]
get_urls_validation()
set_problem_type(:Regression)
EasyMLValidation.unit_test.urls = ["examples/with labels/regression/test","examples/with labels/regression/test.csv"]
get_urls_validation()
set_problem_type(:Segmentation)
EasyMLValidation.unit_test.urls = ["examples/with labels/segmentation/images","examples/with labels/segmentation/labels"]
get_urls_validation()


#---Other------------------------------------------------------------
@info "Testing other"
conn(8)

remove_validation_data()
validate()
empty!(model_data.classes)
validate()
model_data.model = Flux.Chain()
validate()

make_dir("test_dir/test_dir2")

set_problem_type(:Classification)

max_num_threads()

num_threads()