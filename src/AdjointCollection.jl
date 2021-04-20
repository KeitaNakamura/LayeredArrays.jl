struct AdjointCollection{layer, T, V <: AbstractCollection{layer, T}} <: AbstractCollection{layer, T}
    parent::V
end
Base.parent(c::AdjointCollection) = c.parent
LinearAlgebra.adjoint(c::AdjointCollection) = parent(c)
function LinearAlgebra.adjoint(c::AbstractCollection)
    ndims(c) == 1 || throw(ArgumentError("adjoint N>1 collections not supported."))
    AdjointCollection(c)
end

# getindex
Base.length(c::AdjointCollection) = length(parent(c))
Base.size(c::AdjointCollection) = (1, length(c))
@inline function Base.getindex(c::AdjointCollection, i::Int)
    @boundscheck checkbounds(c, i)
    @inbounds parent(c)[i]
end
