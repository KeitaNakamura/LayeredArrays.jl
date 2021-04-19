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
lazyable(::LazyAddLikeOperator, c::AbstractCollection{layer}, ::Val{layer}) where {layer} = c
lazyable(::LazyAddLikeOperator, c::AbstractCollection, ::Val) = throw(ArgumentError("addition like operation with different collections is not allowded"))
lazyable(::LazyMulLikeOperator, c::AbstractCollection{layer}, ::Val{layer}) where {layer} = c
lazyable(::LazyMulLikeOperator, c::AbstractCollection{0}, ::Val{1}) = Collection{1}(c) # 0 becomes 1 with other 1
@generated function lazyables(f, args...)
    layer = maximum(whichlayer, args)
    if minimum(whichlayer, args) == -1
        if layer != -1
            return :(throw(ArgumentError("layer=-1 collection cannot be computed with other layer collections.")))
        end
    end
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
return_layer(::LazyAddLikeOperator, ::AbstractCollection{layer}...) where {layer} = layer
return_layer(::LazyMulLikeOperator, ::AbstractCollection{layer}...) where {layer} = layer
return_layer(::LazyMulLikeOperator, ::AbstractCollection{0}) = 0
return_layer(::LazyMulLikeOperator, ::AbstractCollection{0}, ::AbstractCollection{0}) = -1
return_layer(::LazyMulLikeOperator, ::AbstractCollection{0}, ::AbstractCollection{0}, x::AbstractCollection{0}...) =
    throw(ArgumentError("layer=-1 collections are used $(2+length(x)) times in multiplication"))
return_layer(::LazyMulLikeOperator, ::AbstractCollection{-1}) = -1
return_layer(::LazyMulLikeOperator, ::AbstractCollection{-1}, x::AbstractCollection{-1}...) =
    throw(ArgumentError("layer=-1 collections are used $(1+length(x)) times in multiplication"))

"""
    return_dims(f, args...)

Get returned dimensions.
"""
function return_dims(f, args...)
    args′ = extract_norefs(lazyables(f, args...)...)
    return_dims(LazyOperationType(f), args′...)
end
check_dims(x::Dims) = x
check_dims(x::Dims, y::Dims, z::Dims...) = (@assert x == y; check_dims(y, z...))
return_dims(::LazyAddLikeOperator, args::AbstractCollection{layer}...) where {layer} = check_dims(map(size, args)...)
return_dims(::LazyMulLikeOperator, args::AbstractCollection{layer}...) where {layer} = check_dims(map(size, args)...)
return_dims(::LazyMulLikeOperator, x::AbstractCollection{0}, y::AbstractCollection{0}) = (length(x), length(y))
return_dims(::LazyMulLikeOperator, x::AbstractCollection{-1}) = size(x)


struct LazyCollection{layer, F, Args <: Tuple, N} <: AbstractCollection{layer}
    f::F
    args::Args
    dims::NTuple{N, Int}
    function LazyCollection{layer, F, Args, N}(f::F, args::Args, dims::NTuple{N, Int}) where {layer, F, Args, N}
        new{layer::Int, F, Args, N}(f, args, dims)
    end
end

@inline function LazyCollection{layer}(f::F, args::Args, dims::NTuple{N, Int}) where {layer, F, Args, N}
    LazyCollection{layer, F, Args, N}(f, args, dims)
end

@generated function LazyCollection(f, args...)
    quote
        args′ = lazyables(f, args...)
        norefs = extract_norefs(args′...)
        layer = return_layer(f, norefs...)
        dims = return_dims(f, norefs...)
        LazyCollection{layer}(f, args′, dims)
    end
end
lazy(f, args...) = LazyCollection(f, args...)

Base.length(c::LazyCollection) = prod(c.dims)
Base.size(c::LazyCollection) = c.dims
Base.ndims(c::LazyCollection) = length(size(c))

@generated function _lazy(f, args...)
    if any([t <: AbstractCollection for t in args])
        quote
            LazyCollection(f, args...)
        end
    else
        quote
            f(args...)
        end
    end
end
_lazy(f, arg) = f(arg)
@inline _getindex(c::AbstractCollection, i::Int) = (@_propagate_inbounds_meta; c[i])
@inline _getindex(c::Base.RefValue, i::Int) = c[]
@generated function Base.getindex(c::LazyCollection{<: Any, <: Any, Args, 1}, i::Int) where {Args}
    exps = [:(_getindex(c.args[$j], i)) for j in 1:length(Args.parameters)]
    quote
        @_inline_meta
        @boundscheck checkbounds(c, i)
        @inbounds _lazy(c.f, $(exps...))
    end
end

@generated function Base.getindex(c::LazyCollection{-1, <: Any, Args, 2}, ij::Vararg{Int, 2}) where {Args}
    count = 0
    exps = map(enumerate(Args.parameters)) do (k, T)
        T <: Base.RefValue && return :(c.args[$k][])
        T <: AbstractCollection{-1} && return :(c.args[$k][ij...])
        T <: AbstractCollection && return :(c.args[$k][ij[$(count += 1)]])
        error()
    end
    @assert count == 0 || count == 2
    quote
        @_inline_meta
        @_propagate_inbounds_meta
        @inbounds _lazy(c.f, $(exps...))
    end
end
@inline function Base.getindex(c::LazyCollection{-1, <: Any, <: Any, 2}, i::Int)
    @boundscheck checkbounds(c, i)
    @inbounds begin
        I = CartesianIndices(size(c))[i...]
        c[Tuple(I)...]
    end
end

# convert to array
# this is needed for matrix type because `collect` is called by default
function Base.Array(c::LazyCollection)
    v = first(c)
    A = Array{typeof(v)}(undef, size(c))
    for i in eachindex(A)
        @inbounds A[i] = c[i]
    end
    A
end

show_type_name(c::LazyCollection) = "LazyCollection{$(whichlayer(c))}"
