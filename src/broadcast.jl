import Base.Broadcast:
    AbstractArrayStyle,
    BroadcastStyle,
    Broadcasted,
    broadcasted,
    broadcastable,
    instantiate,
    newindex

struct LayeredArrayStyle{N} <: Broadcast.AbstractArrayStyle{N} end
(::Type{<: LayeredArrayStyle})(::Val{N}) where {N} = LayeredArrayStyle{N}()

BroadcastStyle(::Type{<: AbstractLayeredArray{<: Any, <: Any, N}}) where {N} = LayeredArrayStyle{N}()

broadcastable(x::AbstractLayeredArray) = x
broadcastable(x::Broadcasted{LayeredArrayStyle{N}}) where {N} = copy(x)
instantiate(x::Broadcasted{LayeredArrayStyle{N}}) where {N} = x

function Base.copy(bc::Broadcasted{LayeredArrayStyle{N}}) where {N}
    LazyLayeredArray(bc.f, bc.args...)
end

function Base.copyto!(dest::Union{AbstractVector, AbstractLayeredArray}, src::Broadcasted{LayeredArrayStyle{N}}) where {N}
    set!(dest, copy(src))
end
