using AztecDiamonds
using Documenter

DocMeta.setdocmeta!(AztecDiamonds, :DocTestSetup, :(using AztecDiamonds); recursive=true)

makedocs(;
    modules=[AztecDiamonds],
    authors="Simeon David Schaub <schaub@mit.edu> and contributors",
    repo="https://github.com/simeonschaub/AztecDiamonds.jl/blob/{commit}{path}#{line}",
    sitename="AztecDiamonds.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://simeonschaub.github.io/AztecDiamonds.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/simeonschaub/AztecDiamonds.jl",
    devbranch="main",
)
