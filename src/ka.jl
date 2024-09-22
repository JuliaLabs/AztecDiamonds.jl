using KernelAbstractions, Adapt

Adapt.adapt_structure(to, (; N, x)::Tiling) = Tiling(N, adapt(to, x))
KernelAbstractions.get_backend((; x)::Tiling) = KernelAbstractions.get_backend(x)

# destruction
@kernel function remove_bad_blocks_kernel!(t::Tiling)
    (; N) = t
    I = @index(Global, NTuple)
    i, j = I .- N

    @inbounds if in_diamond(N, i, j) && isblock(t, i, j, Val(false))
        if t[i, j] == UP
            t[i, j + 1] = NONE
        else
            t[i + 1, j] = NONE
        end
        t[i, j] = NONE
    end
end

# sliding
@kernel function slide_tiles_kernel!(t′::Tiling, @Const(t::Tiling))
    (; N) = t
    I = @index(Global, NTuple)
    i, j = I .- N

    @inbounds if in_diamond(N, i, j)
        tile = @inbounds t[i, j]
        isdotted = isodd(i + j - N)
        inc = ifelse(isdotted, -1, 1)
        @inbounds if tile == UP
            t′[i, j + inc] = UP
        elseif tile == RIGHT
            t′[i + inc, j] = RIGHT
        end
    end
end

# filling
@kernel function fill_empty_blocks_kernel1!(t′::Tiling, scratch::OffsetMatrix)
    (; N) = t′
    I = @index(Global, NTuple)
    i, j = I .- N

    @inbounds if in_diamond(N, i, j) && is_empty_tile(t′, i, j)
        should_fill = true
        i′ = i - 1
        while in_diamond(N, i′, j) && is_empty_tile(t′, i′, j)
            should_fill ⊻= true
            i′ -= 1
        end
        should_fill || @goto ret
        j′ = j - 1
        while in_diamond(N, i, j′) && is_empty_tile(t′, i, j′)
            should_fill ⊻= true
            j′ -= 1
        end
        if should_fill
            scratch[i, j] = SHOULD_FILL
        end
    end
    @label ret
end

@kernel function fill_empty_blocks_kernel2!(t′::Tiling, scratch::OffsetMatrix)
    (; N) = t′
    I = @index(Global, NTuple)
    i, j = I .- N

    @inbounds if in_diamond(N, i, j)
        if scratch[i, j] == SHOULD_FILL
            if rand(Bool)
                t′[i, j] = t′[i, j + 1] = UP
            else
                t′[i, j] = t′[i + 1, j] = RIGHT
            end
        end
    end
end

@kernel function zero_kernel!(t::Tiling, N)
    I = @index(Global, NTuple)
    i, j = I .- N
    @inbounds t.x[i, j] = NONE
end

function ka_diamond!(t, t′, N; backend)
    zero! = zero_kernel!(backend)
    remove_bad_blocks! = remove_bad_blocks_kernel!(backend)
    slide_tiles! = slide_tiles_kernel!(backend)
    fill_empty_blocks1! = fill_empty_blocks_kernel1!(backend)
    fill_empty_blocks2! = fill_empty_blocks_kernel2!(backend)

    t′ = Tiling(1, t′.x)
    ndrange = (2, 2)
    fill_empty_blocks1!(t′, t.x; ndrange)
    fill_empty_blocks2!(t′, t.x; ndrange)
    t, t′ = t′, t

    for N in 2:N
        zero!(t′, N - 1; ndrange)
        t′ = Tiling(N, t′.x)

        remove_bad_blocks!(t; ndrange)
        slide_tiles!(t′, t; ndrange)

        ndrange = (2N, 2N)
        fill_empty_blocks1!(t′, t.x; ndrange)
        fill_empty_blocks2!(t′, t.x; ndrange)
        t, t′ = t′, t
    end
    return t
end

function ka_diamond(N, ArrayT)
    mem = ntuple(_ -> fill!(ArrayT{Edge}(undef, 2N, 2N), NONE), 2)
    t, t′ = map(x -> Tiling(0, OffsetMatrix(x, inds(N))), mem)
    return ka_diamond!(t, t′, N; backend = KernelAbstractions.get_backend(mem[1]))
end

# rotation of tilings

@kernel function rotr90_kernel!(t′::Tiling, @Const(t::Tiling))
    (; N) = t
    I = @index(Global, NTuple)
    i, j = I .- N

    edge = NONE
    if @inbounds t.x[i, j] == RIGHT
        edge = UP
    elseif get(t, (i - 1, j), NONE) == UP
        edge = RIGHT
    end
    @inbounds t′.x[j, 1 - i] = edge
end

@kernel function rotl90_kernel!(t′::Tiling, @Const(t::Tiling))
    (; N) = t
    I = @index(Global, NTuple)
    i, j = I .- N

    edge = NONE
    if @inbounds t.x[i, j] == UP
        edge = RIGHT
    elseif get(t, (i, j - 1), NONE) == RIGHT
        edge = UP
    end
    @inbounds t′.x[1 - j, i] = edge
end

@kernel function rot180_kernel!(t′::Tiling, @Const(t::Tiling))
    (; N) = t
    I = @index(Global, NTuple)
    i, j = I .- N

    edge = NONE
    if get(t, (i - 1, j), NONE) == UP
        edge = UP
    elseif get(t, (i, j - 1), NONE) == RIGHT
        edge = RIGHT
    end
    @inbounds t′.x[1 - i, 1 - j] = edge
end

for rot in Symbol.(:rot, ["r90", "l90", "180"])
    @eval function Base.$rot(t::Tiling)
        (; N, x) = t
        t′ = Tiling(N, similar(x))
        backend = KernelAbstractions.get_backend(t)
        $(Symbol(rot, :_kernel!))(backend)(t′, t; ndrange = (2N, 2N))
        return t′
    end
end
