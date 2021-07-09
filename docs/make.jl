
using Documenter, EasyMLTraining

makedocs(modules=[EasyMLTraining],
    sitename = "EasyMLTraining.jl",
    pages = ["Home" => "index.md",
            "Quick guide" => "quick_guide.md",
            "GUI guide" => "gui_guide.md",
            "Functions" => "functions.md",
            "Advanced" => "advanced.md",
            "Handling issues" => "handling_issues.md"],
    authors = "Open Machine Learning Association",
    format = Documenter.HTML(prettyurls = false)
)

deploydocs(
    repo = "github.com/OML-NPA/EasyMLTraining.jl.git",
    devbranch = "main"
)
