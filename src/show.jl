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

function Base.show(io::IO, t::Tiling)
    summary(io, t)
    (; N) = t
    displaysize(io)[2] ≥ 4N || return print(io, "\n  Output too large to fit terminal. Use \
        `using ImageView; imshow(AztecDiamonds.to_img(D))` to display as an image instead.")
    t = adapt(Array, t)
    foreach(Iterators.product(inds(N)...)) do (j, i)
        j == 1-N && println(io)
        isdotted = isodd(i+j-N)
        if get(t, (i, j), NONE) == UP
            color = isdotted ? :red : :green
            if get(t, (i-1, j), NONE) == UP
                print(io, 'a')
            elseif get(t, (i, j-1), NONE) == RIGHT
                print(io, 'b')
            else
                printstyled(io, "🬦🬓"; color)
            end
        elseif get(t, (i-1, j), NONE) == UP
            color = !isdotted ? :red : :green
            if get(t, (i, j-1), NONE) == RIGHT
                print(io, 'c')
            else
                printstyled(io, "🬉🬄"; color)
            end
        elseif get(t, (i, j), NONE) == RIGHT
            color = isdotted ? :yellow : :blue
            if get(t, (i-1, j), NONE) == UP
                print(io, 'd')
            elseif get(t, (i, j-1), NONE) == RIGHT
                print(io, 'e')
            else
                printstyled(io, "🬇🬋"; color)
            end
        elseif get(t, (i, j-1), NONE) == RIGHT
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
