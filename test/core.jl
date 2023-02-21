@testset "core" begin
    D = diamond(100)
    @test verify_tiling(D)

    dr = dr_path(D)
    @test dr[end] == -0.5
end

@testset "Tiling" begin
    D = diamond(100)
    D′ = copy(D)

    @test D′ == D
    @test isequal(D′, D)
    @test hash(D′) == hash(D)

    D[0, 0] = NONE
    @test D[0, 0] == NONE
    @test_throws BoundsError D[51, 51]
    @test_throws BoundsError D[-51, -51]
    @test_throws BoundsError D[51, 51] = NONE
end

using AztecDiamonds: DiamondFaces

@testset "DiamondFaces" begin
    df = DiamondFaces(10)
    df′ = foldl(vcat, df; init=Union{}[])

    @test length(df) == length(df′)
    @test eltype(df) == eltype(df′)
    @test length(df′[1]) == 3
end

@testset "KernelAbstractions CPU" begin
    D = ka_diamond(100, Array)
    @test verify_tiling(D)
end
