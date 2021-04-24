@testset "AbstractLayeredArray" begin
    x = MyType([1,2,3])
    @test (@inferred LayeredArrays.whichlayer(x))::Int == 1
    @test (@inferred eltype(x)) == Int
    @test (@inferred fill!(x, 0))::MyType{Int} == [0,0,0]
    @test (@inferred collect(x))::Vector{Int} == [0,0,0]
    @test (@inferred Array(x))::Vector{Int} == [0,0,0]
    y = [1,2,3]
    @test (@inferred broadcast!(identity, y, x))::Vector{Int} == [0,0,0]
end
