using AztecDiamonds, OffsetArrays
using AztecDiamonds: Edge, UP, RIGHT, NONE
using ImageShow, Colors, Adapt
using Base64: Base64EncodePipe

struct DiagonalTiling{M <: AbstractMatrix{UInt8}}
    N::Int
    x::M
end

module Node
    struct T
        x::UInt8
    end
    Base.UInt8((; x)::T) = x
    const EMPTY = T(0x00)
    const (v) = T(0x01)
    const (^) = T(0x02)
    const (<) = T(0x03)
    const (>) = T(0x04)
end

Adapt.adapt_structure(to, (; N, x)::DiagonalTiling) = DiagonalTiling(N, adapt(to, x))

function to_img((; N, x)::DiagonalTiling)
    x′ = OffsetArray(similar(x, ARGB32, (2N, 2N)), (1 - N):N, (1 - N):N)
    fill!(x′, colorant"transparent")
    for I in CartesianIndices(x)
        i, j = Tuple(I)
        for k in 0:1
            i′ = j + k - i
            j′ = j - 1 + i - N
            node = Node.T((x[I] >> 4k) & 0x0f)
            if node == Node.:v# && checkbounds(Bool, x′, i′, j′)
                x′[i′, j′] = k == 0 ? colorant"red" : colorant"green"
            elseif node == Node.:^
                x′[i′, j′] = k == 0 ? colorant"green" : colorant"red"
            elseif node == Node.:<# && checkbounds(Bool, x′, i′, j′)
                x′[i′, j′] = k == 0 ? colorant"yellow" : colorant"blue"
            elseif node == Node.:>
                x′[i′, j′] = k == 0 ? colorant"blue" : colorant"yellow"
            elseif node != Node.EMPTY
                x′[i′, j′] = colorant"magenta"
            end
        end
    end
    return parent(x′)
end

function Base.show(io::IO, ::MIME"juliavscode/html", t::DiagonalTiling; kw...)
    img = to_img(adapt(Array, t))
    print(io, "<img src='data:image/gif;base64,")
    b64_io = IOContext(Base64EncodePipe(io), :full_fidelity => true)
    show(b64_io, MIME("image/png"), img; kw...)
    close(b64_io)
    print(io, "' style='width: 500px; max-height: 500px; object-fit: contain; image-rendering: pixelated' />")
    return nothing
end

function AztecDiamonds.Tiling((; N, x)::DiagonalTiling)
    x′ = OffsetArray(similar(x, Edge, (2N, 2N)), (1 - N):N, (1 - N):N)
    fill!(x′, NONE)
    for I in CartesianIndices(x)
        i, j = Tuple(I)
        for k in 0:1
            i′ = j + k - i
            j′ = j - 1 + i - N
            node = Node.T((x[I] >> 4k) & 0x0f)
            if node == Node.:v && checkbounds(Bool, x′, i′, j′)
                x′[i′, j′] = UP
            elseif node == Node.:< && checkbounds(Bool, x′, i′, j′)
                x′[i′, j′] = RIGHT
            end
        end
    end
    return Tiling(N, x′)
end

d = DiagonalTiling(
    2,
    [
        0x01 | (0x02 << 4) 0x01 | (0x02 << 4) 0x02
        0x03 | (0x03 << 4) 0x04 | (0x01 << 4) 0x02
        0x00 | (0x04 << 4) 0x00 | (0x01 << 4) 0x00
    ],
)

function DiagonalTiling((; N, x)::Tiling)
    x′ = similar(parent(x), UInt8, (N + 1, N + 1))
    fill!(x′, 0x00)
    for I in CartesianIndices(x′)
        i, j = Tuple(I)
        for k in 0:1
            i′ = j + k - i
            j′ = j - 1 + i - N
            checkbounds(Bool, x, i′, j′) || continue
            edge = x[i′, j′]
            if edge == UP
                x′[i, j] |= UInt8(Node.:v) << 4k
                x′[i - k, j + k] |= UInt8(Node.:^) << 4(1 - k)
            elseif edge == RIGHT
                x′[i, j] |= UInt8(Node.:<) << 4k
                x′[i + 1 - k, j + k] |= UInt8(Node.:>) << 4(1 - k)
            end
        end
    end
    return DiagonalTiling(N, x′)
