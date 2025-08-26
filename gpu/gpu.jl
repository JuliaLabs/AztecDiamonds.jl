using AztecDiamonds, OffsetArrays
using AztecDiamonds: Edge, UP, RIGHT, NONE

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

using AMDGPU

function shuffling_kernel!(x′, x, N)
    i = workitemIdx().x + (workgroupIdx().x - 1) * (workgroupDim().x - 2)
    j = workitemIdx().y + (workgroupIdx().y - 1) * (workgroupDim().y - 2)

    inbounds = i ≤ N && j ≤ N
    tile = inbounds ? @inbounds(x[i, j]) : 0x00

    offset = tile == 0x21 ? Cint(-1) : Cint(1)
    lane = unsafe_trunc(Cint, AMDGPU.Device.activelane())
    width = unsafe_trunc(Cint, AMDGPU.Device.wavefrontsize())
    tile′ = AMDGPU.Device.shfl(tile, clamp(lane + offset, Cint(0), width - Cint(1)))

    tmp = @ROCDynamicLocalArray(UInt8, (workgroupDim().x + 2, 2 * workgroupDim().y + 1), true)
    k, l = workitemIdx().x, workitemIdx().y

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

    AMDGPU.Device.sync_workgroup()

    should_fill = false
    for l in l:-1:1
        tmp[k, 2l - 1] == tmp[k, 2l] == 0x00 || break
        should_fill ⊻= true
    end

    if should_fill && i != N + 1
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

    AMDGPU.Device.sync_workgroup()

    if i ≤ N + 1 && j ≤ N + 1
        if (workgroupIdx().x != 1 && k ≤ 2) || (workgroupIdx().y != 1 && l ≤ 2)
            return nothing
        end
        @inbounds x′[i, j] = tmp[k, 2l - 1] | (tmp[k, 2l] << 4)
    end

    return nothing
end

function shuffle((; N, x)::DiagonalTiling)
    x = ROCArray(x)
    x′ = similar(x, (N + 2, N + 2))
    wavefrontsize = Int(AMDGPU.device().wavefrontsize)
    cus = 12
    @roc groupsize = (wavefrontsize, cus, 1) gridsize = @show((cld(N + 2, wavefrontsize - 2), cld(N + 2, cus - 2), 1)) shmem = (wavefrontsize + 2) * (2cus + 1) shuffling_kernel!(x′, x, N + 1)
    return DiagonalTiling(N + 1, Array(x′))
end

Tiling(shuffle(DiagonalTiling(t)))

function DiagonalTiling(N::Int)
    x, x′ = ROCArray{UInt8}(undef, N + 1, N + 1), ROCArray{UInt8}(undef, N + 1, N + 1)
    fill!(x′, 0x00)
    wavefrontsize = Int(AMDGPU.device().wavefrontsize)
    cus = 12
    for N in 0:N
        @roc groupsize = (wavefrontsize, cus, 1) gridsize = (cld(N + 1, wavefrontsize - 2), cld(N + 1, cus - 2), 1) shmem = (wavefrontsize + 2) * (2cus + 1) shuffling_kernel!(x′, x, N)
        x, x′ = x′, x
    end
    return DiagonalTiling(N, Array(x))
end
