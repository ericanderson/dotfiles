#!/bin/bash

# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Background
On_Black='\033[40m'       # Black
On_Red='\033[41m'         # Red
On_Green='\033[42m'       # Green
On_Yellow='\033[43m'      # Yellow
On_Blue='\033[44m'        # Blue
On_Purple='\033[45m'      # Purple
On_Cyan='\033[46m'        # Cyan
On_White='\033[47m'       # White

info () {
	echo -e "${Cyan}INFO:${Color_Off} $1"
}

fail() {
	echo -e "${Red}ERROR:${Color_Off} $1"
	exit $2
}

if [ $# -ne 3 ]; then
	echo -e "${BRed}Usage `basename $0` <origin repo> <path to filter to> <new_repo_location>${Color_Off}"
	echo
	echo "NOTE: origin repo must be a full path if used locally"
	exit 1;
fi

origin_repo=${1}
path_to_filter_to=${2}
new_repo_location=${3}
new_repo_parent=`dirname ${new_repo_location}`

mkdir -p ${new_repo_parent}

info "Cloning ${origin_repo} to ${new_repo_location}"
git clone --no-hardlinks -q --progress $origin_repo $new_repo_location || fail "Unable to clone" 2
cd ${new_repo_location}

info "Filter branch down to ${path_to_filter_to}"
git filter-branch --prune-empty --subdirectory-filter ${path_to_filter_to} --tag-name-filter cat -- --all 2>&1 | tee filtered_branches.txt || fail "Unable to filter branches" 3

info "Remove branches that are irrelevant"
cat filtered_branches.txt | grep WARNING | awk '{print $3}' | xargs -n 1 git update-ref -d
#rm filtered_branches.txt


info "Deleting old refs"
git for-each-ref --format="%(refname)" refs/original/ | xargs -n 1 git update-ref -d || fail "Unable to delete old refs" 4

info "Removing cruft"
git reflog expire --expire=now --all
git gc --prune=now

info "Repo size: ${du -h -d 0 . | awk '{print $1}'}"
