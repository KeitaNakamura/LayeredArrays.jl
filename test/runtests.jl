using LayeredArrays
using LayeredArrays: LazyLayeredArray
using Test

struct MyType{T} <: AbstractLayeredVector{1, T}
    x::Vector{T}
end
Base.size(m::MyType) = size(m.x)
Base.getindex(m::MyType, i::Int) = getindex(m.x, i)
Base.setindex!(m::MyType, v, i::Int) = setindex!(m.x, v, i)

include("AbstractLayeredArray.jl")
include("LayeredArray.jl")
include("LazyLayeredArray.jl")
