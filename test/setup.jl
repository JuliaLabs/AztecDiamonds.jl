using AztecDiamonds: inds, NONE, UP, RIGHT

function verify_tiling(t::Tiling)
    (; N, x) = t
    for (i, j) in Iterators.product(inds(N)...)
        if checkbounds(Bool, t, i, j)
            if t[i, j] == NONE && get(t, (i-1, j), NONE) != UP && get(t, (i, j-1), NONE) != RIGHT
                error("Square ($i, $j) is not covered by any tile!")
            end
        else
            if x[i, j] != NONE
                error("Square ($i, $j) should be empty, is $(x[i, j])")
            end
            if get(x, CartesianIndex(i-1, j), NONE) == UP
                error("Square ($i, $j) should be empty, is covered from below by ($(i-1), $j)")
            end
            if get(x, CartesianIndex(i, j-1), NONE) == RIGHT
                error("Square ($i, $j) should be empty, is covered from the left by ($i, $(j-1))")
            end
        end
    end
    return true
end
