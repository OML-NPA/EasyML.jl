
#---GUI data handling-----------------------------------------------------

set_data(fields,args...) = set_data_main(all_data,fields,args)

get_data(fields,inds=[]) = get_data_main(all_data,fields,inds)

set_options(fields,args...) = set_data_main(options,fields,args)

get_options(fields,inds=[]) = get_data_main(options,fields,inds)

#---Other-------------------------------------------------------------

problem_type() = model_data.problem_type

input_type() = model_data.input_type