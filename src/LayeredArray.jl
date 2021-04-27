"""
    LayeredArray(x)
    LayeredArray{layer}(x)

Construct `LayeredArray` on `layer` (`layer = 1` by default).

See also [`@layered`](@ref).

# Examples
```jldoctest
julia> x = LayeredArray([1,2,3])
3-element LayeredVector{1, Int64, Vector{Int64}}:
 1
 2
 3

julia> y = LayeredArray{2}([4,5,6])
3-element LayeredVector{2, Int64, Vector{Int64}}:
 4
 5
 6

julia> x .* y
3-element LazyLayeredVector{2, LazyLayeredVector{1, Int64, Base.Broadcast.Broadcasted{LayeredArrays.LayeredArrayStyle{1}, Nothing, typeof(*), Tuple{LayeredVector{1, Int64, Vector{Int64}}, Base.RefValue{Int64}}}}, Base.Broadcast.Broadcasted{LayeredArrays.LayeredArrayStyle{1}, Nothing, typeof(*), Tuple{Base.RefValue{LayeredVector{1, Int64, Vector{Int64}}}, LayeredVector{2, Int64, Vector{Int64}}}}}:
 [4, 8, 12]
 [5, 10, 15]
 [6, 12, 18]
```
"""
struct LayeredArray{layer, T, N, A <: AbstractArray{T, N}} <: AbstractLayeredArray{layer, T, N}
    parent::A
    function LayeredArray{layer, T, N, A}(parent::A) where {layer, T, N, A}
        x = new{layer, T, N, A}(parent)
        layerof(x) # check layer
        x
    end
end

const LayeredVector{layer, T, A <: AbstractVector{T}} = LayeredArray{layer, T, 1, A}
const LayeredMatrix{layer, T, A <: AbstractMatrix{T}} = LayeredArray{layer, T, 2, A}

# constructors
LayeredArray{layer}(x::A) where {layer, T, N, A <: AbstractArray{T, N}} = LayeredArray{layer, T, N, A}(x)
LayeredArray(v) = LayeredArray{1}(v)

Base.parent(x::LayeredArray) = x.parent

Base.size(x::LayeredArray) = size(parent(x))
Base.axes(x::LayeredArray) = axes(parent(x))

@inline function Base.getindex(x::LayeredArray, i::Integer...)
    @boundscheck checkbounds(x, i...)
    @inbounds parent(x)[i...]
end
@inline function Base.setindex!(x::LayeredArray, v, i::Integer...)
    @boundscheck checkbounds(x, i...)
    @inbounds parent(x)[i...] = v
    x
end

"""
    @layered expr
    @layered layer expr

Construct `LayeredArray` on `layer` (`layere = 1` by default).
This is equivalent to `LayeredArray{layer}(expr)`.

See also [`LayeredArray`](@ref).

# Examples
```jldoctest
julia> x = @layered [1,2,3]
3-element LayeredVector{1, Int64, Vector{Int64}}:
 1
 2
 3

julia> y = @layered 2 [4,5,6]
3-element LayeredVector{2, Int64, Vector{Int64}}:
 4
 5
 6

julia> x .* y
3-element LazyLayeredVector{2, LazyLayeredVector{1, Int64, Base.Broadcast.Broadcasted{LayeredArrays.LayeredArrayStyle{1}, Nothing, typeof(*), Tuple{LayeredVector{1, Int64, Vector{Int64}}, Base.RefValue{Int64}}}}, Base.Broadcast.Broadcasted{LayeredArrays.LayeredArrayStyle{1}, Nothing, typeof(*), Tuple{Base.RefValue{LayeredVector{1, Int64, Vector{Int64}}}, LayeredVector{2, Int64, Vector{Int64}}}}}:
 [4, 8, 12]
 [5, 10, 15]
 [6, 12, 18]
```
"""
macro layered(layer::Int, ex)
    esc(:(LayeredArray{$layer}($ex)))
end
macro layered(ex)
    esc(:(LayeredArray($ex)))
end
