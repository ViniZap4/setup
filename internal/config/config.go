package config

import (
	"os"

	"gopkg.in/yaml.v3"
)

// Link represents a symlink mapping from source to target.
type Link struct {
	Source string `yaml:"source"`
	Target string `yaml:"target"`
}

// Dependencies lists packages per package manager.
type Dependencies struct {
	Brew   []string `yaml:"brew,omitempty"`
	Apt    []string `yaml:"apt,omitempty"`
	Pacman []string `yaml:"pacman,omitempty"`
	Dnf    []string `yaml:"dnf,omitempty"`
	Zypper []string `yaml:"zypper,omitempty"`
	Nix    []string `yaml:"nix,omitempty"`
}

// ModuleConfig is the parsed module.yaml manifest.
type ModuleConfig struct {
	Name         string       `yaml:"name"`
	Description  string       `yaml:"description"`
	Platforms    []string     `yaml:"platforms"`
	Links        []Link       `yaml:"links"`
	Dependencies Dependencies `yaml:"dependencies"`
}

// Load reads and parses a module.yaml file.
func Load(path string) (*ModuleConfig, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	var cfg ModuleConfig
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return nil, err
	}

	return &cfg, nil
}
