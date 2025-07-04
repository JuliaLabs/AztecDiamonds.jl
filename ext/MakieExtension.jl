module MakieExtension

using Makie
using GeometryBasics: Vec2f, Point2f, Rect2f
using Colors
using Adapt: adapt

using AztecDiamonds: Tiling, faces, UP, RIGHT
import AztecDiamonds: tilingplot, tilingplot!

function prepare_plot(t::Tiling, pad = 0.1f0)
    tiles = Rect2f[]
    colors = RGB{Colors.N0f8}[]
    arrow_pts, arrows = Point2f[], Vec2f[]
    foreach(faces(t)) do (i, j, isdotted)
        if t[i, j] == UP
            r = Rect2f(j - 1 + pad, i - 1 + pad, 1 - 2pad, 2 - 2pad)
            col = isdotted ? colorant"red" : colorant"green"
            push!(tiles, r)
            push!(colors, col)
            off = isdotted ? -0.3f0 : 0.3f0
            push!(arrow_pts, Point2f(j - 0.5f0 - off, i))
            push!(arrows, Point2f(isdotted ? -0.5f0 : 0.5f0, 0))
        elseif t[i, j] == RIGHT
            r = Rect2f(j - 1 + pad, i - 1 + pad, 2 - 2pad, 1 - 2pad)
            col = isdotted ? colorant"yellow" : colorant"blue"
            push!(tiles, r)
            push!(colors, col)
            off = isdotted ? -0.3f0 : 0.3f0
            push!(arrow_pts, Point2f(j, i - 0.5f0 - off))
            push!(arrows, Point2f(0, isdotted ? -0.5f0 : 0.5f0))
        end
    end
    return tiles, colors, arrow_pts, arrows
end

@recipe(TilingPlot, t) do scene
    Attributes(
        show_arrows = false,
        domino_padding = 0.1f0,
        domino_stroke = 0,
    )
end

Makie.plottype(::Tiling) = TilingPlot

function Makie.plot!(x::TilingPlot{<:Tuple{Tiling}})
    map!(t -> adapt(Array, t), x.attributes, [:t], :t_cpu)
    map!(prepare_plot, x.attributes, [:t_cpu, :domino_padding], [:tiles, :color, :arrow_pts, :arrows])
    poly!(x, x.tiles; x.color, strokewidth = x.domino_stroke)
    arrows!(x, x.arrow_pts, x.arrows; visible = x.show_arrows)
    return x
end

end
