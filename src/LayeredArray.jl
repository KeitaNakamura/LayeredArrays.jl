"""
    LayeredArray(x)
    LayeredArray{layer}(x)
"""
struct LayeredArray{layer, T, N, A <: AbstractArray{T, N}} <: AbstractLayeredArray{layer, T, N}
    parent::A
end

const LayeredVector{layer, T, A <: AbstractVector{T}} = LayeredArray{layer, T, 1, A}
const LayeredMatrix{layer, T, A <: AbstractMatrix{T}} = LayeredArray{layer, T, 2, A}

# constructors
LayeredArray{layer}(x::A) where {layer, T, N, A <: AbstractArray{T, N}} = LayeredArray{layer, T, N, A}(x)
LayeredArray(v) = LayeredArray{1}(v)

Base.parent(x::LayeredArray) = x.parent

Base.size(x::LayeredArray) = size(parent(x))
Base.axes(x::LayeredArray) = axes(parent(x))

@inline function Base.getindex(x::LayeredArray, i::Integer...)
    @boundscheck checkbounds(x, i...)
    @inbounds parent(x)[i...]
end
@inline function Base.setindex!(x::LayeredArray, v, i::Integer...)
    @boundscheck checkbounds(x, i...)
    @inbounds parent(x)[i...] = v
    x
end

macro layered(layer::Int, ex)
    esc(:(LayeredArray{$layer}($ex)))
end
macro layered(ex)
    esc(:(LayeredArray($ex)))
end
