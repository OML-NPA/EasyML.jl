
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

function url_pusher()
    url  = popfirst!(EasyMLDataPreparation.unit_test.urls)
    return url
end
EasyMLDataPreparation.unit_test.url_pusher = url_pusher

set_problem_type(:Classification)
EasyMLDataPreparation.unit_test.urls = ["examples/classification/test"]
get_urls()

set_problem_type(:Regression)
EasyMLDataPreparation.unit_test.urls = ["examples/regression/test","examples/regression/test.csv"]
get_urls()

set_problem_type(:Segmentation)
EasyMLDataPreparation.unit_test.urls = ["examples/segmentation/images","examples/segmentation/labels"]
get_urls()

save_model("models/segmentation.model")

EasyMLDataPreparation.unit_test.urls = [""]
load_model()
EasyMLDataPreparation.unit_test.urls = ["models/segmentation.model"]
load_model()
load_options()

#---Other----------------------------------------

map(i -> set_problem_type(i),0:2)