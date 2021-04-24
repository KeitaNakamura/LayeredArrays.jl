@testset "Collection" begin
    c = Collection([2,6,4])
    @test LayeredCollections.whichlayer(c) == 1
    # getindex
    for i in eachindex(c)
        @test (@inferred c[i])::Int == [2,6,4][i]
    end
    @test (@inferred c[[1,3]])::CollectionView{1, Int} == [2,4]
    @test (@inferred c[1:2])::CollectionView{1, Int} == [2,6]
    @test (@inferred view(c, [1,3]))::CollectionView{1, Int} == [2,4]
    @test (@inferred view(c, 1:2))::CollectionView{1, Int} == [2,6]
    # setindex!
    for i in eachindex(c)
        c[i] = 2i
        @test (@inferred c[i])::Int == 2i
    end
end
