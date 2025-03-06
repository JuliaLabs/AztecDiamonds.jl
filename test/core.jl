@testitem "core" begin
    include("verify_tiling.jl")

    D = diamond(100)
    @test verify_tiling(D)

    dr = dr_path(D)
    @test dr[end] == -0.5

    dr = dr_path(D, 10)
    @test dr[end] == -10.5
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
    df′ = foldl(vcat, df; init = Union{}[])

    @test length(df) == length(df′)
    @test eltype(df) == eltype(df′)
    @test length(df′[1]) == 3
end

@testitem "KernelAbstractions CPU" begin
    include("verify_tiling.jl")

    D = ka_diamond(100, Array)
    @test verify_tiling(D)
end

@testitem "rotation of tilings" begin
    using Colors: @colorant_str, RGBA, N0f8
    include("verify_tiling.jl")
    _to_img(D) = parent(AztecDiamonds.to_img(D))

    D = diamond(100)

    @testset "$rot" for (rot, replacements) in (
            (
                rotr90, Pair{RGBA{N0f8}, RGBA{N0f8}}[
                    colorant"red" => colorant"yellow",
                    colorant"yellow" => colorant"green",
                    colorant"green" => colorant"blue",
                    colorant"blue" => colorant"red",
                ],
            ),
            (
                rotl90, Pair{RGBA{N0f8}, RGBA{N0f8}}[
                    colorant"red" => colorant"blue",
                    colorant"blue" => colorant"green",
                    colorant"green" => colorant"yellow",
                    colorant"yellow" => colorant"red",
                ],
            ),
            (
                rot180, Pair{RGBA{N0f8}, RGBA{N0f8}}[
                    colorant"red" => colorant"green",
                    colorant"green" => colorant"red",
                    colorant"blue" => colorant"yellow",
                    colorant"yellow" => colorant"blue",
                ],
            ),
        )
        D′ = rot(D)
        @test verify_tiling(D′)
        @test _to_img(D′) == replace(rot(_to_img(D)), replacements...)
    end
end

@testitem "JET" begin
    using JET

    @test_opt diamond(10)
    D = diamond(10)
    @test_opt dr_path(D)
    @test_opt AztecDiamonds.to_img(D)
    @test_call show(stdout, MIME("text/plain"), D)
end
