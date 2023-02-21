# AztecDiamonds

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://julia.mit.edu/AztecDiamonds.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://julia.mit.edu/AztecDiamonds.jl/dev/)
[![Build Status](https://github.com/JuliaLabs/AztecDiamonds.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaLabs/AztecDiamonds.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![GPU Build status](https://badge.buildkite.com/5f5d7b845c4e84af3c2039b8e275edf1ac75d498a5c0cb3e95.svg?branch=main)](https://buildkite.com/julialang/aztecdiamonds-dot-jl)
[![Coverage](https://codecov.io/gh/JuliaLabs/AztecDiamonds.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaLabs/AztecDiamonds.jl)

A package for generating and analyzing [Aztec diamonds](https://en.wikipedia.org/wiki/Aztec_diamond)

## Getting Started

To generate an order-n Aztec diamond, simply call `diamond(n)`

```julia
julia> diamond(20)
20-order Tiling{Matrix{AztecDiamonds.Edge}}
                                      🬇🬋🬋🬃
                                    🬇🬋🬋🬃🬇🬋🬋🬃
                                  🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃
                                🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃
                              🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃
                            🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃
                          🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃
                        🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃
                      🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬦🬓🬦🬓🬇🬋🬋🬃🬦🬓🬦🬓🬇🬋🬋🬃🬇🬋🬋🬃
                    🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬦🬓🬉🬄🬉🬄🬇🬋🬋🬃🬉🬄🬉🬄🬇🬋🬋🬃🬦🬓🬇🬋🬋🬃
                  🬇🬋🬋🬃🬦🬓🬦🬓🬦🬓🬇🬋🬋🬃🬇🬋🬋🬃🬉🬄🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬉🬄🬦🬓🬇🬋🬋🬃
                🬦🬓🬇🬋🬋🬃🬉🬄🬉🬄🬉🬄🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬉🬄🬇🬋🬋🬃🬦🬓
              🬦🬓🬉🬄🬇🬋🬋🬃🬦🬓🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬦🬓🬦🬓🬇🬋🬋🬃🬇🬋🬋🬃🬦🬓🬦🬓🬦🬓🬇🬋🬋🬃🬦🬓🬦🬓🬉🬄🬦🬓
            🬦🬓🬉🬄🬦🬓🬦🬓🬦🬓🬉🬄🬦🬓🬦🬓🬦🬓🬦🬓🬦🬓🬦🬓🬉🬄🬉🬄🬦🬓🬦🬓🬇🬋🬋🬃🬉🬄🬉🬄🬉🬄🬇🬋🬋🬃🬉🬄🬉🬄🬦🬓🬉🬄🬦🬓
          🬦🬓🬉🬄🬦🬓🬉🬄🬉🬄🬉🬄🬦🬓🬉🬄🬉🬄🬉🬄🬉🬄🬉🬄🬉🬄🬦🬓🬦🬓🬉🬄🬉🬄🬇🬋🬋🬃🬦🬓🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬉🬄🬦🬓🬉🬄🬦🬓
        🬦🬓🬉🬄🬦🬓🬉🬄🬇🬋🬋🬃🬦🬓🬉🬄🬇🬋🬋🬃🬇🬋🬋🬃🬦🬓🬦🬓🬉🬄🬉🬄🬦🬓🬦🬓🬇🬋🬋🬃🬉🬄🬦🬓🬇🬋🬋🬃🬦🬓🬦🬓🬇🬋🬋🬃🬉🬄🬦🬓🬉🬄🬦🬓
      🬦🬓🬉🬄🬦🬓🬉🬄🬦🬓🬇🬋🬋🬃🬉🬄🬇🬋🬋🬃🬦🬓🬇🬋🬋🬃🬉🬄🬉🬄🬇🬋🬋🬃🬉🬄🬉🬄🬦🬓🬇🬋🬋🬃🬉🬄🬇🬋🬋🬃🬉🬄🬉🬄🬦🬓🬇🬋🬋🬃🬉🬄🬦🬓🬉🬄🬦🬓
    🬦🬓🬉🬄🬦🬓🬉🬄🬦🬓🬉🬄🬇🬋🬋🬃🬇🬋🬋🬃🬦🬓🬉🬄🬦🬓🬇🬋🬋🬃🬦🬓🬦🬓🬦🬓🬇🬋🬋🬃🬉🬄🬦🬓🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬉🬄🬇🬋🬋🬃🬦🬓🬉🬄🬦🬓🬉🬄🬦🬓
  🬦🬓🬉🬄🬦🬓🬉🬄🬦🬓🬉🬄🬇🬋🬋🬃🬦🬓🬇🬋🬋🬃🬉🬄🬦🬓🬉🬄🬇🬋🬋🬃🬉🬄🬉🬄🬉🬄🬦🬓🬇🬋🬋🬃🬉🬄🬇🬋🬋🬃🬇🬋🬋🬃🬦🬓🬦🬓🬦🬓🬦🬓🬦🬓🬉🬄🬦🬓🬉🬄🬦🬓🬉🬄🬦🬓
🬦🬓🬉🬄🬦🬓🬉🬄🬦🬓🬉🬄🬦🬓🬦🬓🬦🬓🬉🬄🬇🬋🬋🬃🬦🬓🬉🬄🬇🬋🬋🬃🬦🬓🬦🬓🬇🬋🬋🬃🬉🬄🬇🬋🬋🬃🬇🬋🬋🬃🬦🬓🬇🬋🬋🬃🬉🬄🬉🬄🬉🬄🬉🬄🬉🬄🬦🬓🬉🬄🬦🬓🬉🬄🬦🬓🬉🬄🬦🬓
🬉🬄🬦🬓🬉🬄🬦🬓🬉🬄🬦🬓🬉🬄🬉🬄🬉🬄🬦🬓🬦🬓🬦🬓🬉🬄🬦🬓🬇🬋🬋🬃🬉🬄🬉🬄🬇🬋🬋🬃🬦🬓🬇🬋🬋🬃🬦🬓🬦🬓🬉🬄🬦🬓🬦🬓🬦🬓🬦🬓🬦🬓🬇🬋🬋🬃🬉🬄🬦🬓🬉🬄🬦🬓🬉🬄🬦🬓🬉🬄
  🬉🬄🬦🬓🬉🬄🬦🬓🬉🬄🬦🬓🬇🬋🬋🬃🬉🬄🬉🬄🬉🬄🬦🬓🬉🬄🬦🬓🬇🬋🬋🬃🬦🬓🬦🬓🬦🬓🬉🬄🬇🬋🬋🬃🬉🬄🬉🬄🬦🬓🬉🬄🬉🬄🬉🬄🬉🬄🬉🬄🬦🬓🬇🬋🬋🬃🬉🬄🬦🬓🬉🬄🬦🬓🬉🬄
    🬉🬄🬦🬓🬉🬄🬦🬓🬉🬄🬦🬓🬇🬋🬋🬃🬇🬋🬋🬃🬉🬄🬦🬓🬉🬄🬦🬓🬦🬓🬉🬄🬉🬄🬉🬄🬇🬋🬋🬃🬦🬓🬇🬋🬋🬃🬉🬄🬇🬋🬋🬃🬦🬓🬇🬋🬋🬃🬉🬄🬇🬋🬋🬃🬦🬓🬉🬄🬦🬓🬉🬄
      🬉🬄🬦🬓🬉🬄🬦🬓🬉🬄🬇🬋🬋🬃🬦🬓🬇🬋🬋🬃🬉🬄🬦🬓🬉🬄🬉🬄🬇🬋🬋🬃🬦🬓🬇🬋🬋🬃🬉🬄🬦🬓🬦🬓🬦🬓🬦🬓🬦🬓🬉🬄🬇🬋🬋🬃🬦🬓🬇🬋🬋🬃🬉🬄🬦🬓🬉🬄
        🬉🬄🬦🬓🬉🬄🬦🬓🬇🬋🬋🬃🬉🬄🬦🬓🬇🬋🬋🬃🬉🬄🬇🬋🬋🬃🬇🬋🬋🬃🬉🬄🬇🬋🬋🬃🬦🬓🬉🬄🬉🬄🬉🬄🬉🬄🬉🬄🬇🬋🬋🬃🬦🬓🬉🬄🬇🬋🬋🬃🬦🬓🬉🬄
          🬉🬄🬦🬓🬉🬄🬦🬓🬇🬋🬋🬃🬉🬄🬇🬋🬋🬃🬇🬋🬋🬃🬦🬓🬇🬋🬋🬃🬇🬋🬋🬃🬦🬓🬉🬄🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬦🬓🬉🬄🬇🬋🬋🬃🬦🬓🬉🬄
            🬉🬄🬦🬓🬉🬄🬦🬓🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬉🬄🬇🬋🬋🬃🬇🬋🬋🬃🬉🬄🬇🬋🬋🬃🬦🬓🬦🬓🬇🬋🬋🬃🬦🬓🬉🬄🬇🬋🬋🬃🬦🬓🬉🬄
              🬉🬄🬦🬓🬉🬄🬇🬋🬋🬃🬦🬓🬦🬓🬦🬓🬇🬋🬋🬃🬇🬋🬋🬃🬦🬓🬦🬓🬇🬋🬋🬃🬦🬓🬉🬄🬉🬄🬇🬋🬋🬃🬉🬄🬇🬋🬋🬃🬦🬓🬉🬄
                🬉🬄🬦🬓🬇🬋🬋🬃🬉🬄🬉🬄🬉🬄🬇🬋🬋🬃🬇🬋🬋🬃🬉🬄🬉🬄🬦🬓🬦🬓🬉🬄🬇🬋🬋🬃🬦🬓🬦🬓🬦🬓🬦🬓🬦🬓🬉🬄
                  🬉🬄🬦🬓🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬉🬄🬉🬄🬦🬓🬦🬓🬦🬓🬉🬄🬉🬄🬉🬄🬉🬄🬉🬄
                    🬉🬄🬦🬓🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬦🬓🬉🬄🬉🬄🬉🬄🬇🬋🬋🬃🬇🬋🬋🬃
                      🬉🬄🬇🬋🬋🬃🬇🬋🬋🬃🬦🬓🬇🬋🬋🬃🬦🬓🬇🬋🬋🬃🬉🬄🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃
                        🬇🬋🬋🬃🬇🬋🬋🬃🬉🬄🬦🬓🬦🬓🬉🬄🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃
                          🬇🬋🬋🬃🬇🬋🬋🬃🬉🬄🬉🬄🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃
                            🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃
                              🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃
                                🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃
                                  🬇🬋🬋🬃🬇🬋🬋🬃🬇🬋🬋🬃
                                    🬇🬋🬋🬃🬇🬋🬋🬃
                                      🬇🬋🬋🬃
```

It is recommended that you use an interactive enviroment like Pluto, VS Code or IJulia to be able to view the generated diamonds in all their glory. Alternatively, you can also view them in a separate window using the [ImageView](https://github.com/JuliaImages/ImageView.jl) package as follows:

```julia
julia> using ImageView

julia> imshow(AztecDiamonds.to_img(D))
[...]
```

It is possible to take advantage of GPU acceleration via [KernelAbstractions.jl](https://github.com/JuliaGPU/KernelAbstractions.jl) on supported backends, e.g. CUDA:

```julia
julia> using CUDA, CUDAKernels

julia> ka_diamond(200, CuArray)
[...]
```

You can extract the DR-path separating the northern arctic region from the rest of the diamond using the `dr_path` function.

```julia
julia> dr_path(D)
41-element OffsetArray(::Vector{Float64}, -20:20) with eltype Float64 with indices -20:20:
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
