---
name: integrate-changes
description: Work out, file by file, whether pending chezmoi differences should be applied to the home directory or folded back into the source, then carry out the source-side half. Use when `chezmoi diff` or `chezmoi status` shows pending changes, before any `chezmoi apply`, or when the user asks to integrate, reconcile or review chezmoi drift.
allowed-tools: Bash(chezmoi status*), Bash(chezmoi diff*), Bash(chezmoi source-path*), Bash(chezmoi git*), Bash(chezmoi re-add*), Bash(chezmoi decrypt*), Bash(chezmoi encrypt*), Bash(readlink *), Read, Edit, AskUserQuestion
---

# /integrate-changes

## Current state

Pending changes (externals excluded):

```!
chezmoi status --exclude=externals
```

Uncommitted changes in the source repo:

```!
chezmoi git -- status --short
```

Latest backup: !`readlink ~/.chezmoi-backups/latest || true`

## Goal

Every pending file ends in one of two states: the deployed file matches the source because the source was right, or the source was changed to match the deployed file because the deployed file was right. Nothing is left as unexplained drift.

A diff has two sides and either can be the stale one. A `-` line may be a local edit that apply would destroy, or a line deliberately deleted from the source. A `+` line may be a new source change, or something the user removed locally that apply would bring back. Line direction alone never tells you the risk; where the change came from does.

## Rules

- Never run `chezmoi apply`, with or without targets. The user runs it. Give them the exact command.
- Never use `--force`.
- Change the source (edits, `chezmoi re-add`) only after the user has chosen a direction for that file.
- Do not print secret values (tokens, keys, passwords) in the analysis. Say that a line holds a secret and name the key.
- Run one command per Bash call, with no pipes or `&&`. A hook in this setup refuses chained git commands. Use `chezmoi git -- <args>` for git in the source repo.

## Step 1: find where each change came from

Read the status block above. The two columns mean:

| Columns | Meaning |
|---|---|
| ` M` | Only the source moved. The deployed file is as chezmoi last wrote it. |
| `MM` | The deployed file was edited since the last apply, and apply would change it. Local edits are at stake. |
| ` A` | Apply would create the file. Check that nothing unmanaged already sits at that path. |
| ` D` | Apply would delete the entry. |
| ` R` | A script would run. See below. |

If the status block is empty, say everything is in sync and stop.

For each pending file, gather:

1. `chezmoi diff <target>` for the content.
2. `chezmoi source-path <target>` for the source file. Note whether it ends in `.tmpl`; that decides how a deployed-side change can be kept.
3. `chezmoi git -- log --oneline -5 -- <source file>` and whether the source file is in the uncommitted list above. Recent commits or uncommitted edits that explain a hunk mean the source side is intentional. A hunk no commit explains, in an `MM` file, came from the deployed side: an app, a UI toggle or a manual edit.

Classify each hunk, not just each file. One file often holds both kinds.

**Scripts.** A `run_once_` or `run_onchange_` source shows in the diff as a new file at its rendered name. Nothing is deployed; chezmoi runs it and discards it. Report it as "this script will run" and say what it does (for example, `brew bundle` installs and upgrades packages).

**Conflicts in kind.** If apply would replace a directory with a symlink or the reverse, say exactly what would be deleted. Treat it as the highest risk in the report.

**Externals.** Run `chezmoi status --include=externals` once and report how many external entries would update. Do not analyse their content.

## Step 2: flag what needs extra care

Call these out in their own section, whichever direction they run:

- **Security posture in `~/.claude/settings.json`**: any change to `permissions` (allow, ask, deny), `sandbox`, `hooks`, `autoMode` or `enabledPlugins`. Dropping a deny rule or turning off the sandbox is not ordinary drift. State plainly what protection would be lost or gained.
- **Infrastructure details headed for the source**: this repo is public. A deployed-side hunk that names a host, an internal domain, a tailnet or an IP address must not be captured as plain text. The name of one of Eric's private GitHub repos is fine. For `settings.json` auto-mode entries, it goes into the encrypted `.private/claude.json.age` (see step 6). For anything else, stop and ask.
- **Secrets**: lines holding credentials on either side.
- **Deletions**: whole files or directories apply would remove.
- **Credential and identity config**: `.gitconfig` credential helpers and signing, anything under `.ssh/`.

## Step 3: check the backup

Read `manifest.json` in the latest backup. If any `MM` or ` D` file is missing from it, or the file has changed since that backup was taken, tell the user to run `/chezmoi-backup` before they apply anything. Source-side work does not need a backup; git covers it.

## Step 4: report

Lead with the findings, not with counts.

```
## Chezmoi integration analysis

[One or two sentences: how many files, how many have local edits at stake, anything from step 2.]

| File | Status | Where the change came from | Recommended direction |
|---|---|---|---|

### Needs extra care
[Step 2 findings, or omit the section.]

### Per file
**~/.example** (template: yes/no)
- [hunk]: [what it is, which side it came from, evidence such as a commit hash]
- Recommendation: [direction and why]

### Backup
[Covered by <id>, or run /chezmoi-backup first.]
```

Show the actual diff lines for hunks where local content would be lost. Summarise the rest.

## Step 5: get decisions

Ask with AskUserQuestion, recommended option first. Group files that share an origin and a recommendation into one question (for example, "these three changed only in the source: apply all?"). Ask about a file on its own when it has mixed hunks or a step 2 flag. The directions are:

- **Source wins**: apply will overwrite the deployed file.
- **Deployed wins**: the source is changed to match the deployed file.
- **Split**: some hunks each way. Ask which.
- **Leave for now**: no change. Record it in the summary as still open.

## Step 6: carry out the source-side half

For each file where the deployed side wins, fully or for some hunks:

- **Plain file** (no `.tmpl`): `chezmoi re-add <target>` when the whole file wins. For a split, edit the source file by hand.
- **Template**: `re-add` will not overwrite templates. Edit the `.tmpl` source by hand so it renders the wanted content, keeping the template logic (conditionals, variables) intact. Do not paste rendered values over template expressions.
- **Home directory paths**: a captured line that contains a literal home path (`/Users/<name>/...`) is written into the source as `~`, `$HOME` or `{{ joinPath .chezmoi.homeDir "..." }}`, whichever the reading program accepts, never as the literal. See "Never hard-code a home directory" in `CLAUDE.md`.
- **Private auto-mode entries**: `autoMode.allow` and `autoMode.environment` lines that describe the homelab live in `.private/claude.json.age` as JSON (`autoModeAllow`, `autoModeEnvironment`), and the settings template splices them in after the public entries. To add or change one, decrypt to the scratchpad with `chezmoi decrypt`, edit the JSON there, and write it back with `chezmoi encrypt -o .private/claude.json.age <file>`. Never put the decrypted file in the source directory. The user can instead run `chezmoi edit-encrypted .private/claude.json.age` themselves. This only works on a machine that has `~/.config/chezmoi/key.txt`; without it the private lines show as a pending removal that must not be applied or captured.
- `chezmoi merge <target>` opens an interactive merge tool. Do not run it; mention it if the user would rather merge by hand.

Then verify with `chezmoi diff <target>`. A file where the deployed side won outright should show no diff. A split file should show only the hunks the user chose to apply.

## Step 7: hand over

Finish with:

1. What was changed in the source, per file.
2. The exact apply command for the files where the source wins, one target per file, never a bare `chezmoi apply` unless every pending file was approved:
   `chezmoi apply ~/.zshrc ~/.gitconfig`
3. A note that the source repo now has uncommitted changes, with the file list, and an offer to commit.
4. Anything left open.
5. `/chezmoi-undo <backup id>` as the way back.
