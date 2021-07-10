
using EasyMLClasses

EasyMLClasses.unit_test.state = true

load_model("models/classification.model")
make_classes()

load_model("models/regression.model")
make_classes()

load_model("models/segmentation.model")
make_classes()
save_model("models/segmentation.model")


#---Other QML------------------------------------------

EasyMLClasses.set_problem_type(0)
EasyMLClasses.get_problem_type()
EasyMLClasses.set_problem_type(1)
EasyMLClasses.get_problem_type()
EasyMLClasses.set_problem_type(2)
EasyMLClasses.get_problem_type()

function url_pusher()
    url  = popfirst!(EasyMLClasses.unit_test.urls)
    return url
end
EasyMLClasses.unit_test.url_pusher = url_pusher

EasyMLClasses.unit_test.urls = ["models2/segmentation.model"]
save_model()

EasyMLClasses.unit_test.urls = [""]
load_model()
EasyMLClasses.unit_test.urls = ["models/segmentation.model"]
load_model()


#---Other---------------------------------------------

EasyMLClasses.input_type()

