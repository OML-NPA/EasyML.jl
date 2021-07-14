
#---GUI data handling-----------------------------------------------------

set_options(fields,args) = set_data_main(options,fields,args)

get_options(fields,inds=[]) = get_data_main(options,fields,inds)


#---Handling channels-------------------------------------------------

get_progress(field) = get_progress_main(channels,field)

empty_channel(field) = empty_channel_main(channels,field)


#---Other-------------------------------------------------------------

problem_type() = model_data.problem_type

input_type() = model_data.input_type