
using EasyMLCore, Test

mutable struct Dummy1<:AbstractEasyML
    a::RefValue{Int64}
    b::Int64
end
dummy1 = Dummy1(Ref(1),1)

mutable struct Dummy2<:AbstractEasyML
    a::RefValue{Int64}
    b::Int64
end
dummy2 = Dummy2(Ref(2),2)

@testset "Accessing fields" begin
    @test dummy1.a isa Int64
    @test dummy1.b isa Int64
end

@testset "Binding" begin
    bind!(dummy1,dummy2)
    @test dummy1.a === dummy2.a
    @test !(dummy1.b === dummy2.b)
end

