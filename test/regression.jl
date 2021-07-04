
#---Init test--------------------------------------------------------------

set_problem_type(:Regression)
set_savepath("models/regression.model")


#---Training test-----------------------------------------------------------

function vector_vector(mode::Symbol)
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

#-Input: Vector | Output: Vector

model_data.model = Flux.Chain(Flux.Dense(25, 5))

vector_vector(:Auto)
training_test()

vector_vector(:Manual)
training_test()


#-Input: Array | Output: Vector

model_data.model = Flux.Chain(x->Flux.flatten(x),Flux.Dense(25, 5))

array_vector(:Auto)
training_test()

array_vector(:Manual)
training_test()


#-Input: Array | Output: Array | GPU: true

global_options.HardwareResources.allow_GPU = true

model_data.model = Flux.Chain(Flux.Conv((1,1), 1 => 1))

array_array(:Auto)
training_test()

array_array(:Manual)
training_test()


#---Clean up test-----------------------------------------------------------

remove_training_data()
remove_testing_data()
remove_training_results()