end

using CUDA

@inline function shuffling_kernel!(x′, x, N, block_col = blockIdx().x, block_row = blockIdx().y)
    i = threadIdx().x + (block_col - 1) * (blockDim().x - 2)
    j = threadIdx().y + (block_row - 1) * (blockDim().y - 2)

    tmp = @cuDynamicSharedMem(UInt8, (blockDim().x + 2, 2 * blockDim().y + 1))
    k, l = threadIdx().x, threadIdx().y

    inbounds′ = i ≤ N + 1 && j ≤ N + 1
    @inbounds if k ≤ 2 || l ≤ 2
        t = inbounds′ ? x′[i, j] : 0x00
        tmp[k, 2l - 1] = t & 0x0f
        tmp[k, 2l] = t >> 4
        if k > 1 && l == 2
            if t >> 4 == 0x01 && k > 3
                tmp[k - 1, 2l + 1] = 0x02
            elseif t >> 4 == 0x03
                tmp[k, 2l + 1] = 0x04
            end
        elseif k == 2 && l > 1
            if t & 0x0f == 0x02
                tmp[k + 1, 2l - 2] = 0x01
            elseif t & 0x0f == 0x03
                tmp[k + 1, 2l] = 0x04
            end
        end
    end

    sync_threads()
    #inbounds′ && @inbounds CUDA.@atomic foo[i, j] |= tmp[k, 2l - 1] | (tmp[k, 2l] << 4)

    inbounds = i ≤ N && j ≤ N
    tile = inbounds ? @inbounds(x[i, j]) : 0x00

    offset = tile == 0x21 ? Int32(-1) : Int32(1)
    lane = (threadIdx().x - 1) % Int32(32)  # CUDA warp size is 32
    width = Int32(32)
    tile′ = shfl_sync(0xffffffff, tile, clamp(lane + offset, Int32(0), width - Int32(1)))

    @inbounds if tile == 0x21
        if tile′ & 0x0f != 0x02
            tmp[k, 2l - 1] = 0x01
            tmp[k, 2l] = 0x02
        end
    elseif tile != 0x44
        if tile & 0x0f == 0x02
            if tile′ != 0x21
                tmp[k + 1, 2l + 1] = 0x02
                tmp[k + 2, 2l] = 0x01
            end
        elseif tile & 0x0f == 0x04
            tmp[k, 2l] = 0x03
            tmp[k, 2l + 1] = 0x04
        end
        if tile >> 4 == 0x04
            tmp[k, 2l - 1] = 0x03
            tmp[k + 1, 2l] = 0x04
        end
    end

    sync_threads()

    should_fill = false
    t = @inbounds tmp[k, 2l - 1] | (tmp[k, 2l] << 4)
    @inbounds if inbounds && l < blockDim().y && k < blockDim().x
        for l in l:-1:1
            tmp[k, 2l - 1] == tmp[k, 2l] == 0x00 || break
            should_fill ⊻= true
        end
    end

    sync_threads()

    @inbounds if should_fill
        if rand(Bool)
            tmp[k, 2l - 1] = 0x01
            tmp[k, 2l] = 0x02
            tmp[k + 1, 2l] = 0x01
            tmp[k, 2l + 1] = 0x02
        else
            tmp[k, 2l - 1] = 0x03
            tmp[k, 2l] = 0x03
            tmp[k + 1, 2l] = 0x04
            tmp[k, 2l + 1] = 0x04
        end
    end

    sync_threads()

    if inbounds′
        if (block_col != 1 && k ≤ 1) || (block_row != 1 && l ≤ 1)
            #((blockIdx().x != 1 && k ≤ 2) || (blockIdx().y != 1 && l ≤ 2)) && t & 0x0f != 0x00 && t >> 4 != 0x00
            return nothing
        end
        @inbounds CUDA.@atomic x′[i, j] |= tmp[k, 2l - 1] | (tmp[k, 2l] << 4)
    end

    return nothing
end

function cooperative_shuffling_kernel!(x′, x, N, offset)
    block_row = blockIdx().x + offset
    ncols = cld(N + 1, blockDim().x - 2)
    nrows = cld(N + 1, blockDim().y - 2)

    for diag in 2:(ncols + nrows)
        block_col = diag - block_row
        if 1 ≤ block_col ≤ ncols && 1 ≤ block_row ≤ nrows
            #@cuprintf "Processing block (%d, %d)\n" block_col block_row
            shuffling_kernel!(x′, x, N, block_col, block_row)
        end
        CUDA.sync_grid()
    end

    return nothing
