"""
    Collection(x, [Val(layer)])
"""
struct Collection{layer, T, V <: Union{AbstractVector{T}, AbstractCollection{<: Any, T}}} <: AbstractCollection{layer, T}
    parent::V
end

# constructors
Collection{layer}(v::V) where {layer, T, V <: Union{AbstractVector{T}, AbstractCollection{<: Any, T}}} = Collection{layer, T, V}(v)
Collection(v) = Collection{1}(v)

Base.parent(c::Collection) = c.parent

# needs to be implemented for AbstractCollection
Base.length(c::Collection) = length(parent(c))
@inline function Base.getindex(c::Collection, i::Integer)
    @boundscheck checkbounds(c, i)
    @inbounds parent(c)[i]
end
@inline function Base.setindex!(c::Collection, v, i::Integer)
    @boundscheck checkbounds(c, i)
    @inbounds parent(c)[i] = v
    c
end
