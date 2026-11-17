# New Machine Setup

## Dotfiles
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply eanderson-cl
```

## Private settings (optional)
This repo is public, so the Claude auto-mode entries that describe the homelab are
age-encrypted in `.private/claude.json.age`. A machine without the key works fine and
just leaves those entries out. To get them, fetch the key from 1Password and re-apply:
```bash
op document get "chezmoi age key" --out-file ~/.config/chezmoi/key.txt
chezmoi init    # only needed if this machine's config predates the age setup
chezmoi apply ~/.claude/settings.json
```
Without the `op` CLI, copy the key file to `~/.config/chezmoi/key.txt` by hand and
`chmod 600` it. Edit the entries with `chezmoi edit-encrypted .private/claude.json.age`.

## Claude Code
After installing Claude Code, run:
```
/plugin marketplace add jarrodwatts/claude-hud
/plugin install claude-hud
```

Configuration is automatically applied by dotfiles.
