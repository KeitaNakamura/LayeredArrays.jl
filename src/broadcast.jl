import Base.Broadcast: BroadcastStyle, Broadcasted, broadcasted, broadcastable

struct CollectionStyle <: BroadcastStyle end

BroadcastStyle(::Type{<: AbstractCollection}) = CollectionStyle()
BroadcastStyle(::CollectionStyle, ::BroadcastStyle) = CollectionStyle()

broadcastable(c::AbstractCollection) = c
broadcastable(c::Broadcasted{CollectionStyle}) = copy(c)

function Base.copy(bc::Broadcasted{CollectionStyle})
    lazy(bc.f, bc.args...)
end

function Base.copyto!(dest::Union{AbstractVector, AbstractCollection}, src::Broadcasted{CollectionStyle})
    set!(dest, copy(src))
end
