module LayeredCollections

using LinearAlgebra

using Base: @_propagate_inbounds_meta, @_inline_meta, @pure

export
    AbstractCollection,
    Collection,
    LazyCollection

include("AbstractCollection.jl")
include("Collection.jl")
include("RepeatedCollection.jl")
include("AdjointCollection.jl")
include("LazyCollection.jl")
include("broadcast.jl")

end # module
