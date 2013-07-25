if [ -f ~/.profile ]; then . ~/.profile; fi
if [ -f ~/.bashrc ]; then . ~/.bashrc; fi

export PATH=$PATH:/Users/eanderson/Documents/Projects/Work/gitscripts/bin

sssh (){ ssh -t "$1" 'tmux attach || tmux new || screen -DR'; }
