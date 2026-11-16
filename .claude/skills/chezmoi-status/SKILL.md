---
name: chezmoi-status
description: Read-only overview of the dotfiles state - what `chezmoi apply` would change and which side changed, the source repo's git state, backups, and what to do next. Use when the user asks for chezmoi or dotfiles status, or at the start of any chezmoi work.
allowed-tools: Bash(chezmoi status*), Bash(chezmoi diff*), Bash(chezmoi git*), Bash(chezmoi managed*), Bash(chezmoi unmanaged*), Bash(chezmoi execute-template*), Bash(ls *), Bash(readlink *), Bash(wc *), Bash(grep *), Read
---

# /chezmoi-status

## Source repo

Branch and uncommitted changes:

```!
chezmoi git -- status --short --branch
```

Last commit: !`chezmoi git -- log -1 --oneline`

## Pending changes (externals excluded)

```!
chezmoi status --exclude=externals
```

- Lines apply would remove: !`chezmoi diff --exclude=externals --no-pager | grep '^-' | grep -v '^---' | wc -l`
- Lines apply would add: !`chezmoi diff --exclude=externals --no-pager | grep '^+' | grep -v '^+++' | wc -l`
- External entries that would update: !`chezmoi status --include=externals | wc -l`

## Machine

- Managed entries: !`chezmoi managed | wc -l`
- Unmanaged entries: !`chezmoi unmanaged | wc -l`
- Age identity: !`chezmoi execute-template '{{ $id := .chezmoi.config.age.identity }}{{ if and $id (stat $id) }}present ({{ $id }}){{ else }}not present{{ end }}'`

## Backups

```!
ls -1 ~/.chezmoi-backups || true
```

Latest: !`readlink ~/.chezmoi-backups/latest || true`

## How to read it

This skill is read-only. Run nothing that changes the source, the home directory or git.

**Pending changes.** Each line is two columns and a path:

| Columns | Meaning | Risk on apply |
|---|---|---|
| ` M` | Only the source changed since the last apply | Low: nothing local is lost |
| `MM` | The deployed file was edited too | Local edits would be overwritten |
| ` A` | Apply would create the file | Low, unless an unmanaged file is already there |
| ` D` | Apply would delete the entry | The entry is lost |
| ` R` | A script would run | Depends on the script; read its header to say what it does |

The line counts show size, not risk. A removed line may be a local edit about to be lost or a line deliberately deleted from the source; the columns say which.

**Source repo.** The first line shows the branch and whether it is ahead of or behind its remote. If the branch is not `master`, say so: `chezmoi apply` deploys whatever branch is checked out.

**Age identity.** This is the key file named in the chezmoi config, normally `~/.config/chezmoi/key.txt`. Without it, the settings template renders without the encrypted private auto-mode lines. On such a machine a pending removal of those lines from `~/.claude/settings.json` is expected and must not be "fixed" by capturing it into the source.

**Warnings.** If any block above contains "config file template has changed", the machine's chezmoi config is older than `.chezmoi.toml.tmpl`; recommend `chezmoi init`.

**Backups.** A backup is a folder holding a `manifest.json`. Other items in that directory are not backups. Count only the real ones.

## Report

Lead with one sentence that answers "is anything waiting, and is any of it risky?" Then:

```
## Source repo
Branch, ahead/behind, last commit, uncommitted files (list them).

## Pending changes
A table of the pending entries with what each status means here, or "None".
Removal and addition line counts. Externals count.

## Machine
Managed and unmanaged counts. Whether the age identity is present.

## Backups
How many, the latest and its date.

## Recommendations
```

Recommend only what the state calls for, most important first:

- Any `MM` or ` D` entry: `/integrate-changes` to decide direction before applying. If the latest backup predates those files' current contents, `/chezmoi-backup` first.
- Only ` M`, ` A` or ` R` entries: safe to review with `chezmoi diff` and apply.
- Uncommitted source changes: list them and suggest committing on a branch. Do not suggest `git add -A`.
- Branch behind its remote: a pull would change what apply does; mention it.
- More than about ten unmanaged entries: `/chezmoi-unmanaged`.
- Nothing pending, nothing uncommitted: say everything is in sync and stop.
