module LazyCollections

using Base: @_propagate_inbounds_meta, @_inline_meta

export
    AbstractCollection,
    Collection,
    ←,
    lazy

include("utils.jl")
include("AbstractCollection.jl")
include("Collection.jl")
include("LazyCollection.jl")

const ← = set!

end # module
