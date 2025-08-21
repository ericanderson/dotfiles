#!/bin/bash

# Enhanced Chezmoi safe update check script with Claude AI summaries
# Checks for updates without automatically applying them

# Get the directory where this script is located (resolves symlinks)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

# Source common utilities
# shellcheck source-path=SCRIPTDIR
source "$SCRIPT_DIR/lib-common.sh"

# Set app name for generic functions
APP_NAME="chezmoi-update-check"

# Initialize common setup
init_common "$APP_NAME"

# Get file paths using common library
CHEZMOI_UPDATE_LOG_FILE="$(get_app_log_file)"
CHEZMOI_UPDATE_CACHE_DIR="$(get_app_cache_dir)"

# Function to safely call Claude CLI with proper error handling
generate_change_summary() {
    local diff_file="$1"
    local claude_cli="/home/eanderson/.local/bin/claude"
    
    # Check if Claude CLI exists and is executable
    if [[ ! -x "$claude_cli" ]]; then
        log_warn "Claude CLI not found or not executable at $claude_cli"
        return 1
    fi
    
    # Check if diff file exists and has content
    if [[ ! -s "$diff_file" ]]; then
        log_warn "Diff file is empty or doesn't exist"
        return 1
    fi
    
    # Get line count and truncate if too large
    local line_count
    line_count=$(wc -l < "$diff_file")
    local diff_content
    
    if [[ $line_count -gt 200 ]]; then
        # Show first 100 and last 50 lines for large diffs
        diff_content=$(head -100 "$diff_file"; echo ""; echo "... [${line_count} total lines, showing partial diff] ..."; echo ""; tail -50 "$diff_file")
        log_info "Large diff detected ($line_count lines), truncating for Claude analysis"
    else
        diff_content=$(cat "$diff_file")
    fi
    
    # Create prompt for Claude
    local prompt="Summarize these chezmoi changes in ONE concise sentence (max 15 words). Focus on what's changing, not technical details:

$diff_content"
    
    # Call Claude with timeout and error handling
    local summary
    if summary=$(timeout 10 "$claude_cli" --print --model haiku <<< "$prompt" 2>/dev/null); then
        # Clean up the summary (remove quotes, trim whitespace, ensure it's reasonable length)
        summary=$(echo "$summary" | tr -d '"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | head -1)
        
        # Validate summary isn't too long or empty
        if [[ -n "$summary" ]] && [[ ${#summary} -le 100 ]]; then
            echo "$summary"
            return 0
        else
            log_warn "Claude returned invalid summary: too long or empty"
            return 1
        fi
    else
        log_warn "Claude CLI failed or timed out"
        return 1
    fi
}

# Cleanup function to ensure lock is released
cleanup() {
    release_lock
    exit $1
}

# Set trap to ensure cleanup on exit
trap 'cleanup $?' EXIT INT TERM

# Start
log_info "Starting chezmoi update check... [context: $(get_execution_context)]"
update_app_status_extended "RUNNING" "Checking for updates..."

# Acquire lock to prevent concurrent runs
if ! acquire_lock; then
    log_error "Could not acquire lock, another instance may be running"
    update_app_status_extended "ERROR" "Could not acquire lock"
    exit 1
fi

# Check if chezmoi is installed
if ! command -v chezmoi &> /dev/null; then
    log_error "chezmoi not found in PATH"
    update_app_status_extended "ERROR" "chezmoi not found in PATH"
    exit 1
fi

# Check if we have internet connectivity
if ! check_internet_connectivity; then
    log_info "No internet connectivity, skipping update check"
    update_app_status_extended "SKIPPED" "No internet connectivity"
    exit 0
fi

# Navigate to chezmoi source directory
CHEZMOI_SOURCE_PATH="$(chezmoi source-path)"
if [[ ! -d "$CHEZMOI_SOURCE_PATH" ]]; then
    log_error "Chezmoi source path not found: $CHEZMOI_SOURCE_PATH"
    update_app_status_extended "ERROR" "Source path not found"
    exit 1
fi

cd "$CHEZMOI_SOURCE_PATH" || exit 1

# Check if git repo is in a clean state
if ! git diff --quiet || ! git diff --cached --quiet; then
    log_info "Git repo has uncommitted changes, skipping update check"
    update_app_status_extended "SKIPPED" "Uncommitted changes in git repo"
    exit 0
fi

# Pull latest changes from remote (does NOT apply to home directory)
log_info "Pulling latest changes from remote repository..."
update_app_status_extended "RUNNING" "Pulling from remote..."

if ! chezmoi git pull >> "$CHEZMOI_UPDATE_LOG_FILE" 2>&1; then
    log_error "Failed to pull from remote repository"
    update_app_status_extended "ERROR" "Failed to pull from remote"
    exit 1
fi

# Check what changes would be applied
log_info "Checking for pending changes..."
DIFF_FILE="$CHEZMOI_UPDATE_CACHE_DIR/update-diff"

# Generate diff of what would change
if ! chezmoi diff > "$DIFF_FILE" 2>&1; then
    log_error "Failed to generate diff"
    update_app_status_extended "ERROR" "Failed to generate diff"
    exit 1
fi

# Check if there are any changes
if [[ ! -s "$DIFF_FILE" ]]; then
    log_info "No changes to apply"
    update_app_status_extended "SUCCESS" "No changes needed" "false" "0" "No updates available"
    rm -f "$DIFF_FILE"
    exit 0
fi

# Count the number of files that would change
local change_count
change_count=$(grep -c "^diff --git" "$DIFF_FILE" 2>/dev/null || echo "0")
log_info "Found changes in $change_count file(s)"

# Store the diff for manual review
local stored_diff_path
stored_diff_path=$(store_diff "$(cat "$DIFF_FILE")")
log_info "Diff stored at: $stored_diff_path"

# Try to generate Claude summary
local claude_summary=""
local summary_status="Generated AI summary"

log_info "Attempting to generate AI summary of changes..."
if claude_summary=$(generate_change_summary "$DIFF_FILE"); then
    log_info "Claude summary generated: $claude_summary"
    summary_status="Generated AI summary"
else
    log_info "Could not generate Claude summary, will show file count instead"
    claude_summary="$change_count file(s) have pending changes"
    summary_status="AI summary unavailable"
fi

# Update status with detailed information
update_app_status_extended "SUCCESS" "$summary_status" "true" "$change_count" "$claude_summary"

log_info "Update check completed successfully. Changes detected: $change_count file(s)"
log_info "Summary: $claude_summary"
log_info "Run 'chezmoi diff' to review changes, then 'chezmoi apply' to update"

# Cleanup temporary diff file (we've stored it elsewhere)
rm -f "$DIFF_FILE"