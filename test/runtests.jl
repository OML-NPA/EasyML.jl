
using EasyMLTraining

function training_test()
    empty!(EasyMLTraining.training_data.tasks)
    EasyMLTraining.empty_progress_channel("training_start_progress")
    EasyMLTraining.empty_progress_channel("training_progress")
    EasyMLTraining.empty_progress_channel("training_modifiers")
    
    EasyMLTraining.train_main2(model_data,EasyMLTraining.all_data,EasyMLTraining.options,EasyMLTraining.channels)

    while true
        if length(EasyMLTraining.training_data.tasks)==2
            break
        elseif length(EasyMLTraining.training_data.tasks)==1
            t = EasyMLTraining.training_data.tasks[1]
            state,err = EasyMLTraining.check_task(t)
            if state==:error
                @error string("Training aborted due to the following error: ",err)
                return
            else
                sleep(0.1)
            end
        else
            sleep(0.1)
        end
    end

    while true
        done_accum = [false,false]
        for i = 1:2
            t = EasyMLTraining.training_data.tasks[i]
            state,err = EasyMLTraining.check_task(t)
            if state==:done
                done_accum[i] = true
            elseif state==:error
                @error string("Training aborted due to the following error: ",err)
                return
            end
        end
        if all(done_accum)
            empty!(EasyMLTraining.training_data.tasks)
            return
        end
        sleep(0.1)
    end
end

training_options.Testing.test_data_fraction = 0.1

#---CPU

global_options.HardwareResources.allow_GPU = false

include("classification.jl")
include("regression.jl")
include("segmentation.jl")

#---GPU

global_options.HardwareResources.allow_GPU = true

include("classification.jl")
include("regression.jl")
include("segmentation.jl")

#---Other

load_options()
load_model("models/classification.model")