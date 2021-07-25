
using EasyMLDataPreparation, Test

EasyMLDataPreparation.unit_test.state = true

@testset "Opening options" begin
    @test begin modify(data_preparation_options); true end
end

for i = 1:2

    if i==1
        model_data.input_properties = [:grayscale]
        EasyMLDataPreparation.image_preparation_options.mirroring = true
        EasyMLDataPreparation.image_preparation_options.num_angles = 2
    else
        model_data.input_properties = Symbol[]
        EasyMLDataPreparation.image_preparation_options.mirroring = false
        EasyMLDataPreparation.image_preparation_options.num_angles = 1
    end
    @testset "Classification" begin
        @test begin 
            load_model("models/classification.model")
            make_classes()
            true
        end
        @test begin 
            url_input = "examples\\classification\\test"
            get_urls(url_input)
            true
        end
        @test begin results = prepare_data(); true end
    end

    @testset "Regression" begin
        @test begin 
            load_model("models/regression.model")
            make_classes()
            true
        end
        @test begin 
            url_input = "examples/regression/test"
            url_label = "examples/regression/test.csv"
            get_urls(url_input,url_label)
            true
        end
        @test begin results = prepare_data(); true end
    end

    @testset "Segmentatation" begin
        @test begin 
            load_model("models/segmentation.model")
            make_classes()
            true
        end
        @test begin 
            url_input = "examples/segmentation/images"
            url_label = "examples/segmentation/labels"
            get_urls(url_input,url_label)
            true
        end
        @test begin results = prepare_data(); true end
    end

end

@info "Handling errors"
@testset "Handling errors" begin
    @test begin 
        empty!(model_data.classes)
        prepare_data()
        true 
    end

    @test begin
        model_data.problem_type = :classification
        EasyMLDataPreparation.preparation_data.ClassificationData = EasyMLDataPreparation.ClassificationData()
        prepare_data()
        load_model("models/classification.model")
        url_input = "examples\\classification\\"
        get_urls(url_input)
        push!(EasyMLDataPreparation.unit_test.urls,"examples/classification/test")
        get_urls()
        true
    end

    @test begin
        model_data.problem_type = :regression
        EasyMLDataPreparation.preparation_data.RegressionData = EasyMLDataPreparation.RegressionData()
        prepare_data()
        load_model("models/regression.model")
        url_input = "examples/regression/"
        url_label = "examples/regression/test.csv"
        get_urls(url_input,url_label)
        push!(EasyMLDataPreparation.unit_test.urls, "examples/regression/test","examples/regression/test.csv")
        get_urls()
        true
    end

    @test begin
        model_data.problem_type = :segmentation
        EasyMLDataPreparation.preparation_data.SegmentationData = EasyMLDataPreparation.SegmentationData()
        prepare_data()
        load_model("models/segmentation.model")
        url_input = "examples/segmentation/"
        url_label = "examples/segmentation/labels"
        get_urls(url_input,url_label)
        push!(EasyMLDataPreparation.unit_test.urls, "examples/segmentation/images","examples/segmentation/labels")
        get_urls()
        true
    end

    @test begin
        model_data.problem_type = :classification
        url_input = "examples/"
        get_urls(url_input)
        url_input = "examples2/"
        get_urls(url_input)
        true
    end

    @test begin
        model_data.problem_type = :segmentation
        url_input = "examples/"
        url_label = "examples/"
        get_urls(url_input,url_label)

        url_input = "examples2/"
        url_label = "examples2/"
        get_urls(url_input,url_label)
        get_urls(url_input)
        true
    end

    @test begin
        push!(EasyMLDataPreparation.unit_test.urls, "")
        load_model()
        true
    end
end

#---Other QML----------------------------------------
@testset "Other QML" begin
    @test begin
        EasyMLDataPreparation.set_options(["DataPreparationOptions","Images","num_angles"],1)
        true
    end
    empty!(model_data.input_properties)
    @test begin
        EasyMLDataPreparation.set_model_data("input_properties","grayscale")
        EasyMLDataPreparation.get_model_data("input_properties","grayscale")==true
    end
    @test begin
        EasyMLDataPreparation.rm_model_data("input_properties","grayscale")
        EasyMLDataPreparation.get_model_data("input_properties","grayscale")==false
    end
end