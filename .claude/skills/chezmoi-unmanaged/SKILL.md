---
name: chezmoi-unmanaged
description: Sort the entries in the home directory that chezmoi neither manages nor ignores into managed, ignored or deliberately left alone. Use when `chezmoi unmanaged` has grown, when the user asks to clean up or review unmanaged files, or to start managing a new config file.
allowed-tools: Bash(chezmoi unmanaged*), Bash(chezmoi add*), Bash(chezmoi status*), Bash(chezmoi git -- status*), Bash(ls *), Read, Edit, Glob, Grep, AskUserQuestion
---

# /chezmoi-unmanaged

## Unmanaged entries

```!
chezmoi unmanaged
```

## Goal

Each entry above ends in one of three states: managed by chezmoi, listed in `.chezmoiignore.tmpl`, or left unmanaged on purpose because the user said so. Work in groups, not one entry at a time.

## Rules

- **This repo is public.** Read a file before adding it. Do not add anything that holds a secret, a key or certificate, a token, a host name, an internal domain, a tailnet name, an IP address or personal data. If the user wants such a file synced anyway, stop and ask how; do not reach for `chezmoi add --encrypt` on your own, because a whole encrypted file makes `chezmoi apply` fail on every machine without the age key.
- **Ignore patterns are public too.** `.chezmoiignore.tmpl` is in the repo, so an exact file name written there is published. For a file whose name is itself personal or revealing, use a generic pattern (`*.p12`, `*.epub`) or leave it unmanaged; say which you chose.
- Never delete or move anything in the home directory.
- Never run `chezmoi apply`. Adding a file copies it into the source; it does not change the deployed file.
- Do not commit unless asked.

## Step 1: classify by name

Sort the entries into groups without opening them. Use `ls` on a directory to see what is inside when its name is not enough.

| Group | Typical entries | Default |
|---|---|---|
| Configuration worth syncing | A hand-edited dotfile or a small config directory for a tool used on several machines | Add |
| Application state | Caches, histories, lock files, tool data directories, backups an app wrote | Ignore |
| Not dotfiles | Documents, media, project folders, downloads | Ignore |
| Sensitive | Keys, certificates (`.p12`, `.pem`), credential stores, anything named for a secret | Ignore, never add |
| Owned by another tool | Files another installer manages and rewrites | Ignore, or leave if the ignore file says it cannot be ignored |

`.chezmoiignore.tmpl` already documents one case of the last kind: skills that workmux installs under `~/.claude/skills/` cannot be ignored, because the negation patterns for that directory take precedence. Leave those unmanaged and say why.

## Step 2: check the "add" candidates

Read each file you would add. Confirm it is hand-maintained configuration, not generated state, and that it passes the public-repo rule. Note whether it contains values that differ per machine (a home directory path, a hostname): if so it needs to be a template.

## Step 3: ask

Present the groups with your recommendation for each, then ask with AskUserQuestion: one question per group (add, ignore or leave), and a separate question for any entry you are unsure about. Do not ask about each entry in a large group individually.

## Step 4: carry out the answers

**Add:** `chezmoi add <path>`. Directories are added recursively by default. For a file with per-machine values, `chezmoi add --template <path>`, then edit the new source file to replace those values with template expressions.

**Ignore:** edit `.chezmoiignore.tmpl` in the source directory. Read the rules at the top of that file first and follow them:

- Patterns are relative to the home directory. **Never start one with `/`.** chezmoi 2.72 and later rejects a leading slash and then fails on every command.
- Put each entry in the section it belongs to; add a boxed header only when no section fits, with two blank lines before it.
- A pattern that starts with an exclamation mark re-includes a path and takes precedence, so an ignore under a re-included directory has no effect.

**Leave:** do nothing; list it in the report.

## Step 5: verify

- `chezmoi unmanaged` again: every entry handled as add or ignore should be gone from the list. If one remains, the ignore pattern does not match; fix it.
- `chezmoi status --exclude=externals`: a file just added should not appear as pending, because the source copy equals the deployed one. If any chezmoi command now errors, the last ignore edit is the likely cause; fix it before anything else.
- `chezmoi git -- status --short`: shows what changed in the source.

## Report

- Added: each path, and which became templates.
- Ignored: each pattern and the section it went in.
- Left unmanaged: each entry and why.
- Anything skipped under the public-repo rule, named without quoting its contents.
- The source files now uncommitted, and an offer to commit them on a branch.
