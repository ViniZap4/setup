package tui

import "fmt"

// SummaryModel displays install results.
type SummaryModel struct {
	results []InstallResult
}

// NewSummaryModel creates a summary from install results.
func NewSummaryModel(results []InstallResult) SummaryModel {
	return SummaryModel{results: results}
}

// View renders the install summary.
func (m SummaryModel) View() string {
	s := "\n"
	s += TitleStyle.Render("  Install Summary") + "\n\n"

	success := 0
	failed := 0

	for _, r := range m.results {
		if r.Success {
			success++
			s += fmt.Sprintf("  %s %s\n", SuccessStyle.Render("✔"), r.Name)
		} else {
			failed++
			s += fmt.Sprintf("  %s %s — %s\n", ErrorStyle.Render("✖"), r.Name, DimStyle.Render(r.Error))
		}
	}

	s += "\n"
	if failed == 0 {
		s += SuccessStyle.Render(fmt.Sprintf("  All %d modules installed successfully!", success))
	} else {
		s += WarningStyle.Render(fmt.Sprintf("  %d succeeded, %d failed", success, failed))
	}

	s += "\n\n" + HelpStyle.Render("  enter: quit")
	return s
}
