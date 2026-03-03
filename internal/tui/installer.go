package tui

import (
	"fmt"
	"time"

	"github.com/ViniZap4/setup/internal/module"
	"github.com/charmbracelet/bubbles/progress"
	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// InstallResult holds the result of installing a single module.
type InstallResult struct {
	Name    string
	Success bool
	Error   string
}

// installDoneMsg signals that a module install finished.
type installDoneMsg struct {
	result InstallResult
}

// tickMsg drives the elapsed timer.
type tickMsg time.Time

func tickEverySecond() tea.Cmd {
	return tea.Tick(time.Second, func(t time.Time) tea.Msg {
		return tickMsg(t)
	})
}

// InstallerModel manages the install progress view.
type InstallerModel struct {
	modules   []module.Module
	current   int
	results   []InstallResult
	spinner   spinner.Model
	progress  progress.Model
	done      bool
	startTime time.Time
	elapsed   time.Duration
	width     int
}

// NewInstallerModel creates a new installer for the given modules.
func NewInstallerModel(modules []module.Module) InstallerModel {
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = lipgloss.NewStyle().Foreground(Mauve)

	p := progress.New(
		progress.WithSolidFill(string(Mauve)),
		progress.WithoutPercentage(),
	)
	p.EmptyColor = string(Surface0)

	return InstallerModel{
		modules:   modules,
		spinner:   s,
		progress:  p,
		startTime: time.Now(),
	}
}

// Start kicks off the first install and timer.
func (m InstallerModel) Start() tea.Cmd {
	return tea.Batch(m.spinner.Tick, m.installNext(), tickEverySecond())
}

func (m InstallerModel) installNext() tea.Cmd {
	if m.current >= len(m.modules) {
		return nil
	}

	mod := m.modules[m.current]
	return func() tea.Msg {
		err := module.Install(mod)
		result := InstallResult{
			Name:    mod.Config.Name,
			Success: err == nil,
		}
		if err != nil {
			result.Error = err.Error()
		}
		return installDoneMsg{result: result}
	}
}

// Update handles messages for the installer.
func (m InstallerModel) Update(msg tea.Msg) (InstallerModel, tea.Cmd) {
	switch msg := msg.(type) {
	case installDoneMsg:
		m.results = append(m.results, msg.result)
		m.current++

		if m.current >= len(m.modules) {
			m.done = true
			m.elapsed = time.Since(m.startTime)
			return m, nil
		}

		return m, m.installNext()

	case tickMsg:
		m.elapsed = time.Since(m.startTime)
		return m, tickEverySecond()

	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		return m, cmd

	case progress.FrameMsg:
		mdl, cmd := m.progress.Update(msg)
		m.progress = mdl.(progress.Model)
		return m, cmd
	}

	return m, nil
}

// View renders the installer progress.
func (m InstallerModel) View() string {
	total := len(m.modules)
	done := len(m.results)
	percent := 0.0
	if total > 0 {
		percent = float64(done) / float64(total)
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
	title := TitleStyle.Render("Installing modules")
	header := fmt.Sprintf("  %s %s",
		title,
		TimerStyle.Render(fmt.Sprintf("%*s", boxWidth-lipgloss.Width(title)+2, timer+" elapsed")),
	)

	// Box content
	m.progress.Width = boxWidth - 6
	var boxContent string
	boxContent += fmt.Sprintf("%d/%d modules\n", done, total)
	boxContent += m.progress.ViewAs(percent) + fmt.Sprintf("  %d%%\n", int(percent*100))

	if m.current < total {
		mod := m.modules[m.current]
		boxContent += "\n"
		boxContent += fmt.Sprintf("%s Installing: %s\n",
			m.spinner.View(),
			AccentStyle.Render(mod.Config.Name))
		if mod.Config.Description != "" {
			boxContent += DimStyle.Render(mod.Config.Description)
		}
	}

	box := lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(Surface1).
		Padding(1, 2).
		Width(boxWidth).
		Render(boxContent)

	// Completed list
	var completed string
	if done > 0 {
		completed += "\n" + HeaderStyle.Render("  Completed:")
		for _, r := range m.results {
			if r.Success {
				completed += fmt.Sprintf("\n    %s %s", SuccessStyle.Render("✔"), r.Name)
			} else {
				completed += fmt.Sprintf("\n    %s %s — %s", ErrorStyle.Render("✖"), r.Name, DimStyle.Render(r.Error))
			}
		}
	}

	// Remaining count
	remaining := total - done
	var remainingStr string
	if remaining > 1 {
		remainingStr = "\n\n" + DimStyle.Render(fmt.Sprintf("  %d remaining...", remaining-1))
	}

	return fmt.Sprintf("\n%s\n\n  %s%s%s\n", header, box, completed, remainingStr)
}

func formatDuration(d time.Duration) string {
	s := int(d.Seconds())
	return fmt.Sprintf("%02d:%02d", s/60, s%60)
}
