package tui

import (
	"github.com/ViniZap4/setup/internal/module"
	tea "github.com/charmbracelet/bubbletea"
)

// View represents the current TUI screen.
type View int

const (
	ViewWelcome View = iota
	ViewSelector
	ViewInstaller
	ViewStatus
	ViewSummary
)

// App is the root bubbletea model.
type App struct {
	currentView View
	modules     []module.Module
	modulesDir  string

	welcome   WelcomeModel
	selector  SelectorModel
	installer InstallerModel
	status    StatusModel
	summary   SummaryModel

	width  int
	height int
}

// NewApp creates a new TUI application.
func NewApp(modulesDir string) App {
	return App{
		currentView: ViewWelcome,
		modulesDir:  modulesDir,
		welcome:     NewWelcomeModel(),
	}
}

func (a App) Init() tea.Cmd {
	return nil
}

func (a App) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		a.width = msg.Width
		a.height = msg.Height
		a.installer.width = msg.Width
		a.summary.width = msg.Width

	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c":
			return a, tea.Quit
		}
	}

	switch a.currentView {
	case ViewWelcome:
		return a.updateWelcome(msg)
	case ViewSelector:
		return a.updateSelector(msg)
	case ViewInstaller:
		return a.updateInstaller(msg)
	case ViewStatus:
		return a.updateStatus(msg)
	case ViewSummary:
		return a.updateSummary(msg)
	}

	return a, nil
}

func (a App) View() string {
	switch a.currentView {
	case ViewWelcome:
		return a.welcome.View()
	case ViewSelector:
		return a.selector.View()
	case ViewInstaller:
		return a.installer.View()
	case ViewStatus:
		return a.status.View(a.modules)
	case ViewSummary:
		return a.summary.View()
	default:
		return ""
	}
}

func (a App) updateWelcome(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "up", "k":
			a.welcome.cursor--
			if a.welcome.cursor < 0 {
				a.welcome.cursor = len(a.welcome.choices) - 1
			}
		case "down", "j":
			a.welcome.cursor++
			if a.welcome.cursor >= len(a.welcome.choices) {
				a.welcome.cursor = 0
			}
		case "enter":
			return a.handleWelcomeChoice()
		case "q":
			return a, tea.Quit
		}
	}
	return a, nil
}

func (a App) handleWelcomeChoice() (tea.Model, tea.Cmd) {
	// Discover modules
	modules, err := module.Discover(a.modulesDir)
	if err != nil {
		modules = nil
	}
	a.modules = modules

	switch a.welcome.cursor {
	case 0: // Install modules
		a.selector = NewSelectorModel(modules)
		a.currentView = ViewSelector
	case 1: // View status
		a.status = NewStatusModel()
		a.currentView = ViewStatus
	case 2: // Quit
		return a, tea.Quit
	}
	return a, nil
}

func (a App) updateSelector(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "up", "k":
			a.selector.cursor--
			if a.selector.cursor < 0 {
				a.selector.cursor = len(a.selector.items) - 1
			}
		case "down", "j":
			a.selector.cursor++
			if a.selector.cursor >= len(a.selector.items) {
				a.selector.cursor = 0
			}
		case " ":
			a.selector.items[a.selector.cursor].selected = !a.selector.items[a.selector.cursor].selected
		case "a":
			allSelected := true
			for _, item := range a.selector.items {
				if !item.selected {
					allSelected = false
					break
				}
			}
			for i := range a.selector.items {
				a.selector.items[i].selected = !allSelected
			}
		case "enter":
			selected := a.selector.GetSelected()
			if len(selected) > 0 {
				a.installer = NewInstallerModel(selected)
				a.currentView = ViewInstaller
				return a, a.installer.Start()
			}
		case "esc":
			a.currentView = ViewWelcome
		case "q":
			return a, tea.Quit
		}
	}
	return a, nil
}

func (a App) updateInstaller(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd
	a.installer, cmd = a.installer.Update(msg)

	if a.installer.done {
		a.summary = NewSummaryModel(a.installer.results, a.installer.elapsed)
		a.summary.width = a.width
		a.currentView = ViewSummary
		return a, nil
	}

	return a, cmd
}

func (a App) updateStatus(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "esc", "q":
			a.currentView = ViewWelcome
		}
	}
	return a, nil
}

func (a App) updateSummary(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "enter", "esc", "q":
			return a, tea.Quit
		}
	}
	return a, nil
}
