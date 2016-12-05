#!/bin/bash

set -e

if [ ! -d "$HOME/.ssh" ]; then
	ssh-keygen -t rsa -b 4096
	echo woot
fi

# Install Homebrew
if [[ $OSTYPE == darwin* ]]; then
  if [ ! -d "/usr/local/Cellar" ]; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
fi
git submodule update --init
ruby install.rb

if [[ $OSTYPE == darwin* ]]; then
  sh ~/.install/nodenv.sh
  sh ~/.install/custom_keyboard_shortcuts.sh
fi
