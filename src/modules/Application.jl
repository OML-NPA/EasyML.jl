
module Application

using Parameters


#---Data----------------------------------------------------------------

@with_kw mutable struct ApplicationData
    input_urls::Vector{Vector{String}} = Vector{Vector{String}}(undef,0)
    folders::Vector{String} = Vector{String}(undef,0)
    url_inputs::String = ""
    tasks::Vector{Task} = Vector{Task}(undef,0)
end
application_data = ApplicationData()


#---Options----------------------------------------------------------------

@with_kw mutable struct ApplicationOptions
    savepath::String = ""
    apply_by::Symbol = :file
    data_type::Symbol = :CSV
    image_type::Symbol = :PNG
    scaling::Float64 = 1
end
application_options = ApplicationOptions()


#---Export all--------------------------------------------------------------

for n in names(@__MODULE__; all=true)
    if Base.isidentifier(n) && n ∉ (Symbol(@__MODULE__), :eval, :include)
        @eval export $n
    end
end

end