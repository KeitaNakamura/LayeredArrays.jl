@testset "Collection" begin
    c = Collection([1,2,3])
    @test LayeredCollections.whichlayer(c) == 1
    for i in eachindex(c)
        @test (@inferred c[i])::Int == i
    end
    for i in eachindex(c)
        c[i] = 2i
        @test (@inferred c[i])::Int == 2i
    end
end
