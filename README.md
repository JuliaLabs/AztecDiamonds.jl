# AztecDiamonds

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://julia.mit.edu/AztecDiamonds.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://julia.mit.edu/AztecDiamonds.jl/dev/)
[![Build Status](https://github.com/julialabs/AztecDiamonds.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/julialabs/AztecDiamonds.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![GPU Build status](https://badge.buildkite.com/5f5d7b845c4e84af3c2039b8e275edf1ac75d498a5c0cb3e95.svg?branch=main)](https://buildkite.com/julialang/aztecdiamonds-dot-jl)
[![Coverage](https://codecov.io/gh/julialabs/AztecDiamonds.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/julialabs/AztecDiamonds.jl)

A package for generating and analyzing [Aztec diamonds](https://en.wikipedia.org/wiki/Aztec_diamond)

## Getting Started

To generate an order-n Aztec diamond, simply call `diamond(n)`

```julia
julia> D = diamond(50)
[...]
```

It is recommended that you use an interactive enviroment like Pluto, VS Code or IJulia to be able to view the generated diamonds in all their glory. Alternatively, you can also view them in a separate window using the [ImageView](https://github.com/JuliaImages/ImageView.jl) package as follows:

```julia
julia> using ImageView

julia> imshow(AztecDiamonds.to_img(D))
[...]
```

If you have an NVIDIA GPU in your system, you can take advantage of GPU acceleration by using the function `cuda_diamond` instead.

You can extract the DR-path separating the northern arctic region from the rest of the diamond using the `dr_path` function.

```julia
julia> dr_path(D)
101-element OffsetArray(::Vector{Float64}, -50:50) with eltype Float64 with indices -50:50:
 -0.5
  0.5
  1.5
  2.5
  3.5
  4.5
  5.5
  6.5
  ⋮
  6.5
  5.5
  4.5
  3.5
  2.5
  1.5
  0.5
 -0.5
```
