function dr_path(t::Tiling, offset::Int = 0)
    (; x, N) = t
    y = OffsetVector{Float64}(undef, (-N + offset):(N - offset))
    y[begin] = -0.5 - offset
    prev = UP
    i = -1 - offset
    for j in (1 - N + offset):(N - offset)
        @assert checkbounds(Bool, t, i + 1, j)
        tile = x[i + 1, j]
        if prev == RIGHT
            y[j] = i + 0.5
        elseif tile == UP
            i += 1
            y[j] = i + 0.5
        elseif tile == RIGHT
            y[j] = i + 0.5
        else
            if prev == UP
                y[j] = i - 0.5
                i -= 1
            else
                i -= 1
                y[j] = i + 0.5
            end
        end
        prev = tile
    end
    return y
end
