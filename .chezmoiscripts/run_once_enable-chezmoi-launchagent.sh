#!/bin/bash

# Enable chezmoi auto-update LaunchAgent

# Only run on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "Skipping LaunchAgent setup (not on macOS)"
    exit 0
fi
PLIST_PATH="$HOME/Library/LaunchAgents/com.user.chezmoi.update.plist"
SERVICE_NAME="gui/$(id -u)/com.user.chezmoi.update"

if [[ -f "$PLIST_PATH" ]]; then
    echo "Loading and enabling chezmoi auto-update LaunchAgent..."
    
    # Unload first in case it's already loaded (prevents errors)
    launchctl unload "$PLIST_PATH" 2>/dev/null
    
    # Load the LaunchAgent (use bootstrap for better compatibility with newer macOS)
    if launchctl bootstrap gui/$(id -u) "$PLIST_PATH" 2>/dev/null; then
        echo "LaunchAgent bootstrapped successfully"
    elif launchctl load "$PLIST_PATH" 2>/dev/null; then
        echo "LaunchAgent loaded successfully"
    else
        echo "Note: Couldn't load LaunchAgent automatically."
        echo "You may need to manually load it with:"
        echo "  launchctl bootstrap gui/$(id -u) $PLIST_PATH"
        echo "or"
        echo "  launchctl load $PLIST_PATH"
        echo ""
        echo "This is typically needed on first setup due to macOS security restrictions."
    fi
    
    # Try to enable the service (may fail on some macOS versions, which is okay)
    launchctl enable "$SERVICE_NAME" 2>/dev/null || true
else
    echo "Warning: LaunchAgent plist not found at $PLIST_PATH"
fi