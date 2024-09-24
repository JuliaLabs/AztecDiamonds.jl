module AztecDiamonds

using OffsetArrays, Transducers
using Transducers: @next, complete

export Tiling, diamond, ka_diamond, dr_path

@enum Edge::UInt8 NONE UP RIGHT SHOULD_FILL

inds(N) = ((1 - N):N, (1 - N):N)

"""
    Tiling(N::Int[, x::OffsetMatrix{AztecDiamonds.Edge}]; sizehint::Int = N)

Represents an order N diamond-shaped tiling. If `x` is not provided, it is initialized with `NONE`
representing an empty tiling. The `sizehint` keyword argument may be used to preallocate a larger
matrix for `x` fitting a tiling of order `sizehint` to avoid reallocations when the tiling grows.

The indices of `x` represent the coordinates of the diamond-shaped tiling and run from 1-N to N
(though `x` is allowed to be larger as long as it contains these indices).
The edges it contains can either be `UP`, `RIGHT`, or `NONE`, where `UP` represents a vertical tile
covering one more tile to the top, `RIGHT` represents a horizontal tile covering one more tile to
the right. `NONE` means the edge is either already covered by another tile to the bottom or left or
the tiling is not fully filled yet.

```jldoctest
julia> t = Tiling(1)
1-order Tiling{Matrix{AztecDiamonds.Edge}}



julia> t[0, 0] = t[1, 0] = AztecDiamonds.RIGHT;

julia> t
1-order Tiling{Matrix{AztecDiamonds.Edge}}
🬇🬋🬋🬃
🬇🬋🬋🬃
```

See [`diamond`](@ref) and [`ka_diamond`](@ref) for constructing a filled tiling.
"""
struct Tiling{M <: AbstractMatrix{Edge}}
    N::Int
    x::OffsetMatrix{Edge, M}
end
Tiling(N::Int; sizehint::Int = N) = Tiling(N, fill(NONE, inds(sizehint)))

in_diamond(N, i, j) = abs(2i - 1) + abs(2j - 1) ≤ 2N
Base.checkbounds(::Type{Bool}, (; N)::Tiling, i, j) = in_diamond(N, i, j)
function Base.checkbounds(t::Tiling, i, j)
    checkbounds(Bool, t, i, j) || throw(BoundsError(t, (i, j)))
    return nothing
end

Base.@propagate_inbounds function Base.getindex(t::Tiling, i::Integer, j::Integer)
    @boundscheck checkbounds(t, i, j)
    return t.x[i, j]
end
Base.@propagate_inbounds function Base.setindex!(t::Tiling, x, i::Integer, j::Integer)
    @boundscheck checkbounds(t, i, j)
    return setindex!(t.x, x, i, j)
end
Base.@propagate_inbounds function Base.get(t::Tiling, (i, j)::NTuple{2, Integer}, def)
    return checkbounds(Bool, t, i, j) ? t[i, j] : def
end

Base.:(==)(t1::Tiling, t2::Tiling) = t1.N == t2.N && t1.x == t2.x
const TILING_SEED = 0x493d55c7378becd5 % UInt
function Base.hash((; N, x)::Tiling, h::UInt)
    return hash(x, hash(N, hash(TILING_SEED, h)))
end
Base.copy((; N, x)::Tiling) = Tiling(N, copy(x))


struct DiamondFaces <: Transducers.Foldable
    N::Int
end
faces((; N)::Tiling) = DiamondFaces(N)
Base.eltype(::DiamondFaces) = Tuple{Int, Int, Bool}
Base.length((; N)::DiamondFaces) = N * (N + 1) * 2
function Transducers.__foldl__(rf::R, val::V, (; N)::DiamondFaces) where {R, V}
    for j in (1 - N):N
        j′ = max(j, 1 - j)
        for i in (j′ - N):(N - j′ + 1)
            isdotted = isodd(i + j - N)
            val = @next(rf, val, (i, j, isdotted))
        end
    end
    return complete(rf, val)
end


