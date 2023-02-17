using Colors
import ImageShow

Base.summary(io::IO, t::Tiling) = print(io, t.N, "-order ", typeof(t))

function to_img(t::Tiling)
    img = fill(colorant"transparent", inds(t.N))
    foreach(faces(t)) do (i, j, isdotted)
        if t[i, j] == UP
            col = isdotted ? colorant"red" : colorant"green"
            img[i, j] = img[i+1, j] = col
        elseif t[i, j] == RIGHT
            col = isdotted ? colorant"yellow" : colorant"blue"
            img[i, j] = img[i, j+1] = col
        end
    end
    img
end

Base.showable(::MIME"image/png", (; N)::Tiling) = N > 0

function Base.show(io::IO, ::MIME"image/png", t::Tiling; kw...)
    io = IOContext(io, :full_fidelity => true)
    img = to_img(adapt(Array, t))
    show(io, MIME("image/png"), img; kw...)
end
