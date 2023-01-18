using MakieCore
using GeometryBasics: Vec2f, Point2f, Rect2f

function prepare_plot(t::Tiling; pad=.1f0)
    tiles = Rect2f[]
    colors = RGB{Colors.N0f8}[]
    arrow_pts, arrows = Point2f[], Vec2f[]
    foreach(faces(t)) do (i, j, isdotted)
        if t[i, j] == UP
            r = Rect2f(j-1+pad, i-1+pad, 1-2pad, 2-2pad)
            col = isdotted ? colorant"red" : colorant"green"
            push!(tiles, r)
            push!(colors, col)
            off = isdotted ? -.3f0 : .3f0
            push!(arrow_pts, Point2f(j-.5f0-off, i))
            push!(arrows, Point2f(isdotted ? -.5f0 : .5f0, 0))
        elseif t[i, j] == RIGHT
            r = Rect2f(j-1+pad, i-1+pad, 2-2pad, 1-2pad)
            col = isdotted ? colorant"yellow" : colorant"blue"
            push!(tiles, r)
            push!(colors, col)
            off = isdotted ? -.3f0 : .3f0
            push!(arrow_pts, Point2f(j, i-.5f0-off))
            push!(arrows, Point2f(0, isdotted ? -.5f0 : .5f0))
        end
    end
    tiles, colors, arrow_pts, arrows
end

MakieCore.@recipe(TilingPlot, t) do scene
    MakieCore.Attributes(
        show_arrows = false,
        domino_padding = 0.1f0,
        domino_stroke = 0,
    )
end

MakieCore.plottype(::Tiling) = TilingPlot

function MakieCore.plot!(x::TilingPlot{<:Tuple{Tiling}})
    t = x[:t][]
    tiles, colors, arrow_pts, arrows = prepare_plot(t; pad=x.domino_padding[])
    poly!(x, tiles; color=colors, strokewidth=x.domino_stroke, axis=(; aspect=1))
    x.show_arrows[] && arrows!(x, arrow_pts, arrows)
    x
end
