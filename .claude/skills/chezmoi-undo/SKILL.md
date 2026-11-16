---
name: chezmoi-undo
description: Restore deployed files from a chezmoi backup, after showing what would change. Use when a `chezmoi apply` needs undoing, when the user asks to restore or roll back dotfiles, or to check what differs from a backup.
argument-hint: "[backup-id] [file ...]"
allowed-tools: Bash(bash *undo.sh*), Bash(ls *), Bash(readlink *), Read, AskUserQuestion
---

# /chezmoi-undo

## Current state

Contents of `~/.chezmoi-backups`:

```!
ls -1 ~/.chezmoi-backups || true
```

Latest backup: !`readlink ~/.chezmoi-backups/latest || true`

A backup is a folder that holds a `manifest.json`. Anything else in that directory (loose `.bak` files, folders without a manifest) is not one; ignore it. A folder ending in `_pre-undo` is the safety copy an earlier restore took.

## Step 1: choose the backup

If the skill was invoked with arguments, the first is the backup ID and any others are files to limit the restore to. With no arguments, use `latest`. If there are no backups, say so, point to `/chezmoi-backup`, and stop.

## Step 2: see what would change

Run the script in this skill's directory:

```
bash <this skill's directory>/undo.sh plan <backup-id> [file ...]
```

It changes nothing. For each file in the backup it prints `identical`, `differs` or `missing` (the deployed copy is gone), and it lists files that apply created after the backup. Read the backup's `manifest.json` for its date and note.

If every file is `identical`, there is nothing to undo. Say so and stop.

## Step 3: tell the user what a restore means

Show the backup's ID, date and note, and the list of files that differ or are missing. Do not print file contents; they can hold secrets. Then state plainly:

- A restore overwrites the deployed copies of those files with the backed-up ones.
- The chezmoi source is not changed. After the restore those files show as pending again, and the next `chezmoi apply` would redo the change. Follow with `/integrate-changes` to decide what the source should say.
- Files that apply created are left in place. Name them; removing them is the user's call.

## Step 4: ask

Ask with AskUserQuestion: restore every file that differs, restore only some (ask which), or cancel. Do not restore without an answer in this conversation, even if the user invoked the skill with a backup ID.

## Step 5: restore and verify

```
bash <this skill's directory>/undo.sh restore <backup-id> [file ...]
```

Before overwriting anything, the script saves the current copies into a new backup named `<timestamp>_pre-undo` and prints its ID. Then it copies the files back.

Run the `plan` command again to confirm the restored files are now `identical`.

## Report

- Each file restored, and any `FAILED` line with its error.
- The `_pre-undo` backup ID, as the way to reverse this restore: `/chezmoi-undo <that ID>`.
- Files apply created that are still in place.
- The reminder from step 3: the source is unchanged, so run `/integrate-changes` before the next apply.

## Rules

- Never delete a file from the home directory.
- Never edit the chezmoi source and never run `chezmoi apply`.
- Do the copying with the script, not by hand: it replaces symlinks correctly and takes the safety copy first.
