package tui

import (
	"fmt"

	"github.com/ViniZap4/setup/internal/module"
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

// InstallerModel manages the install progress view.
type InstallerModel struct {
	modules []module.Module
	current int
	results []InstallResult
	spinner spinner.Model
	done    bool
}

// NewInstallerModel creates a new installer for the given modules.
func NewInstallerModel(modules []module.Module) InstallerModel {
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = lipgloss.NewStyle().Foreground(Mauve)

	return InstallerModel{
		modules: modules,
		spinner: s,
	}
}

// Start kicks off the first install.
func (m InstallerModel) Start() tea.Cmd {
	return tea.Batch(m.spinner.Tick, m.installNext())
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
			return m, nil
		}

		return m, m.installNext()

	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		return m, cmd
	}

	return m, nil
}

// View renders the installer progress.
func (m InstallerModel) View() string {
	s := "\n"
	s += TitleStyle.Render("  Installing modules...") + "\n\n"

	for _, result := range m.results {
		if result.Success {
			s += fmt.Sprintf("  %s %s\n", SuccessStyle.Render("✔"), result.Name)
		} else {
			s += fmt.Sprintf("  %s %s — %s\n", ErrorStyle.Render("✖"), result.Name, DimStyle.Render(result.Error))
		}
	}

	if m.current < len(m.modules) {
		s += fmt.Sprintf("  %s %s\n", m.spinner.View(), m.modules[m.current].Config.Name)
	}

	remaining := len(m.modules) - m.current
	if remaining > 1 {
		s += DimStyle.Render(fmt.Sprintf("\n  %d remaining...", remaining-1))
	}

	return s
}
