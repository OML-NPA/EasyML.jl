
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
