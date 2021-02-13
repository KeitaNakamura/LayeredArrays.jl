module LazyCollections

export
    AbstractCollection,
    Collection,
    ←

include("AbstractCollection.jl")
include("Collection.jl")

const ← = set!

end # module
