package platform

import (
	"os"
	"os/exec"
	"runtime"
	"strings"
)

// OS represents the detected operating system.
type OS string

const (
	MacOS   OS = "macos"
	Linux   OS = "linux"
	WSL     OS = "wsl"
	Unknown OS = "unknown"
)

// PackageManager represents the detected package manager.
type PackageManager string

const (
	Brew   PackageManager = "brew"
	Apt    PackageManager = "apt"
	Pacman PackageManager = "pacman"
	Dnf    PackageManager = "dnf"
	Zypper PackageManager = "zypper"
	Nix    PackageManager = "nix"
	NonePM PackageManager = "unknown"
)

// DetectOS returns the current operating system.
func DetectOS() OS {
	switch runtime.GOOS {
	case "darwin":
		return MacOS
	case "linux":
		data, err := os.ReadFile("/proc/version")
		if err == nil && strings.Contains(strings.ToLower(string(data)), "microsoft") {
			return WSL
		}
		return Linux
	default:
		return Unknown
	}
}

// DetectPackageManager returns the available package manager.
func DetectPackageManager() PackageManager {
	managers := []struct {
		cmd string
		pm  PackageManager
	}{
		{"brew", Brew},
		{"apt", Apt},
		{"pacman", Pacman},
		{"dnf", Dnf},
		{"zypper", Zypper},
		{"nix-env", Nix},
	}

	for _, m := range managers {
		if _, err := exec.LookPath(m.cmd); err == nil {
			return m.pm
		}
	}

	return NonePM
}

// SupportsModule checks if the current OS is in the module's platform list.
func SupportsModule(platforms []string) bool {
	current := DetectOS()
	for _, p := range platforms {
		if OS(p) == current || (current == WSL && OS(p) == Linux) {
			return true
		}
	}
	return false
}
