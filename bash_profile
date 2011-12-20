if [ -f ~/.profile ]; then . ~/.profile; fi
if [ -f ~/.bashrc ]; then . ~/.bashrc; fi
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
