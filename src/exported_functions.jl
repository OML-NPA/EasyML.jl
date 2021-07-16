
"""
    make_classes()

Opens a GUI for addition or modification of classes.
"""
function make_classes()
    classes = model_data.classes
    if length(classes)==0
        ids = [0]
        JindTree = -1
    else
        ids = 1:length(classes)
        JindTree = 0
    end
    @qmlfunction(
        # Classes
        get_class_field,
        num_classes,
        append_classes,
        reset_classes,
        # Problem
        get_problem_type,
        set_problem_type,
        # Options
        get_options,
        # Other
        unit_test
    )
    path_qml = string(@__DIR__,"/gui/ClassDialog.qml")
    gui_dir = string("file:///",replace(@__DIR__, "\\" => "/"),"/gui/")
    text = add_templates(path_qml)
    loadqml(QByteArray(text), gui_dir = gui_dir, JindTree = JindTree, ids = ids)
    exec()
    return nothing
end