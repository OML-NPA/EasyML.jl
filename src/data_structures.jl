
#---Model data----------------------------------------------------------------------

@with_kw mutable struct ModelData<:AbstractEasyML
    problem_type = EasyMLCore.model_data.problem_type
    input_type = EasyMLCore.model_data.input_type
    classes = EasyMLCore.model_data.classes
end
model_data = ModelData()


#---All data------------------------------------------------------------------

@with_kw mutable struct AllDataUrls<:AbstractEasyML
    model_url::RefValue{String} = Ref("")
    model_name::RefValue{String} = Ref("")
end
all_data_urls = AllDataUrls()

@with_kw struct AllData<:AbstractEasyML
    Urls::AllDataUrls = all_data_urls
end
all_data = AllData()


#---Options-------------------------------------------------------------------

@with_kw mutable struct Graphics<:AbstractEasyML
    scaling_factor::RefValue{Float64} = Ref(1.0)
end
graphics = Graphics()

@with_kw struct GlobalOptions
    Graphics::Graphics = graphics
end
global_options = GlobalOptions()

@with_kw struct Options
    GlobalOptions::GlobalOptions = global_options
end
options = Options()


#---Testing-------------------------------------------------------------------

@with_kw mutable struct UnitTest<:AbstractEasyML
    state::RefValue{Bool} = Ref(false)
    urls::RefValue{Vector{String}} = Ref(String[])
    url_pusher = () -> popfirst!(urls[])
end
unit_test = UnitTest()
(m::UnitTest)() = m.state

