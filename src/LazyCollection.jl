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

_promote_rank(::Bool, ::AbstractCollection{rank}, ::AbstractCollection{rank}...) where {rank} = rank
_promote_rank(::Bool, ::AbstractCollection{0}) = 0
_promote_rank(::Bool, ::AbstractCollection{0}, ::AbstractCollection{0}, ::AbstractCollection{0}...) = error()
_promote_rank(mulprec::Bool, ::AbstractCollection{0}, ::AbstractCollection{0}) = mulprec ? -1 : 0
@generated function promote_rank(f, args...)
    mulprec = multiply_precedence(f)
    quote
        args′ = extract_norefs(lazyables(args...)...)
        _promote_rank($mulprec, args′...)
    end
end

# check if all `length`s are the same
check_dims(x::Dims) = x
check_dims(x::Dims, y::Dims, z::Dims...) = (@assert x == y; check_dims(y, z...))
@generated function combine_dims(f, args...)
    quote
        args′ = extract_norefs(lazyables(args...)...)
        rank = promote_rank(f, args′...)
        if rank == -1
            flatten_tuple(map(size, args′))
        else
            check_dims(map(size, args′)...)
        end
    end
end

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
        rank = promote_rank(f, norefs...)
        dims = combine_dims(f, norefs...)
        LazyCollection{rank}(f, args′, dims)
    end
end
lazy(f, args...) = LazyCollection(f, args...)

Base.length(c::LazyCollection) = prod(c.dims)
Base.size(c::LazyCollection) = c.dims
Base.ndims(c::LazyCollection) = length(size(c))

@inline _getindex(c::LazyCollection, i::Int) = (@_propagate_inbounds_meta; c[i])
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
