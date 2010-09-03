#!/bin/bash
export GIT_SSL_NO_VERIFY=TRUE
export SVN_EDITOR="vim"

# Path for my own execs
export PATH=${PATH}:~/bin

# Path for macports
export PATH=/opt/local/bin:/opt/local/sbin:$PATH


# Setup for RVM (SHOULD BE LAST!)
[[ -s $HOME/.rvm/scripts/rvm ]] && source $HOME/.rvm/scripts/rvm
# End Setup for RVM