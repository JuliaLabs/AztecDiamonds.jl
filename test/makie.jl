@testitem "Makie" begin
    using CairoMakie

    D = diamond(100)

    f = Figure()
    ax = Axis(f[1, 1]; aspect = 1)
    plot!(ax, D; domino_padding = 0.05f0, domino_stroke = 1, show_arrows = true)

    path = tempname() * ".png"
    save(path, f)
    @test isfile(path)
    @test filesize(path) > 1024 # 1 kiB

    using JET
    @test_opt Base.get_extension(AztecDiamonds, :MakieExtension).prepare_plot(D)
end
