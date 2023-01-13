using Adapt

@testset "CUDA" begin
    D = cuda_diamond(200)
    D_cpu = adapt(Array, D)
    @test verify_tiling(D_cpu)
end