struct BlockIterator{good, T <: Tiling} <: Transducers.Foldable
    t::T
    BlockIterator{good}(t::T) where {good, T <: Tiling} = new{good, T}(t)
end
Base.@propagate_inbounds function isblock(t::Tiling, i, j, ::Val{good}) where {good}
    (; N) = t
    isdotted = isodd(i + j - N)
    tile = t[i, j]
    if tile == UP && j < N && get(t, (i, j + 1), NONE) == UP
        return good == isdotted
    elseif tile == RIGHT && i < N && get(t, (i + 1, j), NONE) == RIGHT
        return good == isdotted
    end
    return false
end
function Transducers.asfoldable((; t)::BlockIterator{good}) where {good}
    return faces(t) |> Filter() do (i, j, isdotted)
        return @inbounds isblock(t, i, j, Val(good))
    end
end


# destruction
function remove_bad_blocks!(t::Tiling)
    foreach(BlockIterator{false}(t)) do (i, j)
        @inbounds if t[i, j] == UP
            t[i, j + 1] = NONE
        else
            t[i + 1, j] = NONE
        end
        @inbounds t[i, j] = NONE
    end
    return t
end

# sliding
function slide_tiles!(t′::Tiling, t::Tiling)
    foreach(faces(t)) do (i, j, isdotted)
        tile = @inbounds t[i, j]
        inc = isdotted ? -1 : 1
        @inbounds if tile == UP
            t′[i, j + inc] = UP
        elseif tile == RIGHT
            t′[i + inc, j] = RIGHT
        end
    end
    return t′
end

Base.@propagate_inbounds function is_empty_tile(t′::Tiling, i, j)
    return t′[i, j] == NONE && get(t′, (i - 1, j), NONE) != UP && get(t′, (i, j - 1), NONE) != RIGHT
end

# filling
function fill_empty_blocks!(t′::Tiling)
    foreach(faces(t′)) do (i, j)
        @inbounds if is_empty_tile(t′, i, j)
            if rand(Bool)
                t′[i, j] = t′[i, j + 1] = UP
            else
                t′[i, j] = t′[i + 1, j] = RIGHT
            end
        end
    end
    return t′
end

function step!(t′::Tiling, t::Tiling)
    t′.N == t.N + 1 || throw(ArgumentError("t′.N ≠ t.N + 1"))
    remove_bad_blocks!(t)
    slide_tiles!(t′, t)
    fill_empty_blocks!(t′)
    return t′
end

function diamond!(t, t′, N)
    for N in 1:N
        (; x) = t′
        view(x, inds(N - 1)...) .= NONE
        t′ = Tiling(N, x)
        t, t′ = step!(t′, t), t
    end
    return t
end

"""
    diamond(N::Int) -> Tiling{Matrix{AztecDiamonds.Edge}}

Generates a uniformally random order N diamond tiling.

```jldoctest
julia> using Random; Random.seed!(1);

julia> diamond(4)
4-order Tiling{Matrix{AztecDiamonds.Edge}}
      🬇🬋🬋🬃
    🬇🬋🬋🬃🬇🬋🬋🬃
  🬦🬓🬦🬓🬦🬓🬦🬓🬇🬋🬋🬃
🬦🬓🬉🬄🬉🬄🬉🬄🬉🬄🬇🬋🬋🬃🬦🬓
🬉🬄🬦🬓🬦🬓🬇🬋🬋🬃🬦🬓🬦🬓🬉🬄
  🬉🬄🬉🬄🬇🬋🬋🬃🬉🬄🬉🬄
    🬇🬋🬋🬃🬇🬋🬋🬃
      🬇🬋🬋🬃
```

See [`ka_diamond`](@ref) for a version that can take advantage of GPU acceleration.
`ka_diamond(N, Array)` may also be faster for large N.

Ref [`Tiling`](@ref)
"""
function diamond(N::Int)
    t, t′ = Tiling(0; sizehint = N), Tiling(0; sizehint = N)
    return diamond!(t, t′, N)
end

include("ka.jl")
include("show.jl")
include("dr_path.jl")

# stubs for plotting functions

function tilingplot end
function tilingplot! end

end
