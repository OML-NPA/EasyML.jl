
#---GUI data handling-----------------------------------------------------

set_options(fields,args) = set_options_main(options,fields,args)

get_options(fields,inds=[]) = get_options_main(options,fields,inds)

#---Other-------------------------------------------------------------

problem_type() = model_data.problem_type

input_type() = model_data.input_type