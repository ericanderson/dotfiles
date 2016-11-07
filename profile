#!/bin/bash

# .profile
#
# Always loaded, should set stuff like path and editor and what not

export EDITOR="vim"

export CLICOLOR=1

# Path for my own execs
export PATH="$HOME/.rbenv/bin:$PATH"
export PATH=${PATH}:~/bin:~/go/bin
export GOPATH=~/go

export GO15VENDOREXPERIMENT=1
if [ -e ~/.gnupg/S.gpg-agent.ssh ]; then
	echo "Setting gpg as ssh agent"
	export SSH_AUTH_SOCK=~/.gnupg/S.gpg-agent.ssh
fi

if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

if [ -f ~/.profile_`uname | tr 'A-Z' 'a-z'` ]; then . ~/.profile_`uname | tr 'A-Z' 'a-z'`; fi
if [ -f ~/.profile_local ]; then . ~/.profile_local; fi

export PATH=${PATH}:./node_modules/.bin