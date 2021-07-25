
@info "Segmentation test"

#---Init test--------------------------------------------------------------

model_data.problem_type = :segmentation


#---Training test-----------------------------------------------------------

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

@testset "Input: Array | Output: Array" begin
    Training.training_options.Accuracy.weight_accuracy = false
    Training.training_options.Accuracy.accuracy_mode = :auto
    model_data.model = Flux.Chain(Flux.Conv((1,1), 1 => 3))
    @test begin
        array_array(:auto)
        train()
        true
    end
    Training.training_options.Accuracy.weight_accuracy = true
    Training.training_options.Accuracy.accuracy_mode = :manual
    set_weights(ones(3))
    @test begin
        array_array(:manual)
        train()
        true
    end
end

rm("models/segmentation.model")


#---Clean up test-----------------------------------------------------------

@testset "Clean up" begin
    @test begin
        remove_training_data()
        remove_testing_data()
        remove_training_results()
        true
    end
end