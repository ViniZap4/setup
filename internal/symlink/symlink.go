package symlink

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// ExpandHome replaces ~ with the user's home directory.
func ExpandHome(path string) string {
	if strings.HasPrefix(path, "~/") {
		home, err := os.UserHomeDir()
		if err != nil {
			return path
		}
		return filepath.Join(home, path[2:])
	}
	return path
}

// IsCorrectLink checks if target is a symlink pointing to source.
func IsCorrectLink(source, target string) bool {
	target = ExpandHome(target)
	link, err := os.Readlink(target)
	if err != nil {
		return false
	}
	absSource, _ := filepath.Abs(source)
	absLink, _ := filepath.Abs(link)
	return absSource == absLink
}

// Status returns the symlink status for a target.
// Returns: "linked", "missing", "conflict", or "wrong-target"
func Status(source, target string) string {
	target = ExpandHome(target)

	info, err := os.Lstat(target)
	if os.IsNotExist(err) {
		return "missing"
	}

	if info.Mode()&os.ModeSymlink != 0 {
		if IsCorrectLink(source, target) {
			return "linked"
		}
		return "wrong-target"
	}

	return "conflict"
}

// SafeLink creates a symlink from source to target, backing up existing files.
func SafeLink(source, target string) error {
	target = ExpandHome(target)

	// Ensure parent directory exists
	dir := filepath.Dir(target)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return fmt.Errorf("creating directory %s: %w", dir, err)
	}

	// Handle existing file/symlink
	info, err := os.Lstat(target)
	if err == nil {
		if info.Mode()&os.ModeSymlink != 0 {
			// Remove existing symlink
			os.Remove(target)
		} else {
			// Backup existing file/directory
			backup := fmt.Sprintf("%s.backup.%s", target, time.Now().Format("20060102150405"))
			if err := os.Rename(target, backup); err != nil {
				return fmt.Errorf("backing up %s: %w", target, err)
			}
		}
	}

	absSource, err := filepath.Abs(source)
	if err != nil {
		return fmt.Errorf("resolving source path: %w", err)
	}

	if err := os.Symlink(absSource, target); err != nil {
		return fmt.Errorf("creating symlink %s -> %s: %w", target, absSource, err)
	}

	return nil
}
