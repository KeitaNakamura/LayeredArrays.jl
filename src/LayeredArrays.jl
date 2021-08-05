module LayeredArrays

using LinearAlgebra

using Base: @_propagate_inbounds_meta, @_inline_meta, @propagate_inbounds

export
# AbstractLayeredArray
    AbstractLayeredArray,
    AbstractLayeredMatrix,
    AbstractLayeredVector,
    layerof,
# LayeredArray
    LayeredArray,
    LayeredMatrix,
    LayeredVector,
# LazyLayeredArray
    LazyLayeredArray,
    LazyLayeredMatrix,
    LazyLayeredVector,
# macro
    @layered

include("helpers.jl")
include("AbstractLayeredArray.jl")
include("LayeredArray.jl")
include("AdjointLayeredArray.jl")
include("broadcast.jl")
include("LazyLayeredArray.jl")

end # module
