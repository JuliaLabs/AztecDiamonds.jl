using AztecDiamonds
using Documenter

DocMeta.setdocmeta!(AztecDiamonds, :DocTestSetup, :(using AztecDiamonds); recursive=true)

makedocs(;
    modules=[AztecDiamonds],
    authors="Simeon David Schaub <schaub@mit.edu> and contributors",
    repo="https://github.com/julialabs/AztecDiamonds.jl/blob/{commit}{path}#{line}",
    sitename="AztecDiamonds.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://julia.mit.edu/AztecDiamonds.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        #"Examples" => [
        #    "Basics" => "https://julia.mit.edu/AztecDiamonds.jl/examples/dev/notebook.html",
        #],
    ],
)

deploydocs(;
    repo="github.com/julialabs/AztecDiamonds.jl",
    devbranch="main",
)
