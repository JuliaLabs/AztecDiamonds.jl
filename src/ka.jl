using KernelAbstractions

# destruction
@kernel function remove_bad_blocks_kernel!(t::Tiling)
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
end

# sliding
@kernel function slide_tiles_kernel!(t′::Tiling, @Const(t::Tiling))
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
end

@kernel function fill_empty_blocks_kernel1!(t′::Tiling, scratch::OffsetMatrix)
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
            should_fill || @goto foo
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
    end
    @label foo
end

@kernel function fill_empty_blocks_kernel2!(t′::Tiling, scratch::OffsetMatrix)
    (; N) = t′
    i, j = @index(Global, NTuple) .- N

    @inbounds if in_diamond(N, i, j)
        if scratch[i, j] == SHOULD_FILL
            if rand(Bool)
                t′[i, j] = t′[i, j+1] = UP
            else
                t′[i, j] = t′[i+1, j] = RIGHT
            end
        end
    end
end

@kernel function zero_kernel!(t::Tiling, N)
    i, j = @index(Global, NTuple) .- N
    @inbounds t.x[i, j] = NONE
end

function ka_diamond!(t, t′, N; dev)
    zero! = zero_kernel!(dev)
    remove_bad_blocks! = remove_bad_blocks_kernel!(dev)
    slide_tiles! = slide_tiles_kernel!(dev)
    fill_empty_blocks1! = fill_empty_blocks_kernel1!(dev)
    fill_empty_blocks2! = fill_empty_blocks_kernel2!(dev)
    ev = Event(dev)

    ndrange = (0, 0)
    for N in 1:N
        N > 1 && (ev = zero!(t′, N-1; ndrange, dependencies=(ev,)))
        t′ = Tiling(N, t′.x)
        if N > 1
            ev = remove_bad_blocks!(t; ndrange, dependencies=(ev,))
            ev = slide_tiles!(t′, t; ndrange, dependencies=(ev,))
        end
        ndrange = (2N, 2N)
        ev = fill_empty_blocks1!(t′, t.x; ndrange, dependencies=(ev,))
        ev = fill_empty_blocks2!(t′, t.x; ndrange, dependencies=(ev,))
        t, t′ = t′, t
    end
    wait(ev)
    return t
end

function ka_diamond(N, Backend)
    mem = ntuple(_ -> Backend.fill(NONE, 2N, 2N), 2)
    t, t′ = map(x -> Tiling(0, OffsetMatrix(x, inds(N))), mem)
    return ka_diamond!(t, t′, N; dev=KernelAbstractions.get_device(mem[1]))
end
