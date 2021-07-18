
@info "Classification test"

#---Init test--------------------------------------------------------------

model_data.problem_type = Classification


#---Training test-----------------------------------------------------------
@testset "Input: Vector | Testing: Auto | Weights: Auto | Accuracy: Weight" begin
    @test begin
        EasyMLTraining.training_options.Testing.data_preparation_mode = :Auto
        EasyMLTraining.training_options.Accuracy.accuracy_mode = :Auto
        EasyMLTraining.training_options.Accuracy.weight_accuracy = true

        data_input = map(_ -> rand(Float32,25),1:200)
        data_labels = map(_ -> Int32(rand(1:10)),1:200)
        set_training_data(data_input,data_labels)
        set_testing_data()

        model_data.model = Flux.Chain(Flux.Dense(25, 10))

        train()
        true
    end
end

@testset "Input: Array | Testing: Manual | Weights: Manual | Accuracy: Regular" begin
    @test begin
        EasyMLTraining.training_options.Testing.data_preparation_mode = :Manual
        EasyMLTraining.training_options.Accuracy.accuracy_mode = :Manual
        EasyMLTraining.training_options.Accuracy.weight_accuracy = false

        data_input = map(_ -> rand(Float32,5,5,1),1:200)
        data_labels = map(_ -> Int32(rand(1:10)),1:200)
        set_training_data(data_input,data_labels)

        data_input = map(_ -> rand(Float32,5,5,1),1:20)
        data_labels = map(_ -> Int32(rand(1:10)),1:20)
        set_testing_data(data_input,data_labels)

        set_weights(ones(10))

        model_data.model = Flux.Chain(x->Flux.flatten(x),Flux.Dense(25, 10))

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