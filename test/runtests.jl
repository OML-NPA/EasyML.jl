
using EasyMLCore, Parameters, Flux, QML, Test

EasyMLCore.unit_test.state = true

mutable struct Dummy1<:AbstractEasyML
    a::RefValue{Int64}
    b::Int64
end
dummy1 = Dummy1(Ref(1),1)

mutable struct Dummy2<:AbstractEasyML
    a::RefValue{Int64}
    b::Int64
end
dummy2 = Dummy2(Ref(2),2)

@testset "Accessing fields      " begin
    @test dummy1.a isa Int64
    @test dummy1.b isa Int64
end

@testset "Mutating fields       " begin
    @test begin dummy1.a = 3; true end
    @test begin dummy1.b = 4; true end
end

@testset "Binding               " begin
    bind!(dummy1,dummy2)
    @test dummy1.a === dummy2.a
    @test !(dummy1.b === dummy2.b)
end

@testset "Model loading/saving  " begin
    EasyMLCore.model_data.classes = repeat([EasyMLCore.ImageSegmentationClass()],2)
    mutable struct AllDataUrls<:AbstractEasyML
        model_url::RefValue{String}
        model_name::RefValue{String}
    end
    all_data_urls = AllDataUrls(Ref(""),Ref(""))
    url = "models/test.model"
    @test begin save_model_main(EasyMLCore.model_data,url); true end
    @test begin load_model_main(EasyMLCore.model_data,url,all_data_urls); true end
    @test begin load_model_main(EasyMLCore.model_data,"models/old_test.model",all_data_urls); true end
    rm("models/test.model")
    @test begin 
        try 
            url = "models/test2.model"
            load_model_main(EasyMLCore.model_data,url,all_data_urls) 
        catch e
            e isa ErrorException
        end
    end
    all_data_urls.model_name = ""
    EasyMLCore.unit_test.urls = ["models/test.model"]
    @test begin save_model_main(EasyMLCore.model_data,all_data_urls); true end
    EasyMLCore.unit_test.urls = ["models/test.model"]
    @test begin load_model_main(EasyMLCore.model_data,all_data_urls); true end
    rm("models/test.model")
    @test begin 
        try 
            EasyMLCore.unit_test.urls = ["models/test2.model"]
            load_model_main(EasyMLCore.model_data,all_data_urls)
        catch e
            e isa ErrorException
        end
    end
end

@testset "Options loading/saving" begin
    mutable struct OptionsBusted
        a::Vector{Int64}
        b::Int64
    end
    options_busted = OptionsBusted([1],1)
    mutable struct Options
        a::Bool
        b::Int64
    end
    options = Options(true,1)
    @test begin load_options_main(options); true end
    @test begin save_options_main(options); true end
    @test begin load_options_main(options_busted); true end
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
        @test get_data_main(data,["Data2","a"],[])=="a"
        @test get_data_main(data,["Data2","b"],[1])=="b"
        @test get_data_main(data,["Data2","c"],[1,1])=="c"
    end
    @testset "Set data" begin
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
    end
    @testset "Get file/folder" begin
        @test begin 
            EasyMLCore.unit_test.urls = ["test"]
            out = get_folder()
            out == "test"
        end
        @test begin
            EasyMLCore.unit_test.urls = ["test"]
            out = get_file()
            out == "test"
        end
    end
    @testset "Channels" begin
        struct Channels
            a::Channel
            b::Channel
        end
        channels = Channels(Channel{Int64}(1),Channel{Tuple{Int64,Float64}}(Inf))
        @test begin 
            check_progress_main(channels,"a")
            put!(channels.a,1)
            check_progress_main(channels,"a")
            true
        end
        @test begin 
            get_progress_main(channels,"a")
            get_progress_main(channels,"a")
            put!(channels.b,(1,1.0))
            get_progress_main(channels,"b")
            get_progress_main(channels,"b")
            true
        end
        @test begin 
            put!(channels.a,1)
            empty_channel_main(channels,"a")
            put!(channels.a,1)
            empty_channel_main(channels,:a)
            true
        end
        @test begin 
            put_channel_main(channels,"b",[0.0,1.0])
            true
        end
    end
end

@testset "Other" begin
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
end