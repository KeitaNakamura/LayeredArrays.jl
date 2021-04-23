"""
    LayeredCollections.LazyOperationType(f)

This needs to be overrided for custom operator.
Return `LazyAddLikeOperator()` or `LazyMulLikeOperator()`.
"""
abstract type LazyOperationType end
struct LazyAddLikeOperator <: LazyOperationType end
struct LazyMulLikeOperator <: LazyOperationType end
LazyOperationType(::Any) = LazyAddLikeOperator()
@pure function LazyOperationType(f::Function)
    Base.operator_precedence(Symbol(f)) ≥ Base.operator_precedence(:*) ?
        LazyMulLikeOperator() : LazyAddLikeOperator()
end

# add `Ref`s
lazyable(::LazyOperationType, c, ::Val) = Ref(c)
lazyable(::LazyOperationType, c::Base.RefValue, ::Val) = c
lazyable(::LazyOperationType, c::AbstractCollection{layer}, ::Val{layer}) where {layer} = c
lazyable(::LazyAddLikeOperator, c::AbstractCollection, ::Val) = throw(ArgumentError("addition like operation with different collections is not allowded"))
@generated function lazyables(f, args...)
    layer = maximum(whichlayer, args)
    Expr(:tuple, [:(lazyable(LazyOperationType(f), args[$i], Val($layer))) for i in 1:length(args)]...)
end
lazyables(f, args′::Union{Base.RefValue, AbstractCollection{layer}}...) where {layer} = args′ # already "lazyabled"

# extract arguments without `Ref`
_extract_norefs(ret::Tuple) = ret
_extract_norefs(ret::Tuple, x::Ref, y...) = _extract_norefs(ret, y...)
_extract_norefs(ret::Tuple, x, y...) = _extract_norefs((ret..., x), y...)
extract_norefs(x...) = _extract_norefs((), x...)
extract_norefs(x::AbstractCollection...) = x

"""
    return_layer(f, args...)

Get returned layer.
"""
function return_layer(f, args...)
    args′ = extract_norefs(lazyables(f, args...)...)
    return_layer(LazyOperationType(f), args′...)
end
return_layer(::LazyOperationType, ::AbstractCollection{layer}...) where {layer} = layer

"""
    return_dims(f, args...)

Get returned dimensions.
"""
function return_dims(f, args...)
    map(length, Broadcast.combine_axes(args...))
end

function return_eltype(f, args...)
    Base._return_type(_propagate_lazy, eltypes((f,args...)))
end
_eltype(x::AbstractCollection) = eltype(x)
_eltype(x::Base.RefValue) = eltype(x)
_eltype(x) = typeof(x)
eltypes(::Tuple{}) = Tuple{}
eltypes(t::Tuple{Any}) = Tuple{_eltype(t[1])}
eltypes(t::Tuple{Any, Any}) = Tuple{_eltype(t[1]), _eltype(t[2])}
eltypes(t::Tuple) = Tuple{_eltype(t[1]), eltypes(Base.tail(t)).types...}


struct LazyCollection{layer, T, F, Args <: Tuple, N} <: AbstractCollection{layer, T}
    f::F
    args::Args
    dims::NTuple{N, Int}
    function LazyCollection{layer, T, F, Args, N}(f::F, args::Args, dims::NTuple{N, Int}) where {layer, T, F, Args, N}
        new{layer::Int, T, F, Args, N}(f, args, dims)
    end
end

@inline function LazyCollection{layer, T}(f::F, args::Args, dims::NTuple{N, Int}) where {layer, T, F, Args, N}
    LazyCollection{layer, T, F, Args, N}(f, args, dims)
end

_newshape(dims::Dims, x::Base.RefValue) = x
_newshape(dims::Dims{1}, x::AbstractCollection) = x
_newshape(dims::Dims{2}, x::AbstractCollection) = repeat(x, outer = dims[2])
_newshape(dims::Dims{2}, x::AdjointCollection) = repeat(x, inner = dims[1])
function _newshape(dims::Dims{2}, x::LazyCollection{<: Any, <: Any, <: Any, <: Any, 2})
    size(x) == dims && return repeat(x)
    size(x, 1) == 1 && return repeat(x, inner = dims[1])
    error() # unreachable
end
newshapes(dims::Dims, x::Tuple{Any}) = (_newshape(dims, x[1]),)
newshapes(dims::Dims, x::Tuple{Any, Any}) = (_newshape(dims, x[1]), _newshape(dims, x[2]))
newshapes(dims::Dims, x::Tuple) = (_newshape(dims, x[1]), newshapes(dims, Base.tail(x))...)

function LazyCollection(f, args...)
    args′ = lazyables(f, args...)
    norefs = extract_norefs(args′...)
    layer = return_layer(f, norefs...)
    dims = return_dims(f, norefs...)
    T = return_eltype(f, args′...)
    LazyCollection{layer, T}(f, newshapes(dims, args′), dims)
end
lazy(f, args...) = LazyCollection(f, args...)

Base.length(c::LazyCollection) = prod(c.dims)
Base.size(c::LazyCollection) = c.dims

# this propagates lazy operation when any AbstractCollection is found
# otherwise just normally call function `f`.
@generated function _propagate_lazy(f, args...)
    any([t <: AbstractCollection for t in args]) ?
        :(LazyCollection(f, args...)) : :(f(args...))
end
_propagate_lazy(f, arg) = f(arg) # this prevents too much propagation

_getindex(c::AbstractCollection, i::Int) = (@_propagate_inbounds_meta; c[i])
_getindex(c::Base.RefValue, i::Int) = c[]
_getindex_broadcast(x::Tuple{Any}, i::Int) = (_getindex(x[1], i),)
_getindex_broadcast(x::Tuple{Any, Any}, i::Int) = (_getindex(x[1], i), _getindex(x[2], i))
_getindex_broadcast(x::Tuple, i::Int) = (_getindex(x[1], i), _getindex_broadcast(Base.tail(x), i)...)
@inline function Base.getindex(c::LazyCollection, i::Int)
    @boundscheck checkbounds(c, i)
    @inbounds _propagate_lazy(c.f, _getindex_broadcast(c.args, i)...)
end

show_type_name(c::LazyCollection{layer, T}) where {layer, T} = "LazyCollection{$layer, $T}"
