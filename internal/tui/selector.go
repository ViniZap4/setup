package tui

import (
	"fmt"

	"github.com/ViniZap4/setup/internal/module"
)

// SelectorItem represents a module in the multi-select list.
type SelectorItem struct {
	module    module.Module
	selected  bool
	supported bool
}

// SelectorModel is the module multi-select screen.
type SelectorModel struct {
	items  []SelectorItem
	cursor int
}

// NewSelectorModel creates a new selector from discovered modules.
func NewSelectorModel(modules []module.Module) SelectorModel {
	items := make([]SelectorItem, len(modules))
	for i, m := range modules {
		supported := module.IsSupported(m)
		items[i] = SelectorItem{
			module:    m,
			selected:  supported,
			supported: supported,
		}
	}
	return SelectorModel{items: items}
}

// GetSelected returns the selected modules.
func (m SelectorModel) GetSelected() []module.Module {
	var selected []module.Module
	for _, item := range m.items {
		if item.selected {
			selected = append(selected, item.module)
		}
	}
	return selected
}

// View renders the module selector.
func (m SelectorModel) View() string {
	s := "\n"
	s += TitleStyle.Render("  Select modules to install") + "\n\n"

	for i, item := range m.items {
		cursor := "  "
		if m.cursor == i {
			cursor = AccentStyle.Render("> ")
		}

		check := DimStyle.Render("[ ]")
		if item.selected {
			check = SuccessStyle.Render("[x]")
		}

		name := UnselectedStyle.Render(item.module.Config.Name)
		if m.cursor == i {
			name = SelectedStyle.Render(item.module.Config.Name)
		}

		desc := DimStyle.Render(" — " + item.module.Config.Description)
		if !item.supported {
			name = DimStyle.Render(item.module.Config.Name)
			desc = DimStyle.Render(" — unsupported platform")
		}

		s += fmt.Sprintf("  %s%s %s%s\n", cursor, check, name, desc)
	}

	count := 0
	for _, item := range m.items {
		if item.selected {
			count++
		}
	}

	s += "\n" + SubtitleStyle.Render(fmt.Sprintf("  %d/%d selected", count, len(m.items)))
	s += "\n" + HelpStyle.Render("  j/k: navigate • space: toggle • a: toggle all • enter: install • esc: back")

	return s
}
