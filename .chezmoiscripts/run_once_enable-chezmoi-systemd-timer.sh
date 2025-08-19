#!/bin/bash

# Enable chezmoi auto-update systemd timer

# Only run on Linux with systemd
if [[ "$(uname)" != "Linux" ]] || ! command -v systemctl &> /dev/null; then
    echo "Skipping systemd timer setup (not Linux with systemd)"
    exit 0
fi

# Skip if running on macOS (Darwin)
if [[ "$(uname)" == "Darwin" ]]; then
    echo "Skipping systemd timer setup (macOS uses LaunchAgent)"
    exit 0
fi

echo "Setting up chezmoi auto-update systemd timer..."

# Reload user systemd daemon to pick up new units
systemctl --user daemon-reload

# Enable and start the timer
if systemctl --user enable chezmoi-update.timer; then
    echo "Timer enabled successfully"
    
    if systemctl --user start chezmoi-update.timer; then
        echo "Timer started successfully"
        
        # Show timer status
        echo "Timer status:"
        systemctl --user list-timers chezmoi-update.timer --no-pager
    else
        echo "Warning: Could not start timer"
    fi
else
    echo "Warning: Could not enable timer"
fi