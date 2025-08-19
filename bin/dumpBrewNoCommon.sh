#!/usr/bin/env sh

brew bundle dump --file=/dev/stdout | grep -Fvxf "${HOME}"/.local/share/chezmoi/Brewfile.common /dev/stdin
