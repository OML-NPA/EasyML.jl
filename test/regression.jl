
@info "Regression test"

#---Init test--------------------------------------------------------------

model_data.problem_type = Regression
set_savepath("models/regression.model")


#---Training test-----------------------------------------------------------

function vector_vector(mode::Symbol)
    EasyMLTraining.training_options.Testing.data_preparation_mode = mode
    data_input = map(_ -> rand(Float32,25),1:200)
    data_labels = map(_ -> rand(Float32,5),1:200)
    set_training_data(data_input,data_labels)
    if mode==:Auto
        set_testing_data()
    else
        data_input = map(_ -> rand(Float32,25),1:20)
        data_labels = map(_ -> rand(Float32,5),1:20)
        set_testing_data(data_input,data_labels)
    end
    return nothing
end

function array_vector(mode::Symbol)
    data_input = map(_ -> rand(Float32,5,5,1),1:200)
    data_labels = map(_ -> rand(Float32,5),1:200)
    set_training_data(data_input,data_labels)
    if mode==:Auto
        set_testing_data()
    else
        data_input = map(_ -> rand(Float32,5,5,1),1:20)
        data_labels = map(_ -> rand(Float32,5),1:20)
        set_testing_data(data_input,data_labels)
    end
    return nothing
end

function array_array(mode::Symbol)
    data_input = map(_ -> rand(Float32,5,5,1),1:1000)
    data_labels = map(_ -> rand(Float32,5,5,1),1:1000)
    set_training_data(data_input,data_labels)
    if mode==:Auto
        set_testing_data()
    else
        data_input = map(_ -> rand(Float32,5,5,1),1:10)
        data_labels = map(_ -> rand(Float32,5,5,1),1:10)
        set_testing_data(data_input,data_labels)
    end
    return nothing
end


EasyMLTraining.training_options.Accuracy.weight_accuracy = false
EasyMLTraining.training_options.Accuracy.accuracy_mode = :Auto

@testset "Input: Vector | Output: Vector" begin
    model_data.model = Flux.Chain(Flux.Dense(25, 5))
    @test begin 
        vector_vector(:Auto)
        train()
        true
    end
    @test begin 
        vector_vector(:Manual)
        train()
        true
    end
end


@testset "Input: Array | Output: Vector" begin
    model_data.model = Flux.Chain(x->Flux.flatten(x),Flux.Dense(25, 5))
    @test begin 
        array_vector(:Auto)
        train()
        true
    end
    @test begin
        array_vector(:Manual)
        train()
        true
    end
end


@testset "Input: Array | Output: Array" begin
    model_data.model = Flux.Chain(Flux.Conv((1,1), 1 => 1))
    @test begin 
        array_array(:Auto)
        train()
        true
    end
    @test begin
        array_array(:Manual)
        train()
        true
    end
end


#---Clean up test-----------------------------------------------------------
@testset "Clean up" begin
    @test begin
        remove_training_data()
        remove_testing_data()
        remove_training_results()
        true
    end
end