#!/bin/bash

# Enhanced Chezmoi safe update script with status tracking

# Get the directory where this script is located (resolves symlinks)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

# Source common utilities
source "$SCRIPT_DIR/lib-common.sh"

# Set app name for generic functions
APP_NAME="chezmoi-auto-update"

# Initialize common setup
init_common "$APP_NAME"

# Get file paths using common library (app name defaults from init_common)
CHEZMOI_UPDATE_LOG_FILE="$(get_app_log_file)"
CHEZMOI_UPDATE_CACHE_DIR="$(get_app_cache_dir)"


# Start
log_info "Starting chezmoi update check... [context: $(get_execution_context)]"
update_app_status "RUNNING" "Checking for updates..."

# Check if chezmoi is installed
if ! command -v chezmoi &> /dev/null; then
    log_error "chezmoi not found in PATH"
    update_app_status "ERROR" "chezmoi not found in PATH"
    exit 1
fi


# Check if we have internet connectivity
if ! check_internet_connectivity; then
    log_info "No internet connectivity, skipping update"
    update_app_status "SKIPPED" "No internet connectivity"
    exit 0
fi

# Check if git repo is in a clean state
cd "$(chezmoi source-path)" || exit 1
if ! git diff --quiet && git diff --cached --quiet; then
    log_info "Git repo has uncommitted changes, skipping update"
    update_app_status "SKIPPED" "Uncommitted changes in git repo"
    exit 0
fi

# Use cache directory for temporary files
PREVIEW_FILE="$CHEZMOI_UPDATE_CACHE_DIR/update-preview"

# Perform safe update with dry-run first
if chezmoi update --dry-run > "$PREVIEW_FILE" 2>&1; then
    # If dry-run succeeds and shows changes, proceed with actual update
    if [ -s "$PREVIEW_FILE" ]; then
        log_info "Changes detected, applying update:"
        cat "$PREVIEW_FILE" >> "$CHEZMOI_UPDATE_LOG_FILE"
        update_app_status "UPDATING" "Applying changes..."
        
        if chezmoi update >> "$CHEZMOI_UPDATE_LOG_FILE" 2>&1; then
            changes=$(wc -l < "$PREVIEW_FILE")
            log_info "Chezmoi update completed successfully"
            update_app_status "SUCCESS" "Updated $changes file(s)"
        else
            log_error "Chezmoi update failed"
            update_app_status "ERROR" "Update failed - check logs"
            exit 1
        fi
    else
        log_info "No changes to apply"
        update_app_status "SUCCESS" "No changes needed"
    fi
else
    log_error "Dry-run failed, skipping update"
    cat "$PREVIEW_FILE" >> "$CHEZMOI_UPDATE_LOG_FILE"
    update_app_status "ERROR" "Dry-run failed - check logs"
    exit 1
fi

# Cleanup
rm -f "$PREVIEW_FILE"