#!/bin/bash

# Check if pip3 is available
if command -v pip3 &> /dev/null; then
    pip3 install --user pynvim
else
    echo "pip3 not found, skipping pynvim installation"
fi
