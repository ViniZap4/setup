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

// Arch represents the detected CPU architecture.
type Arch string

const (
	AMD64       Arch = "amd64"
	ARM64       Arch = "arm64"
	UnknownArch Arch = "unknown"
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

// DetectArch returns the current CPU architecture.
func DetectArch() Arch {
	switch runtime.GOARCH {
	case "amd64":
		return AMD64
	case "arm64":
		return ARM64
	default:
		return UnknownArch
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

// SupportsModule checks if the current OS and architecture match the module's requirements.
func SupportsModule(platforms []string, architectures []string) bool {
	current := DetectOS()
	platformOK := false
	for _, p := range platforms {
		if OS(p) == current || (current == WSL && OS(p) == Linux) {
			platformOK = true
			break
		}
	}
	if !platformOK {
		return false
	}

	if len(architectures) == 0 {
		return true
	}

	currentArch := DetectArch()
	for _, a := range architectures {
		if Arch(a) == currentArch {
			return true
		}
	}
	return false
}
