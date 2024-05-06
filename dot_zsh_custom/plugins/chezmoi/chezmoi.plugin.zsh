# If Bun is not found, don't do the rest of the script
if (( ! $+commands[chezmoi] )); then
  return
fi

# If the completion file doesn't exist yet, we need to autoload it and
# bind it to `chezmoi`. Otherwise, compinit will have already done that.
if [[ ! -f "$ZSH_CACHE_DIR/completions/_chezmoi" ]]; then
  typeset -g -A _comps
  autoload -Uz _chezmoi
  _comps[bun]=_chezmoi
fi

chezmoi completion zsh >| "$ZSH_CACHE_DIR/completions/_chezmoi" &|

