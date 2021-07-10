
using EasyMLDataPreparation

EasyMLDataPreparation.unit_test.state = true

modify(data_preparation_options)

for i = 1:2

    if i==2
        EasyMLDataPreparation.image_preparation_options.grayscale = false
        EasyMLDataPreparation.image_preparation_options.mirroring = false
        EasyMLDataPreparation.image_preparation_options.num_angles = 1
    end

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

end

set_problem_type(:Classification)
EasyMLDataPreparation.prepared_data.ClassificationData = EasyMLDataPreparation.ClassificationData()
prepare_data()
load_model("models/classification.model")
url_input = "examples\\classification\\"
get_urls(url_input)
EasyMLDataPreparation.unit_test.urls = ["examples/classification/test"]
get_urls()

set_problem_type(:Regression)
EasyMLDataPreparation.prepared_data.RegressionData = EasyMLDataPreparation.RegressionData()
prepare_data()
load_model("models/regression.model")
url_input = "examples/regression/"
url_label = "examples/regression/test.csv"
get_urls(url_input,url_label)
EasyMLDataPreparation.unit_test.urls = ["examples/regression/test","examples/regression/test.csv"]
get_urls()

set_problem_type(:Segmentation)
EasyMLDataPreparation.prepared_data.SegmentationData = EasyMLDataPreparation.SegmentationData()
prepare_data()
load_model("models/segmentation.model")
url_input = "examples/segmentation/"
url_label = "examples/segmentation/labels"
get_urls(url_input,url_label)
EasyMLDataPreparation.unit_test.urls = ["examples/segmentation/images","examples/segmentation/labels"]
get_urls()

save_model("models/segmentation.model")

EasyMLDataPreparation.unit_test.urls = [""]
load_model()
EasyMLDataPreparation.unit_test.urls = ["models/segmentation.model"]
load_model()
load_options()

#---Other----------------------------------------

fields = ["DataPreparationOptions","Images","mirroring"]
EasyMLDataPreparation.set_options_main(EasyMLDataPreparation.options,fields,true)

EasyMLDataPreparation.set_model_data("input_properties",["Grayscale"])