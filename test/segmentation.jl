
#---Init test--------------------------------------------------------------

set_problem_type(:Segmentation)
set_savepath("models/segmentation.model")


#---Training test-----------------------------------------------------------

function vector_vector(mode::Symbol)
    data_input = map(_ -> rand(Float32,25),1:200)
    data_labels = map(_ -> BitArray{1}(undef,5),1:200)
    set_training_data(data_input,data_labels)
    if mode==:Auto
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
    if mode==:Auto
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
    if mode==:Auto
        set_testing_data()
    else
        data_input = map(_ -> rand(Float32,5,5,1),1:20)
        data_labels = map(_ -> BitArray{3}(undef,5,5,3),1:20)
        set_testing_data(data_input,data_labels)
    end
    return nothing
end

#-Input: Vector | Output: Vector

model_data.model = Flux.Chain(Flux.Dense(25, 5))

vector_vector(:Auto)
training_test()

vector_vector(:Manual)
training_test()


#-Input: Array | Output: Vector | Accuracy: Weight

EasyMLTraining.training_options.Accuracy.weight_accuracy = true

model_data.model = Flux.Chain(x->Flux.flatten(x),Flux.Dense(25, 5))

array_vector(:Auto)
training_test()

array_vector(:Manual)
training_test()


#-Input: Array | Output: Array | Accuracy: Regular

EasyMLTraining.training_options.Accuracy.weight_accuracy = false

model_data.model = Flux.Chain(Flux.Conv((1,1), 1 => 3))

array_array(:Auto)
training_test()

array_array(:Manual)
training_test()


#---Clean up test-----------------------------------------------------------

remove_training_data()
remove_testing_data()
remove_training_results()