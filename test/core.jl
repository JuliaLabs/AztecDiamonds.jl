@testitem "core" begin
    include("setup.jl")

    D = diamond(100)
    @test verify_tiling(D)

    dr = dr_path(D)
    @test dr[end] == -0.5
end

@testitem "Tiling" begin
    using AztecDiamonds: NONE

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


@testitem "DiamondFaces" begin
    using AztecDiamonds: DiamondFaces

    df = DiamondFaces(10)
    df′ = foldl(vcat, df; init=Union{}[])

    @test length(df) == length(df′)
    @test eltype(df) == eltype(df′)
    @test length(df′[1]) == 3
end

@testitem "KernelAbstractions CPU" begin
    include("setup.jl")

    D = ka_diamond(100, Array)
    @test verify_tiling(D)
end
