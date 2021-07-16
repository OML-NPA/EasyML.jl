
using EasyMLDesign, Test

EasyMLDesign.EasyMLCore.unit_test.state = true

#---Main functionality----------------------------------------------------

@testset "Main functionality" begin

    set_savepath("models/test.model")
    set_problem_type(Classification)

    # Empty model
    @test begin design_model(); true end

    # All layers test model
    @test begin 
        load_model("models/all_test.model")
        design_model()
        true
    end

    # Flatten error model
    @test begin 
        load_model("models/flatten_error_test.model")
        design_model()
        true
    end

    # No output error model
    @test begin 
        load_model("models/no_output_error_test.model")
        design_model()
        true
    end

    # Losses
    @test begin 
        load_model("models/minimal_test.model")
        losses = 0:13
        for i = 1:length(losses)
            model_data.layers_info[end].loss = losses[i]
            design_model()
        end
        true
    end
end


#---Other QML----------------------------------------------------------

@testset "Other QML" begin
    @test begin
        set_problem_type(0)
        set_problem_type(1)
        set_problem_type(2)
        EasyMLDesign.get_input_type()
        true
    end

    @test begin
        fields = ["DesignOptions","width"]
        value = 340
        EasyMLDesign.set_options(fields,value)
        true
    end
end
