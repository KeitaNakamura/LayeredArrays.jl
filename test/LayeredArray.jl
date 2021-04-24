@testset "LayeredArray" begin
    c = LayeredArray([2,6,4])
    @test LayeredArrays.whichlayer(c) == 1
    # getindex
    for i in eachindex(c)
        @test (@inferred c[i])::Int == [2,6,4][i]
    end
    @test (@inferred c[[1,3]])::LayeredVector{1, Int, <: SubArray} == [2,4]
    @test (@inferred c[1:2])::LayeredVector{1, Int, <: SubArray} == [2,6]
    @test (@inferred view(c, [1,3]))::SubArray == [2,4]
    @test (@inferred view(c, 1:2))::SubArray == [2,6]
    # setindex!
    for i in eachindex(c)
        c[i] = 2i
        @test (@inferred c[i])::Int == 2i
    end
end
