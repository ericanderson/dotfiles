# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository managed by [chezmoi](https://chezmoi.io/). It contains system configurations for macOS and Linux environments, including shell configurations, development tools, and package management.

## Key Commands

For detailed chezmoi command usage, use `/agent chezmoi-specialist`. Common commands:
- `chezmoi diff` - Preview changes before applying
- `chezmoi apply` - Apply configurations to system
- `chezmoi add [--template] <file>` - Add files to management

## Architecture and Structure

### Chezmoi Conventions

For comprehensive chezmoi naming conventions and patterns, use `/agent chezmoi-specialist`.
Key prefixes: `dot_` (dotfiles), `private_` (600 permissions), `run_once_` (one-time scripts), `.tmpl` (templates)

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

See these files for template examples:
- `dot_gitconfig.tmpl` - Conditional GPG signing for work/personal
- `Brewfile.tmpl` - Different packages for work/personal environments
- `private_dot_ssh/private_config.tmpl` - Work-specific SSH configurations
- `run_once_install-packages-darwin.sh.tmpl` - OS-specific installations

## Development Workflow

1. Edit files in the chezmoi source directory (this repository)
2. Run `chezmoi diff` to preview changes
3. Run `chezmoi apply` to apply changes
4. Commit with descriptive messages (see `/agent changes-documenter`)


## Change Tracking

Changes are documented in the `CHANGES/` directory. For creating properly formatted change entries, use `/agent changes-documenter`.

- `CHANGES/YYYY-MM-DD.md`: Daily change logs
- `CHANGES/TODO.md`: Pending tasks

## Claude Code Workflow Guidelines

- When recording changes, look for files in the CHANGES/ directory and follow the pattern you see there
- The `.chezmoiignore` file has formatting rules documented at the top of the file itself

## Available Sub-Agents

This repository includes specialized Claude Code sub-agents for common tasks. Use `/agent <name>` to invoke them:

### chezmoi-specialist
Expert in chezmoi operations, conventions, and template management. Use for:
- Understanding chezmoi naming conventions
- Debugging template issues
- Managing machine-specific configurations
- Executing chezmoi commands correctly

### dotfiles-migration-expert  
Specialist for migrating existing dotfiles to chezmoi management. Use for:
- Adding new configuration files to chezmoi
- Converting files to templates
- Updating .chezmoiignore appropriately
- Testing migrations across environments

### shell-config-specialist
Expert in shell configurations and cross-platform compatibility. Use for:
- Zsh/bash configuration changes
- PATH management issues
- Oh My Zsh plugin configuration
- Cross-platform (macOS/Linux) shell compatibility

### package-manager-expert
Specialist in Homebrew and package management. Use for:
- Managing Brewfile configurations
- Adding work vs personal packages
- Troubleshooting package installations
- Creating run_once installation scripts

### changes-documenter
Dedicated agent for maintaining CHANGES/ documentation. Use for:
- Creating properly formatted change entries
- Following repository documentation patterns
- Managing TODO.md items
- Ensuring consistent change tracking

## Ignored Files

See `.chezmoiignore` for the complete list of ignored file patterns, organized by category with descriptive headers.
- If you expect something in chezmoi diff and its not there, always check the .chezmoiignore file