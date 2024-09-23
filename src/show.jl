using Colors
import ImageShow
using Base64: Base64EncodePipe

Base.summary(io::IO, t::Tiling) = print(io, t.N, "-order ", typeof(t))

function to_img(t::Tiling)
    img = fill(colorant"transparent", inds(t.N))
    foreach(faces(t)) do (i, j, isdotted)
        if t[i, j] == UP
            col = isdotted ? colorant"red" : colorant"green"
            img[i, j] = img[i + 1, j] = col
        elseif t[i, j] == RIGHT
            col = isdotted ? colorant"yellow" : colorant"blue"
            img[i, j] = img[i, j + 1] = col
        end
    end
    img
end

function Base.show(io::IO, (; N, x)::Tiling)
    print(io, "Tiling(", N)
    if N > 0
        print(io, ", ")
        Base._show_nonempty(IOContext(io, :compact => true), parent(x), "")
    end
    print(io, ")")
end

function Base.show(io::IO, ::MIME"text/plain", t::Tiling)
    summary(io, t)
    (; N) = t
    if displaysize(io)[2] < 4N
        printstyled(
            io, "\n  Output too large to fit terminal. \
            Use `using ImageView; imshow(AztecDiamonds.to_img(D))` to display as an image instead.";
            color = :black,
        )
        return nothing
    end
    t = adapt(Array, t)
    foreach(Iterators.product(inds(N)...)) do (j, i)
        j == 1 - N && println(io)
        isdotted = isodd(i + j - N)
        if get(t, (i, j), NONE) == UP
            color = isdotted ? :red : :green
            if get(t, (i - 1, j), NONE) == UP
                print(io, "UU")
            elseif get(t, (i, j - 1), NONE) == RIGHT
                print(io, "UR")
            else
                printstyled(io, "🬦🬓"; color)
            end
        elseif get(t, (i - 1, j), NONE) == UP
            color = !isdotted ? :red : :green
            if get(t, (i, j - 1), NONE) == RIGHT
                print(io, "NR")
            elseif get(t, (i, j), NONE) == RIGHT
                print(io, "RU")
            else
                printstyled(io, "🬉🬄"; color)
            end
        elseif get(t, (i, j), NONE) == RIGHT
            color = isdotted ? :yellow : :blue
            if get(t, (i, j - 1), NONE) == RIGHT
                print(io, "RR")
            else
                printstyled(io, "🬇🬋"; color)
            end
        elseif get(t, (i, j - 1), NONE) == RIGHT
            color = !isdotted ? :yellow : :blue
            printstyled(io, "🬋🬃"; color)
        else
            print(io, "  ")
        end
    end
end

Base.showable(::MIME"image/png", (; N)::Tiling) = N > 0

function Base.show(io::IO, ::MIME"image/png", t::Tiling; kw...)
    io = IOContext(io, :full_fidelity => true)
    img = to_img(adapt(Array, t))
    show(io, MIME("image/png"), img; kw...)
end

Base.showable(::MIME"juliavscode/html", (; N)::Tiling) = N > 0

function Base.show(io::IO, ::MIME"juliavscode/html", t::Tiling; kw...)
    img = to_img(adapt(Array, t))
    print(io, "<img src='data:image/gif;base64,")
    b64_io = IOContext(Base64EncodePipe(io), :full_fidelity => true)
    show(b64_io, MIME("image/png"), img; kw...)
    close(b64_io)
    print(io, "' style='width: 100%; max-height: 500px; object-fit: contain; image-rendering: pixelated' />")
end
