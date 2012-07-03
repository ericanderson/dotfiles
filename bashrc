export UNISONLOCALHOSTNAME=`hostname`
export PATH=/usr/local/bin:${PATH}

if [ -f ~/.bashrc_`uname | tr 'A-Z' 'a-z'` ]; then . ~/.bashrc_`uname | tr 'A-Z' 'a-z'`; fi

if [ -f ~/.bashrc_local ]; then . ~/.bashrc_local; fi

export LSCOLORS=DxFxCxDxBxegedabagacad

# Setup Prompt
txtblk='\e[0;30m' # Black - Regular
txtred='\e[0;31m' # Red
txtgrn='\e[0;32m' # Green
txtylw='\e[0;33m' # Yellow
txtblu='\e[0;34m' # Blue
txtpur='\e[0;35m' # Purple
txtcyn='\e[0;36m' # Cyan
txtwht='\e[0;37m' # White
bldblk='\e[1;30m' # Black - Bold
bldred='\e[1;31m' # Red
bldgrn='\e[1;32m' # Green
bldylw='\e[1;33m' # Yellow
bldblu='\e[1;34m' # Blue
bldpur='\e[1;35m' # Purple
bldcyn='\e[1;36m' # Cyan
bldwht='\e[1;37m' # White
unkblk='\e[4;30m' # Black - Underline
undred='\e[4;31m' # Red
undgrn='\e[4;32m' # Green
undylw='\e[4;33m' # Yellow
undblu='\e[4;34m' # Blue
undpur='\e[4;35m' # Purple
undcyn='\e[4;36m' # Cyan
undwht='\e[4;37m' # White
bakblk='\e[40m'   # Black - Background
bakred='\e[41m'   # Red
badgrn='\e[42m'   # Green
bakylw='\e[43m'   # Yellow
bakblu='\e[44m'   # Blue
bakpur='\e[45m'   # Purple
bakcyn='\e[46m'   # Cyan
bakwht='\e[47m'   # White
txtrst='\e[0m'    # Text Reset

if [ -n "$SSH_CLIENT" ]; then
  # show host only if this is an ssh session
  ps1_host="\h"
fi

case $USER in
  ericanderson|eanderson) ;;
  root)
    ps1_user="\[$txtred\]\u@\h"
    echo "root will be logged out after 10 minutes without input or job"
    export TMOUT=600
    ;;
  *) ps1_user="\[$txtgrn\]\u" ;;
esac

ps1_rvm() {
	if [ -f ~/.rvm/bin/rvm-prompt ]; then
		q=$(~/.rvm/bin/rvm-prompt i)

		if [ "$q" == "jruby" ]; then
			q=$(~/.rvm/bin/rvm-prompt g)
			out=" (jruby$q)"
		else
			q=$(~/.rvm/bin/rvm-prompt v g)

			if [ "$q" != "" ]; then
				out=" ($q)"
			fi
		fi

		if [ "$out" != "" ]; then echo "$out"; fi
	fi
}

function __rbenv_ps1() {
	if type -p rbenv >/dev/null 2>&1; then
		local rbenv_ps1="$(rbenv version-name)"
		if [ -n "${rbenv_ps1}" ]; then
			if [ "system" != "${rbenv_ps1}" ]; then
				printf " (${1:-%s})" "$rbenv_ps1"
			fi
		fi
	fi
}


GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWSTASHSTATE=true

ps1_rvm='$(ps1_rvm)'
ps1_rbenv='$(__rbenv_ps1)'
ps1_vcs='$(type -p __git_ps1 && __git_ps1 "(%s)")'

if [ -n "$ps1_user" ] && [ -n "$ps1_host" ]; then
	ps1_user="$ps1_user@"
fi

if [ "$ps1_user" == "" ] && [ -n "$ps1_host" ]; then
	ps1_host="\[$txtgrn\]$ps1_host\[$txtrst\]"
fi

PS1="$ps1_user$ps1_host"

if [ "$PS1" != "" ]; then PS1="$PS1:"; fi

PS1="$PS1\[$txtcyn\]\w\[$txtylw\]$ps1_vcs\[$txtrst$txtpur\]$ps1_rvm$ps1_rbenv\[$txtrst\] \$ "

# End Setup Prompt

