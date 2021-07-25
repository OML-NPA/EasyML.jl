
using EasyML, Test

EasyML.Common.unit_test.state = true


#---Testing modules------------------------------------------

include("common/runtests.jl")
@info "Classes"
include("classes/runtests.jl")
@info "Data preparation"
include("datapreparation/runtests.jl")
@info "Training"
include("training/runtests.jl")
@info "Validation"
include("validation/runtests.jl")
@info "Application"
# include("application/runtests.jl")


#---Testing package------------------------------------------
