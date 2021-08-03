
using EasyML.Validation
import EasyML.Validation

cd(@__DIR__)

global_options.HardwareResources.num_slices = 1


#---Main functionality---------------------------------------------------------

@testset "Options" begin
    @test begin change(global_options); true end
    @test begin change(validation_options); true end
end
rm("options.bson")

validation_options.Accuracy.weight_accuracy = true
global_options.HardwareResources.allow_GPU = true

@testset "Classfication" begin
    load_model(joinpath(models_dir,"classification.model"))
    @test begin 
        change_classes()
        true
    end
    @test begin 
        url_data = "examples/with labels/classification/test"
        get_urls_validation(url_data)
        true
    end
    @test begin 
        results = validate()
        remove_validation_data()
        remove_validation_results()
        true
    end
end

@testset "Regression" begin
    load_model(joinpath(models_dir,"regression.model"))
    @test begin 
        change_classes()
        true
    end
    @test begin 
        url_input = "examples/with labels/regression/test"
        url_labels = "examples/with labels/regression/test.csv"
        get_urls_validation(url_input,url_labels)
        true
    end
    @test begin
        results = validate()
        remove_validation_data()
        remove_validation_results()
        true
    end
end

@testset "Segmentation" begin
    load_model(joinpath(models_dir,"segmentation.model"))
    @test begin 
        change_classes()
        true
    end
    @test begin 
        url_input = "examples/with labels/segmentation/images"
        url_labels = "examples/with labels/segmentation/labels"
        get_urls_validation(url_input,url_labels)
        true
    end
    @test begin
        results = validate()
        remove_validation_data()
        remove_validation_results()
        true
    end
end

validation_options.Accuracy.weight_accuracy = false
global_options.HardwareResources.allow_GPU = false

@testset "Classfication" begin
    load_model(joinpath(models_dir,"classification.model"))
    @test begin 
        change_classes()
        true
    end
    @test begin 
        url_data = "examples/without labels/classification/test"
        get_urls_validation(url_data)
        true
    end
    @test begin 
        results = validate()
        remove_validation_data()
        remove_validation_results()
        true
    end
end

@testset "Regression" begin
    load_model(joinpath(models_dir,"regression.model"))
    @test begin 
        change_classes()
        true
    end
    @test begin 
        url_input = "examples/without labels/regression/test"
        get_urls_validation(url_input)
        true
    end
    @test begin
        results = validate()
        remove_validation_data()
        remove_validation_results()
        true
    end
end

@testset "Segmentation" begin
    load_model(joinpath(models_dir,"segmentation.model"))
    @test begin 
        change_classes()
        true
    end
    @test begin 
        url_input = "examples/without labels/segmentation/images"
        get_urls_validation(url_input)
        true
    end
    @test begin
        results = validate()
        remove_validation_data()
        remove_validation_results()
        true
    end
end



#---Other QML---------------------------------------------------------
@testset "Other QML" begin
    @test begin Validation.set_options(["GlobalOptions","Graphics","scaling_factor"],1); true end
    @test begin
        model_data.problem_type = :classification
        push!(Validation.unit_test.urls, "examples/with labels/classification/test")
        get_urls_validation()
        model_data.problem_type = :regression
        push!(Validation.unit_test.urls, "examples/with labels/regression/test","examples/with labels/regression/test.csv")
        get_urls_validation()
        model_data.problem_type = :segmentation
        push!(Validation.unit_test.urls, "examples/with labels/segmentation/images","examples/with labels/segmentation/labels")
        get_urls_validation()
        true
    end
end


#---Other------------------------------------------------------------
@testset "Other" begin
    @test begin Validation.conn(8); true end
    @test begin 
        remove_validation_data()
        validate()
        empty!(model_data.classes)
        validate()
        model_data.model = Flux.Chain()
        validate()
        true
    end
end