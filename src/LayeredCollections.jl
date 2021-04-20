module LayeredCollections

using LinearAlgebra

using Base: @_propagate_inbounds_meta, @_inline_meta, @pure

export
# AbstractCollection
    AbstractCollection,
# Collection
    Collection,
# LazyCollection
    LazyCollection,
    LazyOperationType,
    LazyAddLikeOperator,
    LazyMulLikeOperator,
    lazy

include("utils.jl")
include("AbstractCollection.jl")
include("Collection.jl")
include("AdjointCollection.jl")
include("LazyCollection.jl")
include("broadcast.jl")

end # module
