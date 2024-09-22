function dr_path(t::Tiling)
    (; x, N) = t
    y = OffsetVector{Float64}(undef, -N:N)
    y[-N] = -0.5
    prev = UP
    i = -1
    for j in (1 - N):N
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
