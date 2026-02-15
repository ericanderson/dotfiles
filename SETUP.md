# New Machine Setup

## Dotfiles
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply eanderson-cl
```

## Claude Code
After installing Claude Code, run:
```
/plugin marketplace add jarrodwatts/claude-hud
/plugin install claude-hud
```

Configuration is automatically applied by dotfiles.
