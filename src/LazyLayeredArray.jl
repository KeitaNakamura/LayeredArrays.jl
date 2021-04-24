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
lazyable(::LazyOperationType, x, ::Val) = Ref(x)
lazyable(::LazyOperationType, x::Base.RefValue, ::Val) = x
lazyable(::LazyOperationType, x::AbstractLayeredArray{layer}, ::Val{layer}) where {layer} = x
lazyable(::LazyOperationType, x::Adjoint{<: Any, <: AbstractLayeredArray{layer}}, ::Val{layer}) where {layer} = x
lazyable(::LazyAddLikeOperator, x::AbstractLayeredArray, ::Val) = throw(ArgumentError("addition like operation with different layer is not allowded"))
lazyable(::LazyAddLikeOperator, x::Adjoint{<: Any, <: AbstractLayeredArray}, ::Val) = throw(ArgumentError("addition like operation with different layer is not allowded"))
@generated function lazyables(f, args...)
    layer = maximum(whichlayer, args)
    Expr(:tuple, [:(lazyable(LazyOperationType(f), args[$i], Val($layer))) for i in 1:length(args)]...)
end
lazyables(f, args′::Union{Base.RefValue, AbstractLayeredArray{layer}}...) where {layer} = args′ # already "lazyabled"

# extract arguments without `Ref`
_extract_norefs(ret::Tuple) = ret
_extract_norefs(ret::Tuple, x::Ref, y...) = _extract_norefs(ret, y...)
_extract_norefs(ret::Tuple, x, y...) = _extract_norefs((ret..., x), y...)
extract_norefs(x...) = _extract_norefs((), x...)
extract_norefs(x::AbstractLayeredArray...) = x

"""
    return_layer(f, args...)

Get returned layer.
"""
function return_layer(f, args...)
    args′ = extract_norefs(lazyables(f, args...)...)
    return_layer(LazyOperationType(f), args′...)
end
return_layer(f) = error() # unreachable
return_layer(::LazyOperationType, ::Union{AbstractLayeredArray{layer}, Adjoint{<: Any, <: AbstractLayeredArray{layer}}}...) where {layer} = layer

function return_eltype(f, args...)
    Base._return_type(_propagate_lazy, eltypes((f,args...)))
end
_eltype(x::AbstractLayeredArray) = eltype(x)
_eltype(x::Adjoint{<: Any, <: AbstractLayeredArray}) = eltype(x)
_eltype(x::Base.RefValue) = eltype(x)
_eltype(x) = typeof(x)
eltypes(::Tuple{}) = Tuple{}
eltypes(t::Tuple{Any}) = Tuple{_eltype(t[1])}
eltypes(t::Tuple{Any, Any}) = Tuple{_eltype(t[1]), _eltype(t[2])}
eltypes(t::Tuple) = Tuple{_eltype(t[1]), eltypes(Base.tail(t)).types...}


struct LazyLayeredArray{layer, T, N, BC <: Broadcasted{<: AbstractArrayStyle{N}}} <: AbstractLayeredArray{layer, T, N}
    bc::BC
    function LazyLayeredArray{layer, T, N, BC}(bc::BC) where {layer, T, N, BC}
        new{layer::Int, T, N, BC}(bc)
    end
end

const LazyLayeredVector{layer, T, BC <: Broadcasted{LayeredArrayStyle{1}}} = LazyLayeredArray{layer, T, 1, BC}
const LazyLayeredMatrix{layer, T, BC <: Broadcasted{LayeredArrayStyle{2}}} = LazyLayeredArray{layer, T, 2, BC}

@inline function LazyLayeredArray{layer, T}(bc::BC) where {layer, T, N, BC <: Broadcasted{<: AbstractArrayStyle{N}}}
    LazyLayeredArray{layer, T, N, BC}(bc)
end

function LazyLayeredArray(f, args...)
    args′ = lazyables(f, args...)
    norefs = extract_norefs(args′...)
    layer = return_layer(f, norefs...)
    T = return_eltype(f, args′...)
    LazyLayeredArray{layer, T}(Broadcast.broadcasted(f, args′...))
end

Base.size(x::LazyLayeredArray) = size(x.bc)
Base.axes(x::LazyLayeredArray) = axes(x.bc)

# this propagates lazy operation when any AbstractLayeredArray is found
# otherwise just normally call function `f`.
@generated function _propagate_lazy(f, args...)
    any([t <: AbstractLayeredArray || t <: Adjoint{<: Any, <: AbstractLayeredArray} for t in args]) ?
        :(LazyLayeredArray(f, args...)) : :(f(args...))
end
_propagate_lazy(f, arg) = f(arg) # this prevents too much propagation

_getindex(x::AbstractLayeredArray, i) = (@_propagate_inbounds_meta; x[Broadcast.newindex(x,i)])
_getindex(x::Adjoint{<: Any, <: AbstractLayeredArray}, i) = (@_propagate_inbounds_meta; x[Broadcast.newindex(x,i)])
_getindex(x::Base.RefValue, i) = x[]
_getindex_broadcast(x::Tuple{Any}, i) = (_getindex(x[1], i),)
_getindex_broadcast(x::Tuple{Any, Any}, i) = (_getindex(x[1], i), _getindex(x[2], i))
_getindex_broadcast(x::Tuple, i) = (_getindex(x[1], i), _getindex_broadcast(Base.tail(x), i)...)
@inline function Base.getindex(x::LazyLayeredArray, I::Int...)
    @boundscheck checkbounds(x, I...)
    bc = x.bc
    @inbounds _propagate_lazy(bc.f, _getindex_broadcast(bc.args, CartesianIndex(I))...)
end
