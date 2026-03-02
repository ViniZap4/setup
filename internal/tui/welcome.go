package tui

import "fmt"

// WelcomeModel is the welcome screen with menu options.
type WelcomeModel struct {
	choices []string
	cursor  int
}

// NewWelcomeModel creates a new welcome screen.
func NewWelcomeModel() WelcomeModel {
	return WelcomeModel{
		choices: []string{
			"Install modules",
			"View status",
			"Quit",
		},
	}
}

// View renders the welcome screen.
func (m WelcomeModel) View() string {
	s := "\n"
	s += TitleStyle.Render("  setup") + "\n"
	s += SubtitleStyle.Render("  Modular dotfiles manager") + "\n\n"

	for i, choice := range m.choices {
		cursor := "  "
		style := UnselectedStyle
		if m.cursor == i {
			cursor = AccentStyle.Render("> ")
			style = SelectedStyle
		}
		s += fmt.Sprintf("  %s%s\n", cursor, style.Render(choice))
	}

	s += "\n" + HelpStyle.Render("  j/k: navigate • enter: select • q: quit")

	return s
}
