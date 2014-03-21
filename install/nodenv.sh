#!/bin/bash

if [ ! -d "$HOME/.nodenv" ]; then
	git clone https://github.com/wfarr/nodenv.git ~/.nodenv
fi

cd ~/.nodenv
git pull