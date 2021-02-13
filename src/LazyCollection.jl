# add `Ref`s
_lazyable(c::AbstractCollection{rank}, ::Val{rank}) where {rank} = c
_lazyable(c::AbstractCollection{0}, ::Val{1}) = Collection{1}(c) # 0 becomes 1 with other 1
_lazyable(c, ::Val) = Ref(c)
_lazyable(c::Base.RefValue, ::Val) = c
@generated function lazyables(args...)
    rank = maximum(whichrank, args)
    if minimum(whichrank, args) == -1
        if rank != -1
            return :(throw(ArgumentError("rank=-1 collection cannot be computed with other rank collections.")))
        end
    end
    quote
        broadcast(_lazyable, args, Val($rank))
    end
end
lazyables(args′::Union{Base.RefValue, AbstractCollection{rank}}...) where {rank} = args′ # already "lazyabled"

# extract arguments without `Ref`
_extract_norefs(ret::Tuple) = ret
_extract_norefs(ret::Tuple, x::Ref, y...) = _extract_norefs(ret, y...)
_extract_norefs(ret::Tuple, x, y...) = _extract_norefs((ret..., x), y...)
extract_norefs(x...) = _extract_norefs((), x...)
extract_norefs(x::AbstractCollection...) = x

"""
    LazyCollections.multiply_precedence(::Type) -> Bool

This needs to be overrided for custom operator.
"""
multiply_precedence(::Type) = false
multiply_precedence(::Type{F}) where {F <: Function} =
    Base.operator_precedence(Symbol(F.instance)) ≥ Base.operator_precedence(:*)

"""
    return_rank(f, args...)

Get returned rank.
"""
@generated function return_rank(f, args...)
    mulprec = multiply_precedence(f)
    quote
        args′ = extract_norefs(lazyables(args...)...)
        $(mulprec ? :(return_rank_mul(args′...)) : :(return_rank_add(args′...)))
    end
end
return_rank_add(::AbstractCollection{rank}...) where {rank} = rank
return_rank_mul(::AbstractCollection{rank}...) where {rank} = rank
return_rank_mul(::AbstractCollection{0}) = 0
return_rank_mul(::AbstractCollection{0}, ::AbstractCollection{0}) = -1
return_rank_mul(::AbstractCollection{0}, ::AbstractCollection{0}, x::AbstractCollection{0}...) =
    throw(ArgumentError("rank=-1 collections are used $(2+length(x)) times in multiplication"))
return_rank_mul(::AbstractCollection{-1}) = -1
return_rank_mul(::AbstractCollection{-1}, x::AbstractCollection{-1}...) =
    throw(ArgumentError("rank=-1 collections are used $(1+length(x)) times in multiplication"))

"""
    return_dims(f, args...)

Get returned dimensions.
"""
@generated function return_dims(f, args...)
    mulprec = multiply_precedence(f)
    quote
        args′ = extract_norefs(lazyables(args...)...)
        $(mulprec ? :(return_dims_mul(args′...)) : :(return_dims_add(args′...)))
    end
end
check_dims(x::Dims) = x
check_dims(x::Dims, y::Dims, z::Dims...) = (@assert x == y; check_dims(y, z...))
return_dims_add(args::AbstractCollection{rank}...) where {rank} = check_dims(map(size, args)...)
return_dims_mul(args::AbstractCollection{rank}...) where {rank} = check_dims(map(size, args)...)
return_dims_mul(x::AbstractCollection{0}, y::AbstractCollection{0}) = (length(x), length(y))
return_dims_mul(x::AbstractCollection{-1}) = size(x)


struct LazyCollection{rank, F, Args <: Tuple, N} <: AbstractCollection{rank}
    f::F
    args::Args
    dims::NTuple{N, Int}
    function LazyCollection{rank, F, Args, N}(f::F, args::Args, dims::NTuple{N, Int}) where {rank, F, Args, N}
        new{rank::Int, F, Args, N}(f, args, dims)
    end
end

@inline function LazyCollection{rank}(f::F, args::Args, dims::NTuple{N, Int}) where {rank, F, Args, N}
    LazyCollection{rank, F, Args, N}(f, args, dims)
end

@generated function LazyCollection(f, args...)
    quote
        args′ = lazyables(args...)
        norefs = extract_norefs(args′...)
        rank = return_rank(f, norefs...)
        dims = return_dims(f, norefs...)
        LazyCollection{rank}(f, args′, dims)
    end
end
lazy(f, args...) = LazyCollection(f, args...)

Base.length(c::LazyCollection) = prod(c.dims)
Base.size(c::LazyCollection) = c.dims
Base.ndims(c::LazyCollection) = length(size(c))

@inline _getindex(c::AbstractCollection, i::Int) = (@_propagate_inbounds_meta; c[i])
@inline _getindex(c::Base.RefValue, i::Int) = c[]
@inline function Base.getindex(c::LazyCollection{<: Any, <: Any, <: Any, 1}, i::Int)
    @boundscheck checkbounds(c, i)
    @inbounds begin
        args = broadcast(_getindex, c.args, i)
        c.f(args...)
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
        @inbounds c.f($(exps...))
    end
end
@inline function Base.getindex(c::LazyCollection{-1, <: Any, <: Any, 2}, i::Int) where {Args}
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

show_type_name(c::LazyCollection) = "LazyCollection{$(whichrank(c))}"


macro define_lazy_unary_operation(op)
    quote
        @inline $op(x::AbstractCollection) = lazy($op, x)
    end |> esc
end

macro define_lazy_binary_operation(op)
    quote
        @inline $op(c::AbstractCollection, x) = lazy($op, c, x)
        @inline $op(x, c::AbstractCollection) = lazy($op, x, c)
        @inline $op(x::AbstractCollection, y::AbstractCollection) = lazy($op, x, y)
    end |> esc
end

const unary_operations = [
    :(Base.:+),
    :(Base.:-),
]

const binary_operations = [
    :(Base.:+),
    :(Base.:-),
    :(Base.:*),
    :(Base.:/),
    :(Base.:^),
]

for op in unary_operations
    @eval @define_lazy_unary_operation $op
end

for op in binary_operations
    @eval @define_lazy_binary_operation $op
end
