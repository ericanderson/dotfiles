#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -d "$HOME/.ssh" ]; then
	ssh-keygen -t rsa -b 4096
	echo woot
fi


if [[ $OSTYPE == darwin* ]]; then
  # Install Homebrew
  if [ ! -d "/usr/local/Cellar" ]; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

  # Run the ansible playbook for the machine
  if which ansible-playbook > /dev/null; then
    echo Ansible is installed
  else
    brew install ansible
  fi

  (cd "$DIR" && cd mac-playbook && ansible-playbook main.yml)

fi

git submodule update --init
ruby install.rb

if [[ $OSTYPE == darwin* ]]; then
  sh ~/.install/custom_keyboard_shortcuts.sh
fi
