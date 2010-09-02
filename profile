#!/bin/bash
export PATH=${PATH}:~/bin
alias t='todo.sh'
alias thingsdb='cd /Users/ericanderson/Library/Application\ Support/Cultured\ Code/Things'
source ~/.bash_completion.d/todo_completer.sh
complete -F _todo_sh -o default t

export GIT_SSL_NO_VERIFY=TRUE
export SVN_EDITOR="vim"

# Path for macports
export PATH=/opt/local/bin:/opt/local/sbin:$PATH



if [ -f /opt/local/etc/bash_completion ]; then
        . /opt/local/etc/bash_completion
fi




# Setup for RVM
[[ -s $HOME/.rvm/scripts/rvm ]] && source $HOME/.rvm/scripts/rvm
# End Setup for RVM

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
    ps1_user="$txtred\u"
    echo "root will be logged out after 10 minutes without input or job"
    export TMOUT=600
    ;;
  *) ps1_user="$txtgrn\u" ;;
esac

ps1_rvm() {
	out=$(~/.rvm/bin/rvm-prompt v g )
	if [ "$out" != "" ]; then echo " ($out)"; fi
	
}

ps1_ruby='$(ps1_rvm)'
ps1_vcs='$(__git_ps1 " (%s)")'

if [ -n "$ps1_user" ] && [ -n "$ps1_host" ]; then ps1_user="$ps1_user@"; fi
PS1="$ps1_user$ps1_host"
if [ "$PS1" != "" ]; then PS1="$PS1:"; fi

PS1="$PS1$txtcyn\w$txtpur$ps1_ruby$txtrst$txtylw$ps1_vcs$txtrst \$ "

# End Setup Prompt