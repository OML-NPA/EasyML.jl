
#---GUI data handling-------------------------------------------------

set_data(fields,args...) = set_data_main(all_data,fields,args)

get_data(fields,inds=[]) = get_data_main(all_data,fields,inds)

set_options(fields,args...) = set_data_main(options,fields,args)

get_options(fields,inds=[]) = get_data_main(options,fields,inds)


#---Handling channels-------------------------------------------------

# Return a value from progress channels without taking the value
check_progress(field) = check_progress_main(channels,field)

# Return a value from progress channels by taking the value
get_progress(field) = get_progress_main(channels,field)

empty_progress_channel(field) = empty_progress_channel_main(channels,field)

put_channel(field,value) = put_channel_main(channels,field,value)


#---Other-------------------------------------------------------------

problem_type() = model_data.problem_type

input_type() = model_data.input_type