end


function DiagonalTiling(N::Int)
    x, x′ = CuArray{UInt8}(undef, N + 1, N + 1), CuArray{UInt8}(undef, N + 1, N + 1)
    warpsize = 32  # CUDA warp size
    config = CUDA.launch_configuration(cooperative_shuffling_kernel!, shmem = i -> (i[1] + 2) * (2i[2] + 1))
    groupsize = (warpsize, config.threads ÷ warpsize, 1)
    (; blocks) = config
    for N in 1:N
        fill!(view(x′, 1:(N + 1), 1:(N + 1)), 0x00)
        nrows = cld(N + 1, groupsize[2] - 2)
        for offset in 0:blocks:(nrows - 1)
            @cuda threads = groupsize blocks = blocks #=
              =# shmem = (groupsize[1] + 2) * (2groupsize[2] + 1) cooperative = true cooperative_shuffling_kernel!(x′, x, N, offset)
        end
        x, x′ = x′, x
    end
    return DiagonalTiling(N, x)
end

d = DiagonalTiling(1000)

function shuffling_kernel2!(x′, x, N, block_col = blockIdx().x, block_row = blockIdx().y)
    i = threadIdx().x + (block_col - 1) * (blockDim().x - 2)
    j = threadIdx().y + (block_row - 1) * (blockDim().y - 1)

    tmp = @cuDynamicSharedMem(UInt8, (blockDim().x + 2, 2 * blockDim().y + 1))
    k, l = threadIdx().x, threadIdx().y

    inbounds = i ≤ N && j ≤ N
    tile = inbounds ? @inbounds(x[i, j]) : 0x00

    offset = tile == 0x21 ? Int32(-1) : Int32(1)
    lane = (threadIdx().x - 1) % Int32(32)  # CUDA warp size is 32
    width = Int32(32)
    tile′ = shfl_sync(0xffffffff, tile, clamp(lane + offset, Int32(0), width - Int32(1)))

    @inbounds if tile == 0x21
        if tile′ & 0x0f != 0x02
            tmp[k, 2l - 1] = 0x01
            tmp[k, 2l] = 0x02
        end
    elseif tile != 0x44
        if tile & 0x0f == 0x02
            if tile′ != 0x21
                tmp[k + 1, 2l + 1] = 0x02
                tmp[k + 2, 2l] = 0x01
            end
        elseif tile & 0x0f == 0x04
            tmp[k, 2l] = 0x03
            tmp[k, 2l + 1] = 0x04
        end
        if tile >> 4 == 0x04
            tmp[k, 2l - 1] = 0x03
            tmp[k + 1, 2l] = 0x04
        end
    end

    sync_threads()

    if i ≤ N + 1 && j ≤ N + 1
        if (block_col != 1 && k ≤ 2) || (block_row != 1 && l ≤ 1)
            return nothing
        end
        @inbounds x′[i, j] = tmp[k, 2l - 1] | (tmp[k, 2l] << 4)
    end

    return nothing
end

function DiagonalTiling2(N::Int, d::DiagonalTiling = DiagonalTiling(0, [0x00;;]))
    x, x′ = CuArray{UInt8}(undef, N + 1, N + 1), CuArray{UInt8}(undef, N + 1, N + 1)
    copyto!(view(x, Base.OneTo.(size(d.x))...), d.x)

    warpsize = 32  # CUDA warp size
    config = CUDA.launch_configuration(shuffling_kernel2!, shmem = i -> (i[1] + 2) * (2i[2] + 1))
    groupsize = (warpsize, config.threads ÷ warpsize, 1)

    for N in (d.N + 1):N
        gridsize = (cld(N + 1, groupsize[1] - 2), cld(N + 1, groupsize[2] - 1), 1)
        @cuda threads = groupsize blocks = gridsize #=
          =# shmem = (groupsize[1] + 2) * (2groupsize[2] + 1) shuffling_kernel2!(x′, x, N)
        x, x′ = x′, x
    end
    return DiagonalTiling(N, x)
end
