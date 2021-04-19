myfunc(x::Int, y::Int, z::Int) = x * y * z
LayeredCollections.LazyOperationType(::typeof(myfunc)) = LayeredCollections.LazyMulLikeOperator()
myfunc(x, y, z) = lazy(myfunc, x, y, z)
∑(x) = lazy(sum, x)

function check_collection(c, ans)
    @test c == ans
    for i in eachindex(c)
        @test (@inferred c[i]) == ans[i]
    end
end

@testset "LazyCollection" begin
    # layer = 1
    data1 = [1,2,3]
    layer1 = Collection(data1)
    check_collection((@inferred 2 * layer1)::LazyCollection{1}, 2 * data1)
    check_collection((@inferred layer1 / 2)::LazyCollection{1}, data1 / 2)
    check_collection((@inferred layer1 + layer1)::LazyCollection{1}, data1 + data1)
    check_collection((@inferred layer1 - layer1)::LazyCollection{1}, data1 - data1)
    check_collection((@inferred layer1 * layer1)::LazyCollection{1}, data1 .* data1)
    check_collection((@inferred (layer1 + 2*layer1))::LazyCollection{1}, @. data1 + 2*data1)
    check_collection((@inferred (layer1*layer1 + layer1*layer1))::LazyCollection{1}, 2 * (data1 .* data1))
    check_collection((@inferred (layer1*layer1 - layer1*layer1))::LazyCollection{1}, 0 * (data1 .* data1))
    # layer = 0
    data0 = [2,4,6]
    layer0 = MyType(data0)
    check_collection((@inferred 2 * layer0)::LazyCollection{0}, 2 * data0)
    check_collection((@inferred layer0 / 2)::LazyCollection{0}, data0 / 2)
    check_collection((@inferred layer0 + layer0)::LazyCollection{0}, data0 + data0)
    check_collection((@inferred layer0 - layer0)::LazyCollection{0}, data0 - data0)
    check_collection((@inferred layer0 * layer0)::LazyCollection{-1}, data0 * data0')
    check_collection((@inferred (layer0 + 2*layer0))::LazyCollection{0}, @. data0 + 2*data0)
    check_collection((@inferred (layer0*layer0 + layer0*layer0))::LazyCollection{-1}, 2 * (data0 * data0'))
    check_collection((@inferred (layer0*layer0 - layer0*layer0))::LazyCollection{-1}, 0 * (data0 * data0'))
    # layer = 1 and 2
    data2 = [4,5,6]
    layer2 = Collection{2}(data2)
    check_collection((@inferred layer1 * layer2)::LazyCollection{2}, copy(Broadcast.broadcasted(*, Ref(data1), data2)))
    check_collection((@inferred layer2 * layer1)::LazyCollection{2}, copy(Broadcast.broadcasted(*, data2, Ref(data1))))
    @test_throws Exception layer1 + layer2
    @test_throws Exception layer2 + layer1
    @test_throws Exception layer1 - layer2
    @test_throws Exception layer2 - layer1
    # layer = 0 and 1
    check_collection((@inferred layer0 * layer1)::LazyCollection{1}, data0 .* data1)
    check_collection((@inferred layer1 * layer0)::LazyCollection{1}, data1 .* data0)
    check_collection((@inferred layer0 / layer1)::LazyCollection{1}, data0 ./ data1)
    check_collection((@inferred layer1 / layer0)::LazyCollection{1}, data1 ./ data0)
    @test_throws Exception layer0 + layer1
    @test_throws Exception layer1 + layer0
    @test_throws Exception layer0 - layer1
    @test_throws Exception layer1 - layer0
    # layer = 0 and 2
    check_collection((@inferred layer0 * layer2)::LazyCollection{2}, copy(Broadcast.broadcasted(*, Ref(data0), data2)))
    check_collection((@inferred layer2 * layer0)::LazyCollection{2}, copy(Broadcast.broadcasted(*, data2, Ref(data0))))
    @test_throws Exception layer0 + layer2
    @test_throws Exception layer2 + layer0
    @test_throws Exception layer0 - layer2
    @test_throws Exception layer2 - layer0
    # custom functions
    check_collection((@inferred myfunc(layer1, 2, layer2))::LazyCollection{2}, [[myfunc(x1, 2, x2) for x1 in data1] for x2 in data2])
    check_collection((@inferred myfunc(layer1, 2, layer0))::LazyCollection{1}, [myfunc(data1[i], 2, data0[i]) for i in eachindex(data1, data0)])
    check_collection((@inferred myfunc(layer0, 2, layer0))::LazyCollection{-1}, [myfunc(data0[i], 2, data0[j]) for i in eachindex(data0), j in eachindex(data0)])
    # other complicated cases
    check_collection((@inferred lazy(sum, (layer1 * layer2)))::LazyCollection{2}, [sum([x1 * x2 for x1 in data1]) for x2 in data2])
    check_collection((@inferred ∑(layer1 * layer2))::LazyCollection{2}, [sum([x1 * x2 for x1 in data1]) for x2 in data2])
    check_collection((@inferred lazy(sum, (layer0 * layer2)))::LazyCollection{2}, [sum([x0 * x2 for x0 in data0]) for x2 in data2])
    check_collection((@inferred ∑(layer0 * layer2))::LazyCollection{2}, [sum([x0 * x2 for x0 in data0]) for x2 in data2])
    # recursive version
    d0 = [layer0, layer0, layer0]
    d1 = [layer1, layer1, layer1]
    x0 = Collection{2}(d0)
    x1 = Collection{2}(d1)
    check_collection((@inferred ∑(2 * x0 * x1))::LazyCollection{2}, [sum([(2 * d0[i][j] * d1[i][j]) for j in 1:length(d0[i])]) for i in 1:length(d0)])
end
