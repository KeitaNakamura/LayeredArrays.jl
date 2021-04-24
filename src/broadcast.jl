using Base.Broadcast: AbstractArrayStyle, Broadcasted

struct LayeredArrayStyle{N} <: AbstractArrayStyle{N} end
(::Type{<: LayeredArrayStyle})(::Val{N}) where {N} = LayeredArrayStyle{N}()

Broadcast.BroadcastStyle(::Type{<: AbstractLayeredArray{<: Any, <: Any, N}}) where {N} = LayeredArrayStyle{N}()

Broadcast.broadcastable(x::AbstractLayeredArray) = x
Broadcast.broadcastable(x::Broadcasted{LayeredArrayStyle{N}}) where {N} = copy(x)
Broadcast.instantiate(x::Broadcasted{LayeredArrayStyle{N}}) where {N} = x

function Base.copy(bc::Broadcasted{LayeredArrayStyle{N}}) where {N}
    LazyLayeredArray(bc.f, bc.args...)
end

function Base.copyto!(dest::Union{AbstractVector, AbstractLayeredArray}, src::Broadcasted{LayeredArrayStyle{N}}) where {N}
    set!(dest, copy(src))
end
