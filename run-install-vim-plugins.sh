#!/bin/bash

echo "Installing VIM Plugins"
vim -es -u vimrc -i NONE -c "PlugInstall" -c "qa"