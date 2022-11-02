#!/usr/bin/env sh

brew bundle dump --file=/dev/stdout | grep -Fvxf ~/.local/share/chezmoi/Brewfile.common /dev/stdin
