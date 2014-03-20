#!/bin/bash

set -e

if [ ! -d "$HOME/.ssh" ]; then
	ssh-keygen -t rsa
	echo woot
fi

git submodule update --init
ruby install.rb
brew bundle Brewfile
bash ./osx