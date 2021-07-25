
using EasyML.Design
import EasyML.Design

cd(string(dir,"/design"))


#---Main functionality----------------------------------------------------

@testset "Main functionality" begin

    set_savepath("models/test.model")

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
        Design.set_problem_type(0)
        Design.get_problem_type()
        Design.set_problem_type(1)
        Design.get_problem_type()
        Design.set_problem_type(2)
        Design.get_problem_type()
        Design.get_input_type()
        true
    end

    @test begin
        fields = ["DesignOptions","width"]
        value = 340
        Design.set_options(fields,value)
        true
    end
end
