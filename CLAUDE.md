# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository managed by [chezmoi](https://chezmoi.io/). It contains system configurations for macOS and Linux environments, including shell configurations, development tools, and package management.

## Key Commands

For detailed chezmoi command usage, ask for the `chezmoi-specialist` agent (or `@agent-chezmoi-specialist`). Common commands:
- `chezmoi diff` - Preview changes before applying
- `chezmoi apply` - Apply configurations to system
- `chezmoi add [--template] <file>` - Add files to management

## ⚠️ CRITICAL CHEZMOI SAFETY RULES

**NEVER use `chezmoi apply --force` without explicit user permission!**

When encountering chezmoi conflicts:
1. **STOP** - Do not automatically resolve conflicts
2. **INVESTIGATE** - Check what the conflict is about using `chezmoi diff`
3. **EXPLAIN** - Tell the user exactly what would be overwritten
4. **ASK** - Get explicit permission before using `--force`
5. **BACKUP** - Suggest creating backups before destructive operations

Common conflict scenarios:
- **Symlink vs Directory**: If chezmoi wants to create a symlink where a directory exists (or vice versa), this will DELETE the existing content
- **Modified files**: Local changes that differ from chezmoi templates
- **Permission changes**: Files with different permissions than expected

Safe conflict resolution:
- Use `chezmoi apply --dry-run` to preview without changes
- Use `chezmoi apply --verbose` to see detailed operations
- ONLY use `--force` after explicit user consent and understanding of data loss

## Architecture and Structure

### Chezmoi Conventions

For comprehensive chezmoi naming conventions and patterns, ask for the `chezmoi-specialist` agent (or `@agent-chezmoi-specialist`).
Key prefixes: `dot_` (dotfiles), `private_` (600 permissions), `run_once_` (one-time scripts), `.tmpl` (templates)

### Key Configuration Areas

1. **Shell Environment**
   - `dot_zshrc.tmpl`: Main Zsh configuration using Oh My Zsh with Powerlevel10k
   - `dot_bashrc_darwin` / `dot_bashrc_linux`: OS-specific bash configurations
   - Profile files handle environment setup and PATH management

2. **Package Management**
   - `Brewfile.tmpl`: Template that includes `Brewfile.common`
   - `Brewfile.common`: Package list

3. **Development Tools**
   - Git configuration with extensive aliases and merge strategies
   - Vim/Neovim configurations in `dot_vimrc` and `dot_config/nvim/`
   - tmux configuration for terminal multiplexing

### Template Variables

The repository uses chezmoi template variables including:

- `{{ .email }}`: User's email (from git config during install)
- `{{ .chezmoi.os }}`: Operating system (darwin, linux)
- `{{ .chezmoi.hostname }}`: Machine hostname

### Never hard-code a home directory

Do not write `/Users/eanderson`, `/home/<name>` or any other literal home path when an alternative exists. These files are deployed to machines with different users and operating systems. Use, in order of preference:

- `~` or `$HOME`, when the program reading the file expands them (shell scripts, most Claude Code settings such as permission rules and sandbox paths).
- `{{ .chezmoi.homeDir }}` or `{{ joinPath .chezmoi.homeDir "..." }}` in a template, when the program needs an absolute path. Turn the file into a `.tmpl` if that is what it takes.
- `{{ .chezmoi.sourceDir }}` for paths into this repo.

The same applies when capturing a deployed file into the source: an app that wrote an absolute home path gets it replaced with one of the above, not copied as is. A literal home path is acceptable only inside a comment or where none of these work, and then say why next to it.

### Machine-Specific Configurations

There is no work/personal split; every machine gets the same configuration. Templates vary only by OS and by what exists on the machine at apply time:

- `dot_gitconfig.tmpl` - `gh` credential helper only when a real `gh` is installed (fixed install paths first, then `lookPath`; never the claude-flow wrapper)
- `private_dot_ssh/private_config.tmpl` - OrbStack include and FIDO2 `IdentityFile`s only when present (`stat`)
- `dot_claude/private_settings.json.tmpl` - herdr `SessionStart` hook only when herdr's script exists (`stat`); private auto-mode entries only when the age identity exists
- `run_once_install-packages-darwin.sh.tmpl` - OS-specific installations

### This repo is public: private data is encrypted

Never commit a host name, internal domain, tailnet name or IP address as plain text. The names of Eric's private GitHub repos (for example `boss-board`) are fine to publish; what is inside them is not. The auto-mode entries in `~/.claude/settings.json` that describe the homelab are age-encrypted in `.private/claude.json.age` and spliced into the settings template at apply time.

