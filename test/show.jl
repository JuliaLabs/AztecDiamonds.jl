using Images

@testset "image show" begin
    D = diamond(100)
    @test Base.showable("image/png", D)
    @test repr("image/png", D) isa Vector{UInt8}

    img = AztecDiamonds.to_img(D)
    @test img isa AbstractMatrix{<:Colorant}
    @test axes(img) == (-99:100, -99:100)

    @test !Base.showable("image/png", Tiling(0))
end

@testset "summary" begin
    @test summary(Tiling(2)) == "2-order Tiling{Matrix{AztecDiamonds.Edge}}"
end
