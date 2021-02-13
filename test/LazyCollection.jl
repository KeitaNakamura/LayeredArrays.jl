@testset "LazyCollection" begin
    data1 = [1,2,3]
    # rank = 1
    rank1 = Collection(data1)
    @test (@inferred 2 * rank1)::LazyCollection{1} == 2 * data1
    @test (@inferred rank1 / 2)::LazyCollection{1} == data1 / 2
    @test (@inferred rank1 + rank1)::LazyCollection{1} == data1 + data1
    @test (@inferred rank1 - rank1)::LazyCollection{1} == data1 - data1
    @test (@inferred rank1 * rank1)::LazyCollection{1} == data1 .* data1
    @test (@inferred (rank1 + 2*rank1))::LazyCollection{1} == @. data1 + 2*data1
    @test (@inferred (rank1*rank1 + rank1*rank1))::LazyCollection{1} == 2 * (data1 .* data1)
    @test (@inferred (rank1*rank1 - rank1*rank1))::LazyCollection{1} == 0 * (data1 .* data1)
    # rank = 0
    data0 = [2,4,6]
    rank0 = MyType(data0)
    @test (@inferred 2 * rank0)::LazyCollection{0} == 2 * data0
    @test (@inferred rank0 / 2)::LazyCollection{0} == data0 / 2
    @test (@inferred rank0 + rank0)::LazyCollection{0} == data0 + data0
    @test (@inferred rank0 - rank0)::LazyCollection{0} == data0 - data0
    @test (@inferred rank0 * rank0)::LazyCollection{-1} == data0 * data0'
    @test (@inferred (rank0 + 2*rank0))::LazyCollection{0} == @. data0 + 2*data0
    @test (@inferred (rank0*rank0 + rank0*rank0))::LazyCollection{-1} == 2 * (data0 * data0')
    @test (@inferred (rank0*rank0 - rank0*rank0))::LazyCollection{-1} == 0 * (data0 * data0')
    # rank = 1 and 2
    data2 = [4,5,6]
    rank2 = Collection{2}(data2)
    @test (@inferred rank1 * rank2)::LazyCollection{2} == copy(Broadcast.broadcasted(*, Ref(data1), data2))
    @test (@inferred rank2 * rank1)::LazyCollection{2} == copy(Broadcast.broadcasted(*, data2, Ref(data1)))
    @test_throws Exception rank1 + rank2
    @test_throws Exception rank2 + rank1
    @test_throws Exception rank1 - rank2
    @test_throws Exception rank2 - rank1
    # rank = 0 and 1
    @test (@inferred rank0 * rank1)::LazyCollection{1} == data0 .* data1
    @test (@inferred rank1 * rank0)::LazyCollection{1} == data1 .* data0
    @test (@inferred rank0 / rank1)::LazyCollection{1} == data0 ./ data1
    @test (@inferred rank1 / rank0)::LazyCollection{1} == data1 ./ data0
    @test_throws Exception rank0 + rank1
    @test_throws Exception rank1 + rank0
    @test_throws Exception rank0 - rank1
    @test_throws Exception rank1 - rank0
    # rank = 0 and 2
    @test (@inferred rank0 * rank2)::LazyCollection{2} == copy(Broadcast.broadcasted(*, Ref(data0), data2))
    @test (@inferred rank2 * rank0)::LazyCollection{2} == copy(Broadcast.broadcasted(*, data2, Ref(data0)))
    @test_throws Exception rank0 + rank2
    @test_throws Exception rank2 + rank0
    @test_throws Exception rank0 - rank2
    @test_throws Exception rank2 - rank0
end
