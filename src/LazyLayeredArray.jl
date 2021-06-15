# add `Ref`s
lazyable(x, ::Val) = Ref(x)
lazyable(x::Base.RefValue, ::Val) = x
lazyable(x::AbstractLayeredArray{layer}, ::Val{layer}) where {layer} = x
@generated function lazyable(x::Broadcasted{<: Any, <: Any, <: Any, Tup}, ::Val) where {Tup <: Tuple}
    any(T -> T <: AbstractLayeredArray, Tup.parameters) && return :(@unreachable)
    quote
        Ref(copy(x))
    end
end
@generated function lazyables(f, args...)
    layer = maximum(layerof, args)
    exps = [:(lazyable(args[$i], Val($layer))) for i in 1:length(args)]
    quote
        @_inline_meta
        $layer, tuple($(exps...))
    end
end

_eltype(x::AbstractLayeredArray) = eltype(x)
_eltype(x::Base.RefValue) = eltype(x)
_eltype(x) = typeof(x)
function return_eltype(f, args...)
    T = Base._return_type(_propagate_lazy, Tuple{apply2all(_eltype, (f,args...))...})
    if T == Union{}
        f(map(first, args)...)
        @unreachable
    end
    T
end


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
    layer, args′ = lazyables(f, args...)
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
_propagate_lazy(f) = @unreachable

_getindex(x::AbstractLayeredArray, i) = (@_propagate_inbounds_meta; x[Broadcast.newindex(x,i)])
_getindex(x::Base.RefValue, i) = x[]
@inline function Base.getindex(x::LazyLayeredArray, I::Int...)
    @boundscheck checkbounds(x, I...)
    bc = x.bc
    f(x) = _getindex(x, CartesianIndex(I))
    @inbounds _propagate_lazy(bc.f, apply2all(f, bc.args)...)
end

for op in (:+, :-)
    @eval function Base.$op(x::AbstractLayeredArray, y::AbstractLayeredArray)
        layerof(x) == layerof(y) || throw(ArgumentError("layers must match in $($op) operation"))
        LayeredArray{layerof(x)}(map($op, x, y))
    end
end
