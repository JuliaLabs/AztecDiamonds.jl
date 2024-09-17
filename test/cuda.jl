using Adapt, CUDA

@testset "CUDA" begin
    D = ka_diamond(200, CuArray)
    D_cpu = adapt(Array, D)
    @test verify_tiling(D_cpu)
end
