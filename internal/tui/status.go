package tui

import (
	"fmt"

	"github.com/ViniZap4/setup/internal/module"
)

// StatusModel displays the status of all modules.
type StatusModel struct{}

// NewStatusModel creates a new status view.
func NewStatusModel() StatusModel {
	return StatusModel{}
}

// View renders the module status overview.
func (m StatusModel) View(modules []module.Module) string {
	s := "\n"
	s += TitleStyle.Render("  Module Status") + "\n\n"

	if len(modules) == 0 {
		s += DimStyle.Render("  No modules found.") + "\n"
	}

	for _, mod := range modules {
		status := module.GetStatus(mod)
		linked := module.IsFullyLinked(status)

		icon := WarningStyle.Render("○")
		nameStyle := UnselectedStyle
		if linked {
			icon = SuccessStyle.Render("●")
		}

		if !status.Supported {
			icon = DimStyle.Render("○")
			nameStyle = DimStyle
		}

		s += fmt.Sprintf("  %s %s", icon, nameStyle.Render(status.Name))
		s += DimStyle.Render(" — "+mod.Config.Description) + "\n"

		for _, link := range status.Links {
			var statusIcon string
			switch link.Status {
			case "linked":
				statusIcon = StatusLinked.Render("✔")
			case "missing":
				statusIcon = StatusMissing.Render("−")
			case "conflict":
				statusIcon = StatusConflict.Render("!")
			case "wrong-target":
				statusIcon = StatusConflict.Render("→")
			}
			s += fmt.Sprintf("    %s %s → %s\n", statusIcon, DimStyle.Render(link.Source), DimStyle.Render(link.Target))
		}
	}

	s += "\n" + HelpStyle.Render("  esc: back • q: quit")
	return s
}
