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

    N = 20
    D = diamond(N)
    r = repr(D)
    @test length(r) > 2(2N)^2
    r_color = repr(D; context=:color=>true)
    @test length(r_color) == length(r) + 10length(AztecDiamonds.faces(D))
end
