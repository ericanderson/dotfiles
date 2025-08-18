#!/bin/bash

# Enhanced Chezmoi safe update script with status tracking
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

LOG_FILE="$HOME/Library/Logs/chezmoi-update.log"
STATUS_FILE="$HOME/.config/chezmoi-status"

# Create directories if they don't exist
mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$STATUS_FILE")"

# Function to update status
update_status() {
    local status="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S')|$status|$message" > "$STATUS_FILE"
}

# Start
echo "$(date): Starting chezmoi update check..." >> "$LOG_FILE"
update_status "RUNNING" "Checking for updates..."

# Check if chezmoi is installed
if ! command -v chezmoi &> /dev/null; then
    echo "$(date): chezmoi not found in PATH" >> "$LOG_FILE"
    update_status "ERROR" "chezmoi not found in PATH"
    exit 1
fi

# Check if we have internet connectivity
if ! ping -c 1 -W 1000 github.com &> /dev/null; then
    echo "$(date): No internet connectivity, skipping update" >> "$LOG_FILE"
    update_status "SKIPPED" "No internet connectivity"
    exit 0
fi

# Check if git repo is in a clean state
cd "$(chezmoi source-path)" || exit 1
if ! git diff --quiet && git diff --cached --quiet; then
    echo "$(date): Git repo has uncommitted changes, skipping update" >> "$LOG_FILE"
    update_status "SKIPPED" "Uncommitted changes in git repo"
    exit 0
fi

# Perform safe update with dry-run first
if chezmoi update --dry-run > /tmp/chezmoi-update-preview 2>&1; then
    # If dry-run succeeds and shows changes, proceed with actual update
    if [ -s /tmp/chezmoi-update-preview ]; then
        echo "$(date): Changes detected, applying update:" >> "$LOG_FILE"
        cat /tmp/chezmoi-update-preview >> "$LOG_FILE"
        update_status "UPDATING" "Applying changes..."
        
        if chezmoi update >> "$LOG_FILE" 2>&1; then
            local changes=$(wc -l < /tmp/chezmoi-update-preview)
            echo "$(date): Chezmoi update completed successfully" >> "$LOG_FILE"
            update_status "SUCCESS" "Updated $changes file(s)"
        else
            echo "$(date): Chezmoi update failed" >> "$LOG_FILE"
            update_status "ERROR" "Update failed - check logs"
            exit 1
        fi
    else
        echo "$(date): No changes to apply" >> "$LOG_FILE"
        update_status "SUCCESS" "No changes needed"
    fi
else
    echo "$(date): Dry-run failed, skipping update" >> "$LOG_FILE"
    cat /tmp/chezmoi-update-preview >> "$LOG_FILE"
    update_status "ERROR" "Dry-run failed - check logs"
    exit 1
fi

# Cleanup
rm -f /tmp/chezmoi-update-preview