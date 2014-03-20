#!/bin/bash

set -e

if [ ! -d "$HOME/.ssh" ]; then
	ssh-keygen -t rsa
	echo woot
fi

# Install Homebrew
if [ ! -d "/usr/local/Cellar" ]; then
	ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
fi



git submodule update --init
ruby install.rb
brew bundle Brewfile
bash ./osx