package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/ViniZap4/setup/internal/module"
	"github.com/ViniZap4/setup/internal/platform"
	"github.com/ViniZap4/setup/internal/tui"
	tea "github.com/charmbracelet/bubbletea"
)

func main() {
	modulesDir := findModulesDir()

	if len(os.Args) > 1 {
		runCLI(modulesDir)
		return
	}

	app := tui.NewApp(modulesDir)
	p := tea.NewProgram(app, tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

func findModulesDir() string {
	exe, err := os.Executable()
	if err == nil {
		dir := filepath.Join(filepath.Dir(exe), "..", "modules")
		if info, err := os.Stat(dir); err == nil && info.IsDir() {
			abs, err := filepath.Abs(dir)
			if err == nil {
				return abs
			}
			return dir
		}
	}

	if info, err := os.Stat("modules"); err == nil && info.IsDir() {
		abs, _ := filepath.Abs("modules")
		return abs
	}

	home, _ := os.UserHomeDir()
	return filepath.Join(home, "setup", "modules")
}

func runCLI(modulesDir string) {
	switch os.Args[1] {
	case "status":
		cmdStatus(modulesDir)
	case "install":
		cmdInstall(modulesDir)
	case "link":
		cmdLink(modulesDir)
	case "update":
		cmdUpdate(modulesDir)
	case "help", "--help", "-h":
		printUsage()
	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n", os.Args[1])
		printUsage()
		os.Exit(1)
	}
}

func printUsage() {
	fmt.Println("Usage: setup [command]")
	fmt.Println()
	fmt.Println("Commands:")
	fmt.Println("  (no args)    Launch interactive TUI")
	fmt.Println("  status       Show module status")
	fmt.Println("  install      Install all or specific modules")
	fmt.Println("  link         Create symlinks without running install scripts")
	fmt.Println("  update       Pull latest for all submodules")
	fmt.Println("  help         Show this help")
	fmt.Println()
	fmt.Println("Examples:")
	fmt.Println("  setup                    # interactive TUI")
	fmt.Println("  setup install            # install all supported modules")
	fmt.Println("  setup install zsh-config # install specific module")
	fmt.Println("  setup status             # show symlink status")
}

func cmdStatus(modulesDir string) {
	modules, err := module.Discover(modulesDir)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error discovering modules: %v\n", err)
		os.Exit(1)
	}

	detectedOS := platform.DetectOS()
	arch := platform.DetectArch()
	pm := platform.DetectPackageManager()
	fmt.Printf("OS: %s | Arch: %s | Package Manager: %s\n\n", detectedOS, arch, pm)

	for _, mod := range modules {
		status := module.GetStatus(mod)
		linked := module.IsFullyLinked(status)

		icon := "○"
		if linked {
			icon = "●"
		}

		supported := ""
		if !status.Supported {
			icon = "⊘"
			supported = " (unsupported platform)"
		}

		fmt.Printf("%s %s%s\n", icon, status.Name, supported)

		for _, link := range status.Links {
			fmt.Printf("  %s %s → %s\n", link.Status, link.Source, link.Target)
		}
	}
}

func cmdInstall(modulesDir string) {
	modules, err := module.Discover(modulesDir)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error discovering modules: %v\n", err)
		os.Exit(1)
	}

	targets := os.Args[2:]
	if len(targets) > 0 && targets[0] != "all" {
		modules = filterModules(modules, targets)
	}

	for _, mod := range modules {
		if !module.IsSupported(mod) {
			fmt.Printf("  ⊘ %s (unsupported platform, skipping)\n", mod.Config.Name)
			continue
		}
		fmt.Printf("Installing %s...\n", mod.Config.Name)
		if err := module.Install(mod); err != nil {
			fmt.Fprintf(os.Stderr, "  ✖ %s: %v\n", mod.Config.Name, err)
		} else {
			fmt.Printf("  ✔ %s\n", mod.Config.Name)
		}
	}
}

func cmdLink(modulesDir string) {
	modules, err := module.Discover(modulesDir)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error discovering modules: %v\n", err)
		os.Exit(1)
	}

	targets := os.Args[2:]
	if len(targets) > 0 {
		modules = filterModules(modules, targets)
	}

	for _, mod := range modules {
		if !module.IsSupported(mod) {
			fmt.Printf("  ⊘ %s (unsupported platform, skipping)\n", mod.Config.Name)
			continue
		}
		fmt.Printf("Linking %s...\n", mod.Config.Name)
		if err := module.Link(mod); err != nil {
			fmt.Fprintf(os.Stderr, "  ✖ %s: %v\n", mod.Config.Name, err)
		} else {
			fmt.Printf("  ✔ %s\n", mod.Config.Name)
		}
	}
}

func cmdUpdate(modulesDir string) {
	fmt.Println("Updating all submodules...")
	absDir, _ := filepath.Abs(modulesDir)
	repoDir := filepath.Dir(absDir)
	c := exec.Command("git", "submodule", "update", "--remote", "--merge")
	c.Dir = repoDir
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	if err := c.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Error updating submodules: %v\n", err)
		os.Exit(1)
	}
	fmt.Println("✔ All submodules updated")
}

func filterModules(modules []module.Module, names []string) []module.Module {
	nameSet := make(map[string]bool, len(names))
	for _, n := range names {
		nameSet[n] = true
	}

	var filtered []module.Module
	for _, m := range modules {
		if nameSet[m.Config.Name] {
			filtered = append(filtered, m)
		}
	}
	return filtered
}
