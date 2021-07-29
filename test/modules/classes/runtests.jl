
using EasyML.Classes
import EasyML.Classes

cd(@__DIR__)

#---Main functionality------------------------------------------

@testset "Make classes" begin
    @test begin make_classes(); true end

    @test begin
        load_model(joinpath(models_dir,"classification.model"))
        make_classes()
        true
    end

    @test begin
        load_model(joinpath(models_dir,"regression.model"))
        make_classes()
        true
    end

    @test begin
        load_model(joinpath(models_dir,"segmentation.model"))
        make_classes()
        true
    end
end


#---Other QML-----------------------------------------------------

@testset "Other QML" begin
    @test begin 
        Classes.set_problem_type(0)
        Classes.get_problem_type()
        Classes.set_problem_type(1)
        Classes.get_problem_type()
        Classes.set_problem_type(2)
        Classes.get_problem_type()

        Classes.get_input_type()
        true
    end
end


#---Other--------------------------------------------------------

@testset "Other" begin
    @test begin 
        Classes.get_class_data(model_data.classes)
        true
    end
end
