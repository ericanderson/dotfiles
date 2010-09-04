#!/bin/bash
export GIT_SSL_NO_VERIFY=TRUE
export SVN_EDITOR="vim"

# Path for my own execs
export PATH=${PATH}:~/bin

# Path for macports
#export PATH=/opt/local/bin:/opt/local/sbin:$PATH

if [ -f ~/.profile_local ]; then . ~/.profile_local; fi

if [ -f `brew --prefix`/etc/bash_completion ]; then
  . `brew --prefix`/etc/bash_completion
fi


# Setup for RVM (SHOULD BE LAST!)
[[ -s $HOME/.rvm/scripts/rvm ]] && source $HOME/.rvm/scripts/rvm
# End Setup for RVM
