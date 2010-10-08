#!/bin/bash
export SVN_EDITOR="vim"

export CLICOLOR=1

# Path for my own execs
export PATH=${PATH}:~/bin

# Path for macports
#export PATH=/opt/local/bin:/opt/local/sbin:$PATH

if [ -f ~/.profile_local ]; then . ~/.profile_local; fi

if [ "`which brew`" ]; then 
	if [ -f `brew --prefix`/etc/bash_completion ]; then
		. `brew --prefix`/etc/bash_completion
	fi
fi


# Setup for RVM (SHOULD BE LAST!)
[[ -s $HOME/.rvm/scripts/rvm ]] && source $HOME/.rvm/scripts/rvm
# End Setup for RVM
