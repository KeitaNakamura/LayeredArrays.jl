module LayeredCollections

using LinearAlgebra

using Base: @_propagate_inbounds_meta, @_inline_meta, @pure

export
    AbstractCollection,
    Collection

include("AbstractCollection.jl")
include("Collection.jl")
include("CollectionView.jl")
include("RepeatedCollection.jl")
include("AdjointCollection.jl")
include("LazyCollection.jl")
include("broadcast.jl")

end # module
