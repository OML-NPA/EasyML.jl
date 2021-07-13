
using EasyMLDesign, Test

EasyMLDesign.bind!(EasyMLDesign.EasyMLCore.unit_test, EasyMLDesign.unit_test)
EasyMLDesign.unit_test.state = true

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
        losses = ["MAE","MSE","MSLE","Huber","Crossentropy","Logit crossentropy","Binary crossentropy",
            "Logit binary crossentropy","Kullback-Leiber divergence","Poisson","Hinge","Squared hinge",
            "Dice coefficient","Tversky"]
        for i = 1:length(losses)
            model_data.layers_info[end].loss = (losses[i],i+1)
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

    @test begin
        EasyMLDesign.unit_test.urls = ["models/test.model"]
        save_model()
        true
    end

    @test begin
        EasyMLDesign.unit_test.urls = ["models/test.model"]
        load_model()
        rm("models/test.model")
        true
    end

    @test begin
        EasyMLDesign.set_data(["DesignData","warnings"],[])
        true
    end
end

#---Other---------------------------------------------------------------

@testset "Other" begin

    @test begin 
        EasyMLDesign.input_type()
        set_input_type(Image)
        true
    end

    @test begin
        save_model("models/test.model")
        load_options()
        save_options()
        true
    end

    @test begin
        try
            load_model("my_model")
        catch e
            if !(e isa ErrorException)
                error("Wrong error returned.")
            end
        end
        set_savepath("model")
        true
    end
end
