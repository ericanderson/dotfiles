---
name: chezmoi-backup
description: Save the current deployed copy of every file that `chezmoi apply` would change, so an apply can be undone. Use before applying pending chezmoi changes, when the user asks for a backup of their dotfiles state, or when another chezmoi skill says a backup is needed.
argument-hint: "[note]"
allowed-tools: Bash(bash *backup.sh*), Bash(chezmoi status*), Bash(readlink *), Read
---

# /chezmoi-backup

## Current state

Files `chezmoi apply` would change (externals and scripts excluded):

```!
chezmoi status --exclude=externals,scripts
```

Latest backup: !`readlink ~/.chezmoi-backups/latest || true`

## What to do

Run the script in this skill's directory once:

```
bash <this skill's directory>/backup.sh "<note>"
```

For the note, use the arguments the skill was invoked with, if any. Otherwise write one line saying why the backup is being taken, for example "before applying the gitconfig change".

The script does the whole job: it reads `chezmoi status`, copies each pending file from the home directory into `~/.chezmoi-backups/<timestamp>/files/` with modes and symlinks kept, saves the pending diff and a `manifest.json`, and repoints the `latest` symlink. Do not reimplement those steps by hand.

If the list above is empty, there is nothing to back up. Say so and stop; the script would say the same and create nothing.

## Rules

- This skill never runs `chezmoi apply` and never changes the source or the home directory. It only writes under `~/.chezmoi-backups/`.
- Do not print the contents of the saved diff or of backed-up files. They can hold secrets and the decrypted private lines from `.private/claude.json.age`.
- Backups stay in the home directory. Never copy one into the chezmoi source: this repo is public.

## Report

Tell the user:

- the backup ID and location;
- each file saved;
- any file listed as `new` (apply would create it, so there was nothing to save; `/chezmoi-undo` will not remove it);
- any `FAILED` line, with the script's error. A failure means that file is not protected, so say that before anything else.

Then give the next steps: `/integrate-changes` to decide what to apply, and `/chezmoi-undo <backup ID>` as the way back.
