struct CollectionView{layer, T, V <: AbstractCollection{layer, T}, I} <: AbstractCollection{layer, T}
    parent::V
    indices::I
end

@inline function Base.view(c::AbstractCollection, I::Vararg{Any})
    @boundscheck checkbounds(c, I...)
    CollectionView(c, I...)
end

Base.parent(c::AbstractCollection) = c.parent
Base.parentindices(c::AbstractCollection) = c.indices

Base.length(c::CollectionView) = length(parentindices(c))
Base.getindex(c::CollectionView, i::Int) = (@_propagate_inbounds_meta; parent(c)[parentindices(c)[i]])
