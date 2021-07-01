
"""
    modify_classes()

Opens a GUI for addition or modification of classes.
"""
function modify_classes()
    classes = model_data.classes
    if length(classes)==0
        ids = [0]
        JindTree = -1
    else
        ids = 1:length(classes)
        JindTree = 0
    end
    @qmlfunction(
        get_class_field,
        num_classes,
        append_classes,
        reset_classes,
        get_problem_type,
        set_problem_type,
        get_options,
        set_options,
        save_options
    )
    path_qml = string(@__DIR__,"/GUI/ClassDialog.qml")
    loadqml(path_qml,JindTree = JindTree, ids = ids)
    exec()
    return nothing
end

# Design
"""
    design_model()

Opens a GUI for creation of a model.
"""
function design_model()
    # Launches GUI
    @qmlfunction(
        # Handle classes
        model_count,
        model_get_layer_property,
        model_properties,
        # Model functions
        get_max_id,
        reset_layers,
        update_layers,
        make_model,
        check_model,
        move_model,
        save_model,
        load_model,
        # Model design
        arrange,
        # Data handling
        get_data,
        set_data,
        get_options,
        set_options,
        save_options,
        # Other
        source_dir
    )
    path_qml = string(@__DIR__,"/GUI/Design.qml")
    loadqml(path_qml)
    exec()

    return nothing
end
