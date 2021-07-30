
import EasyML.Common, QML
using EasyML.Common, Parameters, Flux, Test, DelimitedFiles, BSON

cd(@__DIR__)


#---Main functionality-----------------------------------------------------

@testset "Model loading/saving  " begin
    @test begin set_savepath("models/test.model"); true end
    @test begin set_savepath("model"); true end
    model_data.classes = repeat([ImageSegmentationClass()],2)
    url = "models/test.model"
    @test begin save_model(url); true end
    @test begin load_model(url); true end
    @test begin load_model("models/old_test.model"); true end
    @test begin load_model("models/broken_property.model"); true end
    rm("models/test.model")
    @test begin 
        try 
            url = "models/test2.model"
            load_model(url) 
        catch e
            e isa ErrorException
        end
    end
    Common.all_data_urls.model_name = ""
    push!(Common.unit_test.urls,"models/test.model")
    @test begin save_model(); true end
    push!(Common.unit_test.urls,"models/test.model")
    @test begin load_model(); true end
    rm("models/test.model")
    @test begin 
        try 
            push!(Common.unit_test.urls,"models/test2.model")
            load_model()
        catch e
            e isa ErrorException
        end
    end
end

@testset "Options loading/saving" begin
    mutable struct OptionsBusted
        GlobalOptions::Bool
    end
    options_busted = OptionsBusted(true)
    @test begin 
        save_options()
        dict_busted = Dict()
        BSON.@save("options.bson",dict_busted)
        true 
    end
    @test begin 
        load_options()
        load_options() 
        rm("options.bson")
        load_options() 
        rm("options.bson")
        true 
    end
end

@testset verbose = true "QML interaction       "  begin
    mutable struct Data2
        a::Symbol
        b::Vector{Symbol}
        c::Vector{Vector{Symbol}}
    end
    mutable struct Data
        Data2::Data2
    end
    data = Data(Data2(:a,[:b],[[:c]]))
    @testset "Type conversion" begin
        propmap = QML.QQmlPropertyMap()
        propmap["string"] = "some string"
        propmap["integer"] = zero(Int64)
        propmap["float"] = zero(Float64)
        propmap["list"] = [1,2,3,4]
        @test fix_QML_types(propmap["string"])=="some string"
        @test fix_QML_types(propmap["integer"])==zero(Int64)
        @test fix_QML_types(propmap["float"])==zero(Float64)
        @test fix_QML_types(propmap["list"])==[1,2,3,4]
        @test fix_QML_types((1,2))==(1,2)
    end
    @testset "Get data" begin
        import EasyML.Common.get_data_main
        @test get_data_main(data,["Data2","a"],[])=="a"
        @test get_data_main(data,["Data2","b"],[1])=="b"
        @test get_data_main(data,["Data2","c"],[1,1])=="c"
        @test get_data(["TrainingData","warnings"])==String[]
        @test get_options(["GlobalOptions","Graphics","scaling_factor"])==1.0
        @test get_options(["ApplicationOptions","image_type"])=="png"
    end
    @testset "Set data" begin
        import EasyML.Common.set_data_main
        @test begin 
            set_data_main(data,["Data2","a"],("c"))
            data.Data2.a == :c
        end
        @test begin 
            set_data_main(data,["Data2","b"],([1],"d"))
            data.Data2.b[1] == :d
        end
        @test begin 
            set_data_main(data,["Data2","c"],([1,1],"e"))
            data.Data2.c[1][1] == :e
        end
        @test begin 
            set_data(["TrainingData","warnings"],[])
            true
        end
        @test begin 
            set_options(["GlobalOptions","Graphics","scaling_factor"],1.0)
            true
        end
        @test begin 
            set_options(["ApplicationOptions","image_type"],"PNG")
            true
        end
    end
    @testset "Get file/folder" begin
        @test begin 
            push!(Common.unit_test.urls,"test")
            out = get_folder()
            out == "test"
        end
        @test begin
            push!(Common.unit_test.urls,"test")
            out = get_file()
            out == "test"
        end
    end
    @testset "Channels" begin
        struct Channels
            a::Channel
            b::Channel
        end
        channels = Channels(Channel{Int64}(1),Channel{Tuple{Int64,Float64}}(1))
        @test begin 
            import EasyML.Common.check_progress_main
            check_progress_main(channels,"a")
            put!(channels.a,1)
            check_progress_main(channels,"a")
            check_progress("data_preparation_progress")
            true
        end
        @test begin 
            import EasyML.Common.get_progress_main
            get_progress_main(channels,"a")
            get_progress_main(channels,"a")
            put!(channels.b,(1,1.0))
            get_progress_main(channels,"b")
            get_progress_main(channels,"b")
            put!(channels.a,1)
            get_progress_main(channels,:a)
            get_progress_main(channels,:a)
            put!(channels.b,(1,1.0))
            get_progress_main(channels,:b)
            get_progress_main(channels,:b)
            get_progress(:data_preparation_progress)
            true
        end
        @test begin 
            import EasyML.Common.empty_channel_main
            put!(channels.a,1)
            empty_channel_main(channels,"a")
            put!(channels.a,1)
            empty_channel_main(channels,:a)
            empty_channel(:data_preparation_progress)
            true
        end
        @test begin 
            import EasyML.Common.put_channel_main
            put_channel_main(channels,"b",[0.0,1.0])
            put_channel("data_preparation_progress",1)
            true
        end
    end
end

@testset "Set property" begin
    @test begin
        obj = Common.Application.OutputVolume()
        obj.binning = :auto
        obj.normalization = :none
        true
    end
    @test begin
        obj = Common.application_options
        obj.apply_by = :file
        obj.data_type= :csv
        obj.image_type = :png
        true
    end
    @test begin
        try
            obj = Common.application_options
            obj.apply_by = :esgsg
        catch
            true
        end
    end
end

@testset "Other                 " begin
    @test begin
        f1() = true
        t1 = Task(f1)
        check_task(t1)
        schedule(t1)
        sleep(2)
        check_task(t1)
        f2() = 1/[]
        t2 = Task(f2)
        schedule(t2)
        sleep(2)
        check_task(t2)
        true
    end
    @test begin
        writedlm("test.qml", ["","import", "import", "import","",""])
        url = "test.qml" 
        Common.add_templates(url)
        Common.add_templates(url)
        rm("test.qml")
        true
    end
    @test begin problem_type(); true end
    @test begin input_type(); true end
    @test begin
        change(global_options)
        rm("options.bson")
        true
    end
    @test begin
        Common.max_num_threads()
        Common.num_threads()
        true
    end
    @test begin model_data.normalization.f([]); true end
end