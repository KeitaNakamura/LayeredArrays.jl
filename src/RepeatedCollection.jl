struct RepeatedCollection{layer, T, V <: AbstractCollection{layer, T}} <: AbstractCollection{layer, T}
    parent::V
    inner::Int
    outer::Int
end

function Base.repeat(x::AbstractCollection; inner::Int = 1, outer::Int = 1)
    RepeatedCollection(x, inner, outer)
end
Base.repeat(x::AbstractCollection, outer::Int) = repeat(x; outer)

Base.parent(x::RepeatedCollection) = x.parent

function Base.length(x::RepeatedCollection)
    len = length(parent(x))
    len * x.inner * x.outer
end

function Base.getindex(x::RepeatedCollection, i::Int)
    @boundscheck checkbounds(x, i)
    inner_length = x.inner * length(parent(x))
    j = x.outer == 1 ? i : rem(i-1, inner_length) + 1
    k = x.inner == 1 ? j : div(j-1, x.inner) + 1
    @inbounds parent(x)[k]
end
