if [ -f ~/.profile ]; then . ~/.profile; fi
if [ -f ~/.bashrc ]; then . ~/.bashrc; fi

export PATH=$PATH

sssh (){ ssh -t "$1" 'tmux attach || tmux new || screen -DR'; }
