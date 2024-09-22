@testitem "image show" begin
    using Images

    D = diamond(100)
    @test Base.showable("image/png", D)
    @test repr("image/png", D) isa Vector{UInt8}

    img = AztecDiamonds.to_img(D)
    @test img isa AbstractMatrix{<:Colorant}
    @test axes(img) == (-99:100, -99:100)

    @test !Base.showable("image/png", Tiling(0))
end

@testitem "pretty printing" begin
    @test summary(Tiling(2)) == "2-order $Tiling{Matrix{AztecDiamonds.Edge}}"
    @test repr(Tiling(1)) == "Tiling(1, [NONE NONE; NONE NONE])"

    N = 20
    D = diamond(N)
    r = repr(MIME("text/plain"), D)
    @test length(r) > 2(2N)^2
    r_color = repr(MIME("text/plain"), D; context = :color => true)
    @test length(r_color) == length(r) + 10length(AztecDiamonds.faces(D))
end

@testitem "printing of malformed tilings" begin
    using AztecDiamonds: Tiling, UP, RIGHT

    t = Tiling(4)
    t[-3, 0] = UP
    t[-2, 0] = UP

    t[0, -3] = RIGHT
    t[0, -2] = UP

    t[0, 0] = UP
    t[1, -1] = RIGHT

    t[0, 1] = UP
    t[1, 1] = RIGHT

    t[2, -1] = RIGHT
    t[2, 0] = RIGHT

    expected = replace(
        """
        4-order $Tiling{Matrix{AztecDiamonds.Edge}}
              🬦🬓        \\
              UU        \\
              🬉🬄        \\
        🬇🬋UR  🬦🬓🬦🬓      \\
          🬉🬄🬇🬋NRRU🬋🬃    \\
            🬇🬋RR🬋🬃      \\
                        \\
                        """,
        "\\" => ""
    )
    @test repr(MIME("text/plain"), t) == expected
end