- The identity is `~/.config/chezmoi/key.txt` (master copy in 1Password). A machine without it renders settings without the private entries; that is expected, not drift.
- The public half is `.private/age-recipients.txt`. `.chezmoi.toml.tmpl` points chezmoi at both.
- Edit the private entries with `chezmoi edit-encrypted .private/claude.json.age`. Never leave a decrypted copy in the source directory.

## Reading `chezmoi diff` Output

`chezmoi diff` shows what would change in the **deployed** (home directory) files if you ran `chezmoi apply`. A `-` line means that content exists in the deployed file but NOT in the chezmoi source — applying would **remove** it.

**Always run diff in two modes:**
1. `chezmoi diff --exclude externals` — shows only files we directly manage in this repo. Use this to understand **our** changes.
2. `chezmoi diff --include externals` — shows what external sources (e.g., oh-my-zsh) would update. Useful for understanding the full scope of an `apply` but not our direct changes.

When you see removals (`-` lines) in managed files, always ask: **why is this line missing from chezmoi source?**

- **Intentional removal**: The user deleted it from the chezmoi source file → applying is correct
- **External modification**: Something (an app, a manual edit, another tool) added it directly to the deployed file and it was never in chezmoi → applying would silently destroy it

When you see additions (`+` lines) in managed files, always ask: **does the user actually want this added back?**

- **Intentional addition**: We added it to the chezmoi source → applying is correct
- **Stale source**: The user removed it from the deployed file (e.g., via a UI or manual edit) but the chezmoi source still has the old value → applying would silently revert the user's change. Remove it from chezmoi source instead.

Before applying or ignoring diffs, **flag unexpected changes in both directions to the user**. Ask whether the chezmoi source or the deployed file represents the desired state.

### `run_once_` scripts in diff output

A `run_once_` source script (e.g. `run_once_install-packages-darwin.sh.tmpl`) appears in `chezmoi diff` as a brand-new file at the target path (`install-packages-darwin.sh` in the home dir). **It is not actually deployed as a persistent file.** Chezmoi materializes it as a temporary script, executes it, and uses its rendered content to compute a hash so the script is only re-run when its content changes. If the only "new file" in the diff is a `run_once_` artifact, treat it as a script-execution event, not a file creation — there's nothing to back up, and the file won't be sitting in the home directory afterward.

## Development Workflow

1. Edit files in the chezmoi source directory (this repository)
2. Run `chezmoi diff` to preview changes
3. Run `chezmoi apply` to apply changes
4. On `master`, branch to `claude/<topic>`, add a `CHANGES/YYYY-MM-DD.md` entry, and open a PR to `master`

## Gotchas

- `claude plugin install/uninstall` rewrites `~/.claude/settings.json`. Mirror the change in `enabledPlugins` in `dot_claude/private_settings.json.tmpl`, or the next `chezmoi apply` reverts it.
- When something other than chezmoi has rewritten a deployed file, `chezmoi apply` needs a TTY to confirm ("could not open a new TTY"). Claude can't answer it, so ask Eric to run the apply.
- Tests live in `.tests/`. chezmoi never deploys dot-prefixed source entries. Run: `python3 -I .tests/<name>_test.py`.

## Change Tracking

Changes are documented in the `CHANGES/` directory. For creating properly formatted change entries, ask for the `changes-documenter` agent (or `@agent-changes-documenter`).

- `CHANGES/YYYY-MM-DD.md`: Daily change logs
- `CHANGES/TODO.md`: Pending tasks

## Claude Code Workflow Guidelines

- When recording changes, look for files in the CHANGES/ directory and follow the pattern you see there
- The `.chezmoiignore.tmpl` file has formatting rules documented at the top of the file itself

## Project Skills

Skills in `.claude/skills/`:

- `chezmoi-status`: read-only overview of pending changes, repo state and backups. Start here.
- `integrate-changes`: decide, file by file, whether to apply or fold back into the source. Use before any `chezmoi apply`.
- `chezmoi-backup`: save the deployed copy of every file an apply would change.
- `chezmoi-undo`: restore deployed files from a backup.
- `chezmoi-unmanaged`: sort home-directory entries chezmoi neither manages nor ignores.

## Available Sub-Agents

This repository includes specialized Claude Code sub-agents in `.claude/agents/`. To invoke one, ask for it by name or mention it as `@agent-<name>`:

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
- Updating `.chezmoiignore.tmpl` appropriately
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

See `.chezmoiignore.tmpl` for the complete list of ignored file patterns, organized by category with descriptive headers.
- If you expect something in chezmoi diff and its not there, always check the `.chezmoiignore.tmpl` file