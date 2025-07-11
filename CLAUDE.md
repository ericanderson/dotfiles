# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository managed by [chezmoi](https://chezmoi.io/). It contains system configurations for macOS and Linux environments, including shell configurations, development tools, and package management.

## Key Commands

### Applying Configuration Changes

```bash
# Apply all configuration changes to the system
chezmoi apply

# Preview what changes would be applied without making them
chezmoi diff

# Update from the repository and apply changes
chezmoi update
```

### Working with Templates

```bash
# Edit a template file (opens in $EDITOR)
chezmoi edit ~/.zshrc

# View template data available for use
chezmoi data
```

### Adding New Configurations

```bash
# Add an existing file to chezmoi management
chezmoi add ~/.config/some-app/config

# Add a file as a template
chezmoi add --template ~/.config/some-app/config
```

## Architecture and Structure

### Chezmoi Conventions

- Files prefixed with `dot_` become dotfiles (e.g., `dot_zshrc` → `~/.zshrc`)
- `.tmpl` suffix indicates template files processed with Go templates
- `private_` prefix for files with restricted permissions (600)
- `run_once_` scripts execute once per machine during `chezmoi apply`
- `run_onchange_` scripts run when their contents change

### Key Configuration Areas

1. **Shell Environment**
   - `dot_zshrc.tmpl`: Main Zsh configuration using Oh My Zsh with Powerlevel10k
   - `dot_bashrc_darwin` / `dot_bashrc_linux`: OS-specific bash configurations
   - Profile files handle environment setup and PATH management

2. **Package Management**
   - `Brewfile.tmpl`: Dynamically generated based on environment
   - `Brewfile.common`: Base packages for all environments
   - `Brewfile.work`: Additional packages for work machines

3. **Development Tools**
   - Git configuration with extensive aliases and merge strategies
   - Vim/Neovim configurations in `dot_vimrc` and `dot_config/nvim/`
   - tmux configuration for terminal multiplexing

### Template Variables

The repository uses chezmoi template variables including:

- `{{ .email }}`: User's email (from git config during install)
- `{{ .chezmoi.os }}`: Operating system (darwin, linux)
- `{{ .is_work }}`: Boolean flag for work environment
- `{{ .chezmoi.hostname }}`: Machine hostname (used for machine-specific logic)

### Machine-Specific Configurations

This repository uses template conditions to apply different configurations based on the machine:

- **Work machines**: Identified by hostname pattern `eanderson[0-9]+-mac`
- **Personal machines**: All other machines

Example template condition:

```go
{{- if and (eq .chezmoi.os "darwin") (regexMatch "eanderson[0-9]+-mac" .chezmoi.hostname) -}}
# Work machine specific config
{{- else -}}
# Personal machine config
{{- end -}}
```

## Development Workflow

When modifying configurations:

1. Edit the source file in the chezmoi directory (this repository)
2. Use `chezmoi diff` to preview changes
3. Apply with `chezmoi apply`
4. Commit changes to git with descriptive conventional commit messages

For template files, test variable substitution with:

```bash
chezmoi execute-template < path/to/file.tmpl
```

## SSH Configuration Management

The SSH config uses an Include directive to support machine-specific configurations:

- `private_dot_ssh/private_config.tmpl`: Template that includes `~/.ssh/local_config`
- `~/.ssh/local_config`: Machine-specific host configurations (not managed by chezmoi)
- This allows different SSH hosts on each machine while sharing common settings

To add machine-specific SSH hosts, edit `~/.ssh/local_config` directly.

## Change Tracking

Changes to this repository are documented in the `CHANGES/` directory:

- `CHANGES/YYYY-MM-DD.md`: Document actual changes made on specific dates
- `CHANGES/TODO.md`: For tracking pending changes and tasks

When recording changes, create date-based files following the existing pattern and focus on documenting what was actually changed, keeping things concise.

## Claude Code Workflow Guidelines

- When you record changes, look for files in the @CHANGES/ directory and follow the pattern you see there
