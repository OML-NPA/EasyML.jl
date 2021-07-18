
using EasyMLValidation, Test

EasyMLValidation.unit_test.state = true

#---Main Functionality---------------------------------------------------------

@testset "Options" begin
    @test begin modify(global_options); true end
    @test begin modify(validation_options); true end
end

for i = 1:2
    if i==1
        validation_options.Accuracy.weight_accuracy = true
        global_options.HardwareResources.allow_GPU = true
    else
        validation_options.Accuracy.weight_accuracy = false
        global_options.HardwareResources.allow_GPU = false
        global_options.HardwareResources.num_slices = 5
    end

    @testset "Classfication" begin
        load_model("models/classification.model")
        @test begin 
            make_classes()
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
        load_model("models/regression.model")
        @test begin 
            make_classes()
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
        save_model("models/segmentation.model")
        @test begin 
            make_classes()
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
end


#---Other QML---------------------------------------------------------
@testset "Other QML" begin
    @test begin EasyMLValidation.set_options(["GlobalOptions","Graphics","scaling_factor"],1); true end
    @test begin
        model_data.problem_type = Classification
        push!(EasyMLValidation.unit_test.urls, "examples/with labels/classification/test")
        get_urls_validation()
        model_data.problem_type = Regression
        push!(EasyMLValidation.unit_test.urls, "examples/with labels/regression/test","examples/with labels/regression/test.csv")
        get_urls_validation()
        model_data.problem_type = Segmentation
        push!(EasyMLValidation.unit_test.urls, "examples/with labels/segmentation/images","examples/with labels/segmentation/labels")
        get_urls_validation()
        true
    end
end


#---Other------------------------------------------------------------
@testset "Other" begin
    @test begin EasyMLValidation.conn(8); true end
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