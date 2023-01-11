using Colors
import ImageShow

function to_img(t::Tiling)
    img = fill(colorant"transparent", inds(t.N))
    foreach(faces(t)) do (i, j, isdotted)
        if t[i, j] == UP
            col = isdotted ? colorant"red" : colorant"yellow"
            img[i, j] = img[i+1, j] = col
        elseif t[i, j] == RIGHT
            col = isdotted ? colorant"green" : colorant"blue"
            img[i, j] = img[i, j+1] = col
        end
    end
    img
end

Base.showable(::MIME"image/png", (; N)::Tiling) = N > 0

function Base.show(io::IO, ::MIME"image/png", t::Tiling; kw...)
    show(io, MIME("image/png"), to_img(t); kw...)
end
