
using EasyMLClasses

EasyMLClasses.unit_test.state = true

make_classes()

load_model("models/classification.model")
make_classes()

load_model("models/regression.model")
make_classes()

load_model("models/segmentation.model")
make_classes()


#---Other QML------------------------------------------

EasyMLClasses.set_problem_type(0)
EasyMLClasses.get_problem_type()
EasyMLClasses.set_problem_type(1)
EasyMLClasses.get_problem_type()
EasyMLClasses.set_problem_type(2)
EasyMLClasses.get_problem_type()

EasyMLClasses.get_input_type()

#---Other---------------------------------------------

EasyMLClasses.get_class_data(model_data.classes)
