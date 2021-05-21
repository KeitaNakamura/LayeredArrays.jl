# LayeredArrays

## Introduction

LayeredArrays provides layer-wise array computation written in the [Julia programming language](https://julialang.org).
The layers have hierarchical structure, and lower layers can be accessed by using `getindex` in `AbstractLayeredArray`.
All types except subtypes of `AbstractLayeredArray` are on bottom layer `0`.
The layer-wise operations are simply available by using [`broadcast operations`](https://docs.julialang.org/en/v1/manual/arrays/#Broadcasting).
This framework is useful for following index notation.

```julia
julia> xᵢ = @layered 3 [1,2,3]
3-element LayeredVector{3, Int64, Vector{Int64}}:
 1
 2
 3

julia> yⱼ = @layered 2 [4,5,6]
3-element LayeredVector{2, Int64, Vector{Int64}}:
 4
 5
 6

julia> zₖ = @layered 1 [7,8,9]
3-element LayeredVector{1, Int64, Vector{Int64}}:
 7
 8
 9

julia> Aᵢⱼₖ = @. xᵢ * yⱼ + zₖ * yⱼ;                   # layerof(Aᵢⱼₖ) == 3

julia> Aᵢⱼₖ[1] == @. xᵢ[1] * yⱼ + zₖ * yⱼ             # layerof(Aᵢⱼₖ[1]) == 2
true

julia> Aᵢⱼₖ[1][2] == @. xᵢ[1] * yⱼ[2] + zₖ * yⱼ[2]    # layerof(Aᵢⱼₖ[1][2]) == 1
true

julia> Aᵢⱼₖ[1][2][3] == xᵢ[1] * yⱼ[2] + zₖ[3] * yⱼ[2] # layerof(Aᵢⱼₖ[1][2][3]) == 0
true
```

Note that the layer-wise broadcasting operations are always lazily evaluated.

## Installation

```julia
pkg> add LayeredArrays
```

## Types and Functions

```@autodocs
Modules = [LayeredArrays]
Order   = [:type, :function, :macro]
```
