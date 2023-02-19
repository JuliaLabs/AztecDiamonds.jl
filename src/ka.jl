using KernelAbstractions

# destruction
function remove_bad_blocks_kernel!(t::Tiling)
    (; N) = t
    i, j = @index(Global, NTuple) .- N

    @inbounds if in_diamond(N, i, j) && isblock(t, i, j, Val(false))
        if t[i, j] == UP
            t[i, j+1] = NONE
        else
            t[i+1, j] = NONE
        end
        t[i, j] = NONE
    end

    nothing
end

# sliding
function slide_tiles_kernel!(t′::Tiling, @Const(t::Tiling))
    (; N) = t
    i, j = @index(Global, NTuple) .- N

    @inbounds if in_diamond(N, i, j)
        tile = @inbounds t[i, j]
        isdotted = isodd(i+j-N)
        inc = ifelse(isdotted, -1, 1)
        @inbounds if tile == UP
            t′[i, j+inc] = UP
        elseif tile == RIGHT
            t′[i+inc, j] = RIGHT
        end
    end

    nothing
end

function fill_empty_blocks_kernel!(t′::Tiling, scratch::OffsetMatrix)
    (; N) = t′
    i, j = @index(Global, NTuple) .- N

    @inbounds if in_diamond(N, i, j)
        if t′[i, j] == NONE && get(t′, (i-1, j), NONE) != UP && get(t′, (i, j-1), NONE) != RIGHT
            should_fill = true
            i′ = i - 1
            while checkbounds(Bool, t′, i′, j)
                if t′[i′, j] == NONE && get(t′, (i′-1, j), NONE) != UP && get(t′, (i′, j-1), NONE) != RIGHT
                    should_fill ⊻= true
                    i′ -= 1
                else
                    break
                end
            end
            should_fill || return
            j′ = j - 1
            while checkbounds(Bool, t′, i, j′)
                if t′[i, j′] == NONE && get(t′, (i-1, j′), NONE) != UP && get(t′, (i, j′-1), NONE) != RIGHT
                    should_fill ⊻= true
                    j′ -= 1
                else
                    break
                end
            end
            if should_fill
                scratch[i, j] = SHOULD_FILL
            end
        end

        @synchronize

        if scratch[i, j] == SHOULD_FILL
            if rand(Bool)
                t′[i, j] = t′[i, j+1] = UP
            else
                t′[i, j] = t′[i+1, j] = RIGHT
            end
        end
    end
    return t′
end
