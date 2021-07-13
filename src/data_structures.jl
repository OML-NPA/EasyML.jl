
#---Model data-------------------------------------------------------------

@with_kw mutable struct ModelData<:AbstractEasyML
    model = EasyMLCore.model_data.model
    loss = EasyMLCore.model_data.loss
    input_size = EasyMLCore.model_data.input_size
    output_size = EasyMLCore.model_data.output_size
    problem_type = EasyMLCore.model_data.problem_type
    input_type = EasyMLCore.model_data.input_type
    layers_info = EasyMLCore.model_data.layers_info
end
model_data = ModelData()

#---Master data
@with_kw mutable struct DesignData
    ModelData::ModelData = ModelData()
    warnings::Vector{String} = Vector{String}(undef,0)
end
design_data = DesignData()

@with_kw mutable struct AllDataUrls<:AbstractEasyML
    model_url::RefValue{String} = Ref("")
    model_name::RefValue{String} = Ref("")
end
all_data_urls = AllDataUrls()

@with_kw mutable struct AllData
    DesignData::DesignData = design_data
    Urls::AllDataUrls = all_data_urls
end
all_data = AllData()


#---Options-----------------------------------------------------------------

@with_kw mutable struct Graphics<:AbstractEasyML
    scaling_factor::RefValue{Float64} = Ref(1.0)
end
graphics = Graphics()

@with_kw struct GlobalOptions
    Graphics::Graphics = graphics
end
global_options = GlobalOptions()

# Design
@with_kw mutable struct DesignOptions
    width::Float64 = 340
    height::Float64 = 100
    min_dist_x::Float64 = 80
    min_dist_y::Float64 = 40
end
design_options = DesignOptions()


@with_kw struct Options
    GlobalOptions::GlobalOptions = global_options
    DesignOptions::DesignOptions = design_options
end
options = Options()


#---Testing----------------------------------------------------------------

@with_kw mutable struct UnitTest<:AbstractEasyML
    state = Ref(false)
    urls = Ref(String[])
    url_pusher = Ref{Function}(() -> popfirst!(urls[]))
end
unit_test = UnitTest()
(m::UnitTest)() = m.state