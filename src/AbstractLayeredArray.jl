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

# getindex
@inline function Base.getindex(x::AbstractLayeredArray{layer}, i::Union{Real, AbstractArray}...) where {layer}
    @boundscheck checkbounds(x, i...)
    @inbounds LayeredArray{layer}(view(x, i...))
end

function set!(dest::Union{AbstractVector, AbstractLayeredArray{layer}}, src::AbstractLayeredArray{layer}) where {layer}
    @simd for i in eachindex(dest, src)
        @inbounds dest[i] = src[i]
    end
    dest
end

short_type_name(x) = short_type_name(typeof(x))
short_type_name(x::Type) = x
function Base.summary(io::IO, x::AbstractLayeredArray)
    print(io, Base.dims2string(size(x)), " ", "<layer=", whichlayer(x), "> ", short_type_name(x))
end
