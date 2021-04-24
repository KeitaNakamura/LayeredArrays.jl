"""
    AbstractLayeredArray{layer, T, N}
"""
abstract type AbstractLayeredArray{layer, T, N} <: AbstractArray{T, N} end

const AbstractLayeredVector{layer, T} = AbstractLayeredArray{layer, T, 1}
const AbstractLayeredMatrix{layer, T} = AbstractLayeredArray{layer, T, 2}

whichlayer(::AbstractLayeredArray{layer}) where {layer} = layer
whichlayer(::Adjoint{<: Any, <: AbstractLayeredArray{layer}}) where {layer} = layer
whichlayer(::Type{<: AbstractLayeredArray{layer}}) where {layer} = layer
whichlayer(::Type{<: Adjoint{<: Any, <: AbstractLayeredArray{layer}}}) where {layer} = layer
whichlayer(::Any) = -100 # just use low value

# getindex for slice
# cannot overload `getindex` since `getindex(A::AbstractLayeredArray, i::Int...)` also calls it.
# so following unexported `_getindex` is overloaded
@inline function Base._getindex(::IndexCartesian, x::AbstractLayeredArray{layer}, i::Union{Real, AbstractArray}...) where {layer}
    @boundscheck checkbounds(x, i...)
    @inbounds LayeredArray{layer}(view(x, i...))
end
# following function fixes ambiguity
@inline function Base._getindex(::IndexCartesian, A::AbstractLayeredArray, I::Int...)
    @boundscheck checkbounds(A, I...) # generally _to_subscript_indices requires bounds checking
    @inbounds r = getindex(A, Base._to_subscript_indices(A, I...)...)
    r
end

function set!(dest::Union{AbstractVector, AbstractLayeredArray{layer}}, src::AbstractLayeredArray{layer}) where {layer}
    @simd for i in eachindex(dest, src)
        @inbounds dest[i] = src[i]
    end
    dest
end
