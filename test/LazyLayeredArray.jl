myfunc(x::Int, y::Int, z::Int) = x * y * z

function check_getindex(x, ans)
    @test x == ans
    for i in eachindex(x)
        @test (@inferred x[i]) == ans[i]
    end
end

@testset "LazyLayeredArray" begin
    # layer = 1
    data1 = [1,2,3]
    layer1 = LayeredArray(data1)
    check_getindex(@inferred(2 .* layer1)::LazyLayeredArray{1}, 2 * data1)
    check_getindex(@inferred(layer1 ./ 2)::LazyLayeredArray{1}, data1 / 2)
    check_getindex(@inferred(layer1 .+ layer1)::LazyLayeredArray{1}, data1 + data1)
    check_getindex(@inferred(layer1 .- layer1)::LazyLayeredArray{1}, data1 - data1)
    check_getindex(@inferred(layer1 .* layer1)::LazyLayeredArray{1}, data1 .* data1)
    check_getindex(@inferred((layer1 .+ 2*layer1))::LazyLayeredArray{1}, @. data1 + 2*data1)
    check_getindex(@inferred((layer1.*layer1 .+ layer1.*layer1))::LazyLayeredArray{1}, 2 * (data1 .* data1))
    check_getindex(@inferred((layer1.*layer1 .- layer1.*layer1))::LazyLayeredArray{1}, 0 * (data1 .* data1))
    # custom type
    data1′ = [2,4,6]
    layer1′ = MyType(data1′)
    check_getindex(@inferred(2 .* layer1′)::LazyLayeredArray{1}, 2 * data1′)
    check_getindex(@inferred(layer1′ ./ 2)::LazyLayeredArray{1}, data1′ / 2)
    check_getindex(@inferred(layer1′ .+ layer1′)::LazyLayeredArray{1}, data1′ + data1′)
    check_getindex(@inferred(layer1′ .- layer1′)::LazyLayeredArray{1}, data1′ - data1′)
    check_getindex(@inferred(layer1′ .* layer1′')::LazyLayeredArray{1}, data1′ * data1′')
    check_getindex(@inferred((layer1′ .+ 2layer1′))::LazyLayeredArray{1}, @. data1′ + 2*data1′)
    check_getindex(@inferred((layer1′.*layer1′' .+ layer1′.*layer1′'))::LazyLayeredArray{1}, 2 * (data1′ * data1′'))
    check_getindex(@inferred((layer1′.*layer1′' .- layer1′.*layer1′'))::LazyLayeredArray{1}, 0 * (data1′ * data1′'))
    # layer = 1 and 2
    data2 = [4,5,6]
    layer2 = LayeredArray{2}(data2)
    check_getindex(@inferred(layer1 .* layer2)::LazyLayeredArray{2}, copy(Broadcast.broadcasted(*, Ref(data1), data2)))
    check_getindex(@inferred(layer2 .* layer1)::LazyLayeredArray{2}, copy(Broadcast.broadcasted(*, data2, Ref(data1))))
    check_getindex(@inferred(layer1 .+ layer2)::LazyLayeredArray{2}, copy(Broadcast.broadcasted((x,y) -> x .+ y, Ref(data1), data2)))
    check_getindex(@inferred(layer2 .+ layer1)::LazyLayeredArray{2}, copy(Broadcast.broadcasted((x,y) -> x .+ y, data2, Ref(data1))))
    check_getindex(@inferred(layer1 .- layer2)::LazyLayeredArray{2}, copy(Broadcast.broadcasted((x,y) -> x .- y, Ref(data1), data2)))
    check_getindex(@inferred(layer2 .- layer1)::LazyLayeredArray{2}, copy(Broadcast.broadcasted((x,y) -> x .- y, data2, Ref(data1))))
    @test_throws Exception layer1 + layer2
    @test_throws Exception layer2 + layer1
    @test_throws Exception layer1 - layer2
    @test_throws Exception layer2 - layer1
    # layer = 0 and 1
    check_getindex(@inferred(layer1′ .* layer1)::LazyLayeredArray{1}, data1′ .* data1)
    check_getindex(@inferred(layer1 .* layer1′)::LazyLayeredArray{1}, data1 .* data1′)
    check_getindex(@inferred(layer1′ ./ layer1)::LazyLayeredArray{1}, data1′ ./ data1)
    check_getindex(@inferred(layer1 ./ layer1′)::LazyLayeredArray{1}, data1 ./ data1′)
    check_getindex(@inferred(layer1′ .+ layer1)::LazyLayeredArray{1}, data1′ .+ data1)
    check_getindex(@inferred(layer1 .+ layer1′)::LazyLayeredArray{1}, data1 .+ data1′)
    check_getindex(@inferred(layer1′ .- layer1)::LazyLayeredArray{1}, data1′ .- data1)
    check_getindex(@inferred(layer1 .- layer1′)::LazyLayeredArray{1}, data1 .- data1′)
    # layer = 0 and 2
    check_getindex(@inferred(layer1′ .* layer2)::LazyLayeredArray{2}, copy(Broadcast.broadcasted(*, Ref(data1′), data2)))
    check_getindex(@inferred(layer2 .* layer1′)::LazyLayeredArray{2}, copy(Broadcast.broadcasted(*, data2, Ref(data1′))))
    @test_throws Exception layer1′ + layer2
    @test_throws Exception layer2 + layer1′
    @test_throws Exception layer1′ - layer2
    @test_throws Exception layer2 - layer1′
    # custom functions
    check_getindex(@inferred(broadcast(myfunc, layer1, 2, layer1′))::LazyLayeredArray{1}, [myfunc(data1[i], 2, data1′[i]) for i in eachindex(data1, data1′)])
    check_getindex(@inferred(broadcast(myfunc, layer1′, 2, layer1′'))::LazyLayeredArray{1}, [myfunc(data1′[i], 2, data1′[j]) for i in eachindex(data1′), j in eachindex(data1′)])
    check_getindex(@inferred(broadcast(myfunc, layer1, 2, layer2))::LazyLayeredArray{2}, [[myfunc(x1, 2, x2) for x1 in data1] for x2 in data2])
    # other complicated cases
    check_getindex(@inferred(broadcast(sum, layer1 .* layer2))::LazyLayeredArray{2}, [sum([x1 * x2 for x1 in data1]) for x2 in data2])
    check_getindex(@inferred(broadcast(sum, layer1′ .* layer2))::LazyLayeredArray{2}, [sum([x0 * x2 for x0 in data1′]) for x2 in data2])
    # recursive version
    d0 = [layer1′, layer1′, layer1′]
    d1 = [layer1, layer1, layer1]
    x0 = LayeredArray{2}(d0)
    x1 = LayeredArray{2}(d1)
    check_getindex(@inferred(broadcast(sum, @. 2 * x0 * x1))::LazyLayeredArray{2}, [sum([(2 * d0[i][j] * d1[i][j]) for j in 1:length(d0[i])]) for i in 1:length(d0)])
end
