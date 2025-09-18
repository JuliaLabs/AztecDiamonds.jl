@testitem "CUDA" tags = [:cuda] begin
    include("verify_tiling.jl")
    using CUDA, Adapt

    D = ka_diamond(200, CuArray)
    D_cpu = adapt(Array, D)
    @test verify_tiling(D_cpu)
    @test AztecDiamonds.to_img(D) isa Matrix

    @testset "$rot" for rot in (rotr90, rotl90, rot180)
        D′ = rot(D)
        D_cpu′ = adapt(Array, D′)
        @test verify_tiling(D_cpu′)
        @test D_cpu′ == rot(D_cpu)
    end
end
