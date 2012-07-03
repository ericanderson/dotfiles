#!/bin/bash
export SVN_EDITOR="vim"

export CLICOLOR=1

# Path for my own execs
export PATH=${PATH}:~/bin

# Path for macports
#export PATH=/opt/local/bin:/opt/local/sbin:$PATH

if [ -f ~/.profile_local ]; then . ~/.profile_local; fi

if type -p brew >/dev/null 2>&1; then
	if [ -f `brew --prefix`/etc/bash_completion ]; then
		. `brew --prefix`/etc/bash_completion
	fi
fi

[[ `uname | tr 'A-Z' 'a-z'` == "darwin" ]] && export JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/CurrentJDK/Home/
