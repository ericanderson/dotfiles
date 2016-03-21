#!/bin/bash

# .profile
#
# Always loaded, should set stuff like path and editor and what not

export EDITOR="vim"

export CLICOLOR=1

# Path for my own execs
export PATH="$HOME/.rbenv/bin:$PATH"
export PATH=${PATH}:~/bin
export GOPATH=~/go
export PATH=${PATH}:~/go/bin
eval "$(rbenv init -)"
if [ -f ~/.profile_`uname | tr 'A-Z' 'a-z'` ]; then . ~/.profile_`uname | tr 'A-Z' 'a-z'`; fi
if [ -f ~/.profile_local ]; then . ~/.profile_local; fi
