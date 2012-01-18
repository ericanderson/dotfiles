if [ -f ~/.profile ]; then . ~/.profile; fi
if [ -f ~/.bashrc ]; then . ~/.bashrc; fi

[ -d $HOME/.rbenv ] && export PATH="$HOME/.rbenv/bin:$PATH"
[ -d /usr/local/rbenv ] && export PATH="/usr/local/rbenv/bin:$PATH"

type -p rbenv && eval "$(rbenv init -)"
