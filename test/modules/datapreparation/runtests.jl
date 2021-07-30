
using EasyML.DataPreparation
import EasyML.DataPreparation

cd(@__DIR__)


#---Main functionality----------------------------------------------------

@testset "Opening options" begin
    @test begin change(data_preparation_options); true end
    rm("options.bson")
end

for i = 1:2

    if i==1
        model_data.input_properties = [:grayscale]
        DataPreparation.image_preparation_options.mirroring = true
        DataPreparation.image_preparation_options.num_angles = 2
    else
        model_data.input_properties = Symbol[]
        DataPreparation.image_preparation_options.mirroring = false
        DataPreparation.image_preparation_options.num_angles = 1
    end
    @testset "Classification" begin
        @test begin 
            load_model(joinpath(models_dir,"classification.model"))
            change_classes()
            true
        end
        @test begin 
            url_input = joinpath(examples_dir,"classification/test")
            get_urls(url_input)
            true
        end
        @test begin results = prepare_data(); true end
    end

    @testset "Regression" begin
        @test begin 
            load_model(joinpath(models_dir,"regression.model"))
            change_classes()
            true
        end
        @test begin 
            url_input = joinpath(examples_dir,"regression/test")
            url_label = joinpath(examples_dir,"regression/test.csv")
            get_urls(url_input,url_label)
            true
        end
        @test begin results = prepare_data(); true end
    end

    @testset "Segmentatation" begin
        @test begin 
            load_model(joinpath(models_dir,"segmentation.model"))
            change_classes()
            true
        end
        @test begin 
            url_input = joinpath(examples_dir,"segmentation/images")
            url_label = joinpath(examples_dir,"segmentation/labels")
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
        DataPreparation.preparation_data.ClassificationData = DataPreparation.ClassificationData()
        prepare_data()
        load_model(joinpath(models_dir,"classification.model"))
        url_input = string(examples_dir,"\\classification\\")
        get_urls(url_input)
        push!(DataPreparation.unit_test.urls,string(examples_dir,"/classification/test"))
        get_urls()
        true
    end

    @test begin
        model_data.problem_type = :regression
        DataPreparation.preparation_data.RegressionData = DataPreparation.RegressionData()
        prepare_data()
        load_model(joinpath(models_dir,"regression.model"))
        url_input = joinpath(examples_dir,"regression/")
        url_label = joinpath(examples_dir,"regression/test.csv")
        get_urls(url_input,url_label)
        push!(DataPreparation.unit_test.urls, joinpath(examples_dir,"regression/test"),joinpath(examples_dir,"regression/test.csv"))
        get_urls()
        true
    end

    @test begin
        model_data.problem_type = :segmentation
        DataPreparation.preparation_data.SegmentationData = DataPreparation.SegmentationData()
        prepare_data()
        load_model(joinpath(models_dir,"segmentation.model"))
        url_input = joinpath(examples_dir,"segmentation/")
        url_label = joinpath(examples_dir,"segmentation/labels")
        get_urls(url_input,url_label)
        push!(DataPreparation.unit_test.urls, joinpath(examples_dir,"segmentation/images"),joinpath(examples_dir,"segmentation/labels"))
        get_urls()
        true
    end

    @test begin
        model_data.problem_type = :classification
        url_input = string(examples_dir,"/")
        get_urls(url_input)
        url_input = "examples2/"
        get_urls(url_input)
        true
    end

    @test begin
        model_data.problem_type = :segmentation
        url_input = string(examples_dir,"/")
        url_label = string(examples_dir,"/")
        get_urls(url_input,url_label)

        url_input = "examples2/"
        url_label = "examples2/"
        get_urls(url_input,url_label)
        get_urls(url_input)
        true
    end

    @test begin
        push!(DataPreparation.unit_test.urls, "")
        load_model()
        true
    end
end


#---Other QML----------------------------------------

@testset "Other QML" begin
    @test begin
        DataPreparation.set_options(["DataPreparationOptions","Images","num_angles"],1)
        true
    end
    empty!(model_data.input_properties)
    @test begin
        DataPreparation.set_model_data("input_properties","grayscale")
        DataPreparation.get_model_data("input_properties","grayscale")==true
    end
    @test begin
        DataPreparation.rm_model_data("input_properties","grayscale")
        DataPreparation.get_model_data("input_properties","grayscale")==false
    end
end