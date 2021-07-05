using Documenter, EasyML

makedocs(modules=[EasyML],
    sitename = "EasyML.jl",
    pages = ["Home" => "index.md",
            "Quick guide" => "quick_guide.md",
            "GUI guide" => "gui_guide.md",
            "Functions" => "functions.md",
            "Advanced" => "advanced.md",
            "Handling issues" => "handling_issues.md"],
    authors = "Aleksandr Illarionov",
    format = Documenter.HTML(prettyurls = false)
)

deploydocs(
    repo = "github.com/OML-NPA/EasyML.jl.git",
    devbranch = "main"
)