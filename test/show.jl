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
    @test summary(Tiling(2)) == "Order-2 $Tiling{Matrix{AztecDiamonds.Edge}}"
    @test repr(Tiling(1)) == "Tiling(1, [NONE NONE; NONE NONE])"

    N = 20
    D = diamond(N)
    r = repr(MIME("text/plain"), D)
    @test length(r) == 2537
    r_color = repr(MIME("text/plain"), D; context = :color => true)
    @test length(r_color) == length(r) + 10length(AztecDiamonds.faces(D))

    r = repr(MIME("text/plain"), D; context = :displaysize => (10, 10))
    @test contains(r, "Output too large to fit terminal")
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

    # TODO: should
    expected = replace(
        """
        Order-4 $Tiling{Matrix{AztecDiamonds.Edge}}
              🬦🬓  \\
              UU    \\
              🬉🬄      \\
        🬇🬋UR  🬦🬓🬦🬓      \\
          🬉🬄🬇🬋NRRU🬋🬃    \\
            🬇🬋RR🬋🬃    \\
                    \\
                  """,
        "\\" => ""
    )
    @test repr(MIME("text/plain"), t) == expected
end

@testitem "VSCode show" begin
    using Base64

    D = diamond(20)
    @test Base.showable("juliavscode/html", D)
    html = String(repr("juliavscode/html", D))
    b64_png = stringmime("image/png", D)
    @test contains(html, b64_png)
end
