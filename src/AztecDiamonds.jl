module AztecDiamonds

using OffsetArrays, Transducers, Folds
using Transducers: @next, complete, Executor

export Tiling, diamond, cuda_diamond, dr_path

@enum Edge::UInt8 NONE UP RIGHT SHOULD_FILL

inds(N) = (1-N:N, 1-N:N)

struct Tiling{M<:AbstractMatrix{Edge}}
    N::Int
    x::OffsetMatrix{Edge, M}
end
Tiling(N::Int; sizehint=N) = Tiling(N, fill(NONE, inds(sizehint)))
Base.checkbounds(::Type{Bool}, (; N)::Tiling, i, j) = abs(i-.5) + abs(j-.5) ≤ N
Base.@propagate_inbounds function Base.getindex(t::Tiling, i, j)
    @boundscheck checkbounds(Bool, t, i, j)
    return t.x[i, j]
end
Base.@propagate_inbounds function Base.setindex!(t::Tiling, x, i, j)
    @boundscheck checkbounds(Bool, t, i, j)
    return setindex!(t.x, x, i, j)
end
Base.@propagate_inbounds function Base.get(t::Tiling, (i, j)::NTuple{2, Integer}, def)
    return checkbounds(Bool, t, i, j) ? t[i, j] : def
end
Base.copy((; N, x)::Tiling) = Tiling(N, copy(x))


struct DiamondFaces <: Transducers.Foldable
    N::Int
end
faces((; N)::Tiling) = DiamondFaces(N)
Base.eltype(::DiamondFaces) = Tuple{Int, Int, Bool}
Base.length((; N)::DiamondFaces) = N * (N+1) * 2
function Transducers.__foldl__(rf, val, (; N)::DiamondFaces)
    for j in 1-N:N
        j′ = max(j, 1-j)
        for i in j′-N:N-j′+1
            isdotted = isodd(i+j-N)
            val = @next(rf, val, (i, j, isdotted))
        end
    end
    return complete(rf, val)
end


struct BlockIterator{good, T<:Tiling} <: Transducers.Foldable
    t::T
    BlockIterator{good}(t::T) where {good, T<:Tiling} = new{good, T}(t)
end
function Transducers.asfoldable((; t)::BlockIterator{good}) where {good}
    (; N) = t
    return faces(t) |> Filter() do (i, j, isdotted)
        tile = @inbounds t[i, j]
        @inbounds if tile == UP && j < N && t[i, j+1] == UP
            return good == isdotted
        elseif tile == RIGHT && i < N && t[i+1, j] == RIGHT
            return good == isdotted
        end
        return false
    end
end


_foreach(f, itr, ::SequentialEx) = foreach(f, itr)
function _foreach(f, itr, ex)
    if itr isa DiamondFaces
        let (; N) = itr
            N == 0 && return
            Folds.foreach(CartesianIndices(inds(N)), ex) do I
                i, j = Tuple(I)
                abs(i-.5) + abs(j-.5) ≤ N && f((i, j, isodd(i+j-N)))
            end
        end
    elseif itr isa BlockIterator
        let (; t) = itr
        (; N) = t
        good = itr isa BlockIterator{true}
        _foreach(faces(t), ex) do (i, j, isdotted)
            tile = @inbounds t[i, j]
            @inbounds if tile == UP && j < N && t[i, j+1] == UP
                good == isdotted && f((i, j, isdotted))
            elseif tile == RIGHT && i < N && t[i+1, j] == RIGHT
                good == isdotted && f((i, j, isdotted))
            end
        end
        end
    else
        Folds.foreach(f, itr, ex)
    end
end


# destruction
function remove_bad_blocks!(t::Tiling; ex=SequentialEx())
    _foreach(BlockIterator{false}(t), ex) do (i, j)
        @inbounds if t[i, j] == UP
            t[i, j+1] = NONE
        else
            t[i+1, j] = NONE
        end
        @inbounds t[i, j] = NONE
    end
    return t
end

# sliding
function slide_tiles!(t′::Tiling, t::Tiling; ex=SequentialEx())
    _foreach(faces(t), ex) do (i, j, isdotted)
        tile = @inbounds t[i, j]
        inc = isdotted ? -1 : 1
        @inbounds if tile == UP
            t′[i, j+inc] = UP
        elseif tile == RIGHT
            t′[i+inc, j] = RIGHT
        end
    end
    return t′
end

# filling
function fill_empty_blocks!(t′::Tiling, ex=SequentialEx(); scratch=nothing)
    _foreach(faces(t′), ex) do (i, j)
        @inbounds if t′[i, j] == NONE && get(t′, (i-1, j), NONE) != UP && get(t′, (i, j-1), NONE) != RIGHT
            if rand(Bool)
                t′[i, j] = t′[i, j+1] = UP
            else
                t′[i, j] = t′[i+1, j] = RIGHT
            end
        end
    end
    return t′
end

function step!(t′::Tiling, t::Tiling; ex=SequentialEx())
    t′.N == t.N + 1 || throw(ArgumentError("t′.N ≠ t.N + 1"))
    remove_bad_blocks!(t; ex)
    slide_tiles!(t′, t; ex)
    fill_empty_blocks!(t′, ex; scratch=t.x)
    return t′
end

function diamond!(t, t′, N; ex=SequentialEx())
    for N in 1:N
        (; x) = t′
        view(x, inds(N-1)...) .= NONE
        t′ = Tiling(N, x)
        t, t′ = step!(t′, t; ex), t
    end
    return t
end

function diamond(N)
    t, t′ = Tiling(0; sizehint=N), Tiling(0; sizehint=N)
    return diamond!(t, t′, N)
end

using FoldsCUDA, Adapt, Referenceables
using CUDA: CUDA, CuArray

# filling CUDA
function fill_empty_blocks!(t′::Tiling, ex::CUDAEx; scratch::OffsetMatrix)
    _foreach(faces(t′), ex) do (i, j)
        @inbounds if t′[i, j] == NONE && get(t′, (i-1, j), NONE) != UP && get(t′, (i, j-1), NONE) != RIGHT
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
    end
    _foreach(faces(t′), ex) do (i, j)
        @inbounds if scratch[i, j] == SHOULD_FILL
            if rand(Bool)
                t′[i, j] = t′[i, j+1] = UP
            else
                t′[i, j] = t′[i+1, j] = RIGHT
            end
        end
    end
    return t′
end

Adapt.adapt_structure(to, (; N, x)::Tiling) = Tiling(N, adapt(to, x))
function Base.fill!(a::SubArray{T, N, OffsetArray{T, N, CuArray{T, N, CUDA.Mem.DeviceBuffer}}}, x) where {T, N}
    length(a) != 0 && Folds.foreach(referenceable(a), CUDAEx()) do a
        a[] = x
    end
    return a
end

function cuda_diamond(N)
    t, t′ = ntuple(_ -> Tiling(0, OffsetMatrix(CUDA.fill(NONE, 2N, 2N), inds(N))), 2)
    return diamond!(t, t′, N; ex=CUDAEx())
end

include("show.jl")
include("dr_path.jl")

end
