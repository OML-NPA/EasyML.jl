using Documenter, EasyML

makedocs(modules=[EasyML],
    sitename = "EasyML.jl",
    pages = ["Home" => "index.md",
            "Quick guide" => "quick_guide.md",
            "GUI guide" => "gui_guide.md",
            "Functions" => "functions.md",
            "Advanced" => "advanced.md",
            "Handling issues" => "handling_issues.md"],
    authors = "Open Machine Learning Association",
    format = Documenter.HTML(prettyurls = false)
)