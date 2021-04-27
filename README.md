# LayeredArrays

*Layer-wise array computation for Julia*

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://KeitaNakamura.github.io/LayeredArrays.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://KeitaNakamura.github.io/LayeredArrays.jl/dev)
[![Build Status](https://github.com/KeitaNakamura/LayeredArrays.jl/workflows/CI/badge.svg)](https://github.com/KeitaNakamura/LayeredArrays.jl/actions)
[![codecov](https://codecov.io/gh/KeitaNakamura/LayeredArrays.jl/branch/main/graph/badge.svg?token=KXLJPD7E0I)](https://codecov.io/gh/KeitaNakamura/LayeredArrays.jl)

LayeredArrays provides layer-wise array computation written in the [Julia programming language](https://julialang.org).
The layers have hierarchical structure, and lower layers can be accessed by using `getindex` in `AbstractLayeredArray`.
All types except subtypes of `AbstractLayeredArray` are on bottom layer `0`.
The layer-wise operations are simply available by using [`broadcast operations`](https://docs.julialang.org/en/v1/manual/arrays/#Broadcasting), where operations are performed in order from the highest to the lowest layer.
For example, we have three vectors on layer 1 and 2:

```julia
julia> x = @layered 1 ["a", "b", "c"]
3-element LayeredVector{1, String, Vector{String}}:
 "a"
 "b"
 "c"

julia> y = @layered 1 ["d", "e", "f"]
3-element LayeredVector{1, String, Vector{String}}:
 "d"
 "e"
 "f"

julia> z = @layered 2 ["g", "h", "i"]
3-element LayeredVector{2, String, Vector{String}}:
 "g"
 "h"
 "i"
```

The broadcasting vector multiplication for those vectors are then computed as

```julia
julia> @. x * y # equal to built-in Array for operations on the same layers
3-element LazyLayeredVector{1, String, Base.Broadcast.Broadcasted{LayeredArrays.LayeredArrayStyle{1}, Nothing, typeof(*), Tuple{LayeredVector{1, String, Vector{String}}, LayeredVector{1, String, Vector{String}}}}}:
 "ad"
 "be"
 "cf"

julia> @. x * z # broadcasting operations on each layer
3-element LazyLayeredVector{2, LazyLayeredVector{1, String, Base.Broadcast.Broadcasted{LayeredArrays.LayeredArrayStyle{1}, Nothing, typeof(*), Tuple{LayeredVector{1, String, Vector{String}}, Base.RefValue{String}}}}, Base.Broadcast.Broadcasted{LayeredArrays.LayeredArrayStyle{1}, Nothing, typeof(*), Tuple{Base.RefValue{LayeredVector{1, String, Vector{String}}}, LayeredVector{2, String, Vector{String}}}}}:
 ["ag", "bg", "cg"]
 ["ah", "bh", "ch"]
 ["ai", "bi", "ci"]

julia> @. x * y * z
3-element LazyLayeredVector{2, LazyLayeredVector{1, String, Base.Broadcast.Broadcasted{LayeredArrays.LayeredArrayStyle{1}, Nothing, typeof(*), Tuple{LayeredVector{1, String, Vector{String}}, LayeredVector{1, String, Vector{String}}, Base.RefValue{String}}}}, Base.Broadcast.Broadcasted{LayeredArrays.LayeredArrayStyle{1}, Nothing, typeof(*), Tuple{Base.RefValue{LayeredVector{1, String, Vector{String}}}, Base.RefValue{LayeredVector{1, String, Vector{String}}}, LayeredVector{2, String, Vector{String}}}}}:
 ["adg", "beg", "cfg"]
 ["adh", "beh", "cfh"]
 ["adi", "bei", "cfi"]
```

Note that the layer-wise broadcasting operations are always lazily evaluated.
