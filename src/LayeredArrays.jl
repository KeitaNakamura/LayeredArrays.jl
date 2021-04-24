module LayeredArrays

using LinearAlgebra

using Base: @_propagate_inbounds_meta, @_inline_meta, @pure

export
    AbstractLayeredArray,
    LayeredArray

include("AbstractLayeredArray.jl")
include("LayeredArray.jl")
include("broadcast.jl")
include("LazyLayeredArray.jl")

end # module
