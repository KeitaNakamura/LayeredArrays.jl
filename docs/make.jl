using Documenter
using LayeredArrays

# Setup for doctests in docstrings
DocMeta.setdocmeta!(LayeredArrays, :DocTestSetup, recursive = true,
    quote
        using LayeredArrays
    end
)

makedocs(;
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    modules = [LayeredArrays],
    sitename = "LayeredArrays.jl",
    pages=[
        "Home" => "index.md",
    ],
    doctest = true, # :fix
)

deploydocs(
    repo = "github.com/KeitaNakamura/LayeredArrays.jl.git",
    devbranch = "main",
)
