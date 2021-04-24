module LayeredArrays

using LinearAlgebra

using Base: @_propagate_inbounds_meta, @_inline_meta, @pure

export
    AbstractLayeredArray,
    AbstractLayeredMatrix,
    AbstractLayeredVector,
    LayeredArray,
    LayeredMatrix,
    LayeredVector

include("AbstractLayeredArray.jl")
include("LayeredArray.jl")
include("broadcast.jl")
include("LazyLayeredArray.jl")

end # module
