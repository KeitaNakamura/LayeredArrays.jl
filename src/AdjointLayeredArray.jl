struct AdjointLayeredArray{layer, T, A <: AbstractLayeredArray{layer, T}} <: AbstractLayeredMatrix{layer, T}
    parent::A
    function AdjointLayeredArray{layer, T, A}(parent::A) where {layer, T, A}
        x = new{layer, T, A}(parent)
        layerof(x) # check layer
        x
    end
end

Base.parent(x::AdjointLayeredArray) = x.parent

Base.adjoint(x::A) where {layer, T, A <: AbstractLayeredArray{layer, T}} = AdjointLayeredArray{layer, T, A}(x)
Base.adjoint(x::AdjointLayeredArray) = parent(x)

Base.size(x::AdjointLayeredArray) = (size(parent(x), 2), size(parent(x), 1))
Base.axes(x::AdjointLayeredArray) = (axes(parent(x), 2), axes(parent(x), 1))

Base.IndexStyle(::Type{<: AdjointLayeredArray{<: Any, <: Any, A}}) where {A} = IndexStyle(A)

# IndexLinear
@inline function Base.getindex(x::AdjointLayeredArray, i::Integer)
    @boundscheck checkbounds(x, i)
    @inbounds parent(x)[i]
end
@inline function Base.setindex!(x::AdjointLayeredArray, v, i::Integer)
    @boundscheck checkbounds(x, i)
    @inbounds parent(x)[i] = v
    x
end

# IndexCartesian
@inline function Base.getindex(x::AdjointLayeredArray, i::Integer, j::Integer)
    @boundscheck checkbounds(x, i, j)
    @inbounds parent(x)[j, i]
end
@inline function Base.setindex!(x::AdjointLayeredArray, v, i::Integer, j::Integer)
    @boundscheck checkbounds(x, i, j)
    @inbounds parent(x)[j, i] = v
    x
end
