package module

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/ViniZap4/setup/internal/config"
	"github.com/ViniZap4/setup/internal/platform"
	"github.com/ViniZap4/setup/internal/symlink"
)

// Module represents a discovered module with its config and path.
type Module struct {
	Path   string
	Config *config.ModuleConfig
}

// LinkStatus holds the status of a single symlink.
type LinkStatus struct {
	Source string
	Target string
	Status string // "linked", "missing", "conflict", "wrong-target"
}

// ModuleStatus holds the overall status of a module.
type ModuleStatus struct {
	Name      string
	Supported bool
	Links     []LinkStatus
}

// Discover finds all modules in the given directory.
func Discover(modulesDir string) ([]Module, error) {
	entries, err := os.ReadDir(modulesDir)
	if err != nil {
		return nil, fmt.Errorf("reading modules directory: %w", err)
	}

	var modules []Module
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}

		manifestPath := filepath.Join(modulesDir, entry.Name(), "module.yaml")
		cfg, err := config.Load(manifestPath)
		if err != nil {
			continue // skip directories without valid module.yaml
		}

		modules = append(modules, Module{
			Path:   filepath.Join(modulesDir, entry.Name()),
			Config: cfg,
		})
	}

	return modules, nil
}

// GetStatus checks the symlink status of a module.
func GetStatus(m Module) ModuleStatus {
	status := ModuleStatus{
		Name:      m.Config.Name,
		Supported: platform.SupportsModule(m.Config.Platforms),
	}

	for _, link := range m.Config.Links {
		source := filepath.Join(m.Path, link.Source)
		s := symlink.Status(source, link.Target)
		status.Links = append(status.Links, LinkStatus{
			Source: link.Source,
			Target: link.Target,
			Status: s,
		})
	}

	return status
}

// IsFullyLinked returns true if all links are correctly established.
func IsFullyLinked(status ModuleStatus) bool {
	for _, l := range status.Links {
		if l.Status != "linked" {
			return false
		}
	}
	return len(status.Links) > 0
}

// Install runs the module's install.sh script.
func Install(m Module) error {
	scriptPath := filepath.Join(m.Path, "install.sh")
	if _, err := os.Stat(scriptPath); os.IsNotExist(err) {
		// No install script, just create symlinks
		return Link(m)
	}

	cmd := exec.Command("bash", scriptPath)
	cmd.Dir = m.Path
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

// Link creates all symlinks for a module without running install.sh.
func Link(m Module) error {
	for _, link := range m.Config.Links {
		source := filepath.Join(m.Path, link.Source)
		if err := symlink.SafeLink(source, link.Target); err != nil {
			return fmt.Errorf("linking %s: %w", link.Source, err)
		}
	}
	return nil
}
