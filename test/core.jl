@testset "core" begin
    D = diamond(100)
    @test verify_tiling(D)

    dr = dr_path(D)
    @test dr[end] == -0.5
end
