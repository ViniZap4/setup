package tui

import (
	"fmt"
	"time"

	"github.com/charmbracelet/bubbles/progress"
	"github.com/charmbracelet/lipgloss"
)

// SummaryModel displays install results.
type SummaryModel struct {
	results  []InstallResult
	elapsed  time.Duration
	progress progress.Model
	width    int
}

// NewSummaryModel creates a summary from install results.
func NewSummaryModel(results []InstallResult, elapsed time.Duration) SummaryModel {
	p := progress.New(
		progress.WithSolidFill(string(Mauve)),
		progress.WithoutPercentage(),
	)
	p.EmptyColor = string(Surface0)

	return SummaryModel{
		results:  results,
		elapsed:  elapsed,
		progress: p,
	}
}

// View renders the install summary.
func (m SummaryModel) View() string {
	success := 0
	failed := 0
	for _, r := range m.results {
		if r.Success {
			success++
		} else {
			failed++
		}
	}

	total := len(m.results)
	percent := 0.0
	if total > 0 {
		percent = float64(success) / float64(total)
	}

	boxWidth := 60
	if m.width > 0 && m.width-6 < boxWidth {
		boxWidth = m.width - 6
	}
	if boxWidth < 40 {
		boxWidth = 40
	}

	// Header: title + timer
	timer := formatDuration(m.elapsed)
	title := TitleStyle.Render("Install Summary")
	header := fmt.Sprintf("  %s %s",
		title,
		TimerStyle.Render(fmt.Sprintf("%*s", boxWidth-lipgloss.Width(title)+2, timer+" total")),
	)

	// Box content
	m.progress.Width = boxWidth - 6
	var boxContent string
	boxContent += m.progress.ViewAs(percent) + fmt.Sprintf("  %d%%\n", int(percent*100))
	boxContent += "\n"

	successStr := SuccessStyle.Render(fmt.Sprintf("%d succeeded", success))
	failedStr := ErrorStyle.Render(fmt.Sprintf("%d failed", failed))
	if failed == 0 {
		failedStr = DimStyle.Render("0 failed")
	}
	boxContent += successStr + "   " + failedStr

	box := lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(Surface1).
		Padding(1, 2).
		Width(boxWidth).
		Render(boxContent)

	// Results list
	var list string
	for _, r := range m.results {
		if r.Success {
			list += fmt.Sprintf("\n    %s %s", SuccessStyle.Render("✔"), r.Name)
		} else {
			list += fmt.Sprintf("\n    %s %s — %s", ErrorStyle.Render("✖"), r.Name, DimStyle.Render(r.Error))
		}
	}

	help := HelpStyle.Render("  enter: quit")

	return fmt.Sprintf("\n%s\n\n  %s\n%s\n\n%s\n", header, box, list, help)
}
