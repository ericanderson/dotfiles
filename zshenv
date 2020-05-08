# Always loaded, should set stuff like path and editor and what not
export EDITOR="vim"
export CLICOLOR=1

export LSCOLORS=DxFxCxDxBxegedabagacad

# Path for my own execs
path=(
  '~/.rbenv/bin'
  $path
  '~/bin',
  './node_modules/.bin'
)

if which yarn > /dev/null; then path+=`yarn global bin`; fi

if type gpgconf &>/dev/null; then
  SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
  export SSH_AUTH_SOCK
fi

if which rbenv > /dev/null; then eval "$(rbenv init - zsh)"; fi

if [ -f ~/.zshenv`uname | tr 'A-Z' 'a-z'` ]; then . ~/.zshenv_`uname | tr 'A-Z' 'a-z'`; fi
if [ -f ~/.zshenv_local ]; then . ~/.zshenv_local; fi

