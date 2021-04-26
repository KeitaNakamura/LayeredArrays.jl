# add `Ref`s
lazyable(x, ::Val) = Ref(x)
lazyable(x::Base.RefValue, ::Val) = x
lazyable(x::AbstractLayeredArray{layer}, ::Val{layer}) where {layer} = x
@generated function lazyables(f, args...)
    layer = maximum(whichlayer, args)
    exps = [:(lazyable(args[$i], Val($layer))) for i in 1:length(args)]
    quote
        @_inline_meta
        tuple($(exps...))
    end
end

# extract arguments without `Ref`
_extract_norefs(ret::Tuple) = ret
_extract_norefs(ret::Tuple, x::Ref, y...) = _extract_norefs(ret, y...)
_extract_norefs(ret::Tuple, x, y...) = _extract_norefs((ret..., x), y...)
extract_norefs(x...) = _extract_norefs((), x...)

function return_layer(f, args...)
    args′ = extract_norefs(lazyables(f, args...)...)
    return_layer(args′...)
end
return_layer() = error() # unreachable
return_layer(::AbstractLayeredArray{layer}...) where {layer} = layer

function return_eltype(f, args...)
    T = Base._return_type(_propagate_lazy, eltypes((f,args...)))
    if T == Union{}
        f(map(first, args)...)
        error() # unreachable
    end
    T
end
_eltype(x::AbstractLayeredArray) = eltype(x)
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
    any([t <: AbstractLayeredArray for t in args]) ?
    :(LazyLayeredArray(f, args...)) : :(f(args...))
end
_propagate_lazy(f, arg) = f(arg) # this prevents too much propagation

_getindex(x::AbstractLayeredArray, i) = (@_propagate_inbounds_meta; x[Broadcast.newindex(x,i)])
_getindex(x::Base.RefValue, i) = x[]
_getindex_broadcast(x::Tuple{Any}, i) = (_getindex(x[1], i),)
_getindex_broadcast(x::Tuple{Any, Any}, i) = (_getindex(x[1], i), _getindex(x[2], i))
_getindex_broadcast(x::Tuple, i) = (_getindex(x[1], i), _getindex_broadcast(Base.tail(x), i)...)
@inline function Base.getindex(x::LazyLayeredArray, I::Int...)
    @boundscheck checkbounds(x, I...)
    bc = x.bc
    @inbounds _propagate_lazy(bc.f, _getindex_broadcast(bc.args, CartesianIndex(I))...)
end

for op in (:+, :-)
    @eval function Base.$op(x::AbstractLayeredArray, y::AbstractLayeredArray)
        whichlayer(x) == whichlayer(y) || throw(ArgumentError("layers must match in $($op) operation"))
        LayeredArray{whichlayer(x)}(map($op, x, y))
    end
end
