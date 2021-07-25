
@info "Segmentation test"

#---Init test--------------------------------------------------------------

model_data.problem_type = :segmentation


#---Training test-----------------------------------------------------------

function vector_vector(mode::Symbol)
    EasyMLTraining.training_options.Testing.data_preparation_mode = mode
    data_input = map(_ -> rand(Float32,25),1:200)
    data_labels = map(_ -> BitArray{1}(undef,5),1:200)
    set_training_data(data_input,data_labels)
    if mode==:auto
        set_testing_data()
    else
        data_input = map(_ -> rand(Float32,25),1:20)
        data_labels = map(_ -> BitArray{1}(undef,5),1:20)
        set_testing_data(data_input,data_labels)
    end
    return nothing
end

function array_vector(mode::Symbol)
    data_input = map(_ -> rand(Float32,5,5,1),1:200)
    data_labels = map(_ -> BitArray{1}(undef,5),1:200)
    set_training_data(data_input,data_labels)
    if mode==:auto
        set_testing_data()
    else
        data_input = map(_ -> rand(Float32,5,5,1),1:20)
        data_labels = map(_ -> BitArray{1}(undef,5),1:20)
        set_testing_data(data_input,data_labels)
    end
    return nothing
end

function array_array(mode::Symbol)
    data_input = map(_ -> rand(Float32,5,5,1),1:200)
    data_labels = map(_ -> BitArray{3}(undef,5,5,3),1:200)
    set_training_data(data_input,data_labels)
    if mode==:auto
        set_testing_data()
    else
        data_input = map(_ -> rand(Float32,5,5,1),1:20)
        data_labels = map(_ -> BitArray{3}(undef,5,5,3),1:20)
        set_testing_data(data_input,data_labels)
    end
    return nothing
end

@testset "Input: Vector | Output: Vector" begin
    model_data.model = Flux.Chain(Flux.Dense(25, 5))
    @test begin
        vector_vector(:auto)
        train()
        true
    end
    @test begin
        vector_vector(:manual)
        train()
        true
    end
end

@testset "Input: Array | Output: Vector | Accuracy: Weight" begin
    EasyMLTraining.training_options.Accuracy.weight_accuracy = true
    model_data.model = Flux.Chain(x->Flux.flatten(x),Flux.Dense(25, 5))
    @test begin
        array_vector(:auto)
        train()
        true
    end
    @test begin
        array_vector(:manual)
        train()
        true
    end
end

@testset "Input: Array | Output: Vector | Accuracy: Weight | Accuracy mode: Manual" begin
    EasyMLTraining.training_options.Accuracy.weight_accuracy = true
    EasyMLTraining.training_options.Accuracy.accuracy_mode = :manual
    model_data.model = Flux.Chain(x->Flux.flatten(x),Flux.Dense(25, 5))
    @test begin
        array_vector(:auto) # Fail
        train()
        true
    end
    @test begin
        set_weights([1,1,1,1,1])
        array_vector(:auto)
        train()
        true
    end
    @test begin
        array_vector(:manual)
        train()
        true
    end
end

@testset "Input: Array | Output: Array | Accuracy: Regular" begin
    EasyMLTraining.training_options.Accuracy.weight_accuracy = false
    EasyMLTraining.training_options.Accuracy.accuracy_mode = :auto
    model_data.model = Flux.Chain(Flux.Conv((1,1), 1 => 3))
    @test begin
        array_array(:auto)
        train()
        true
    end
    @test begin
        array_array(:manual)
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