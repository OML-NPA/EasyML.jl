
using EasyMLClasses

EasyMLClasses.bind!(EasyMLClasses.EasyMLCore.unit_test, EasyMLClasses.unit_test)
EasyMLClasses.unit_test.state = true

make_classes()
EasyMLClasses.unit_test.urls = [""]
save_model()

load_model("models/classification.model")
make_classes()
save_model("models/classification.model")

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

EasyMLClasses.get_input_type()

EasyMLClasses.unit_test.urls = ["models2/segmentation.model"]
save_model()

EasyMLClasses.unit_test.urls = [""]
load_model()
EasyMLClasses.unit_test.urls = ["models/segmentation.model"]
load_model()


#---Other---------------------------------------------

EasyMLClasses.get_class_data(model_data.classes)

EasyMLClasses.input_type()

