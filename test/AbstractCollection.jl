struct MyType{T} <: AbstractCollection{1, T}
    x::Vector{T}
end
Base.length(m::MyType) = length(m.x)
Base.getindex(m::MyType, i::Int) = getindex(m.x, i)
Base.setindex!(m::MyType, v, i::Int) = setindex!(m.x, v, i)

@testset "AbstractCollection" begin
    x = MyType([1,2,3])
    @test (@inferred LayeredCollections.whichlayer(x))::Int == 1
    @test (@inferred eltype(x)) == Int
    @test (@inferred fill!(x, 0))::MyType{Int} == [0,0,0]
    @test (@inferred collect(x))::Vector{Int} == [0,0,0]
    @test (@inferred Array(x))::Vector{Int} == [0,0,0]
    y = [1,2,3]
    @test (@inferred broadcast!(identity, y, x))::Vector{Int} == [0,0,0]
end
