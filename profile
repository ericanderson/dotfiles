
# Always loaded, should set stuff like path and editor and what not
export EDITOR="vim"

export CLICOLOR=1

# Path for my own execs
export PATH="$HOME/.rbenv/bin:$PATH"
export PATH=${PATH}:~/bin:~/src/go/bin
export GOPATH=~/src/go

export GO15VENDOREXPERIMENT=1

if [ -f "${HOME}/.gpg-agent-info" ]; then
	. "${HOME}/.gpg-agent-info"
	export GPG_AGENT_INFO
	export SSH_AUTH_SOCK
fi
export GPG_TTY=$(tty)

if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

if which yarn > /dev/null; then export PATH="$PATH:`yarn global bin`"; fi

if [ -f ~/.profile_`uname | tr 'A-Z' 'a-z'` ]; then . ~/.profile_`uname | tr 'A-Z' 'a-z'`; fi
if [ -f ~/.profile_local ]; then . ~/.profile_local; fi

export PATH=${PATH}:./node_modules/.bin