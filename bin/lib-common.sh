#!/bin/bash

# Common shell utilities for dotfiles scripts
# Provides XDG-compliant paths and shared functionality
# Reference: https://specifications.freedesktop.org/basedir-spec/latest/

# XDG Base Directory support with fallbacks
# User-specific directories
get_xdg_data_dir() {
    echo "${XDG_DATA_HOME:-$HOME/.local/share}"
}

get_xdg_config_dir() {
    echo "${XDG_CONFIG_HOME:-$HOME/.config}"
}

get_xdg_state_dir() {
    echo "${XDG_STATE_HOME:-$HOME/.local/state}"
}

get_xdg_cache_dir() {
    echo "${XDG_CACHE_HOME:-$HOME/.cache}"
}

get_xdg_runtime_dir() {
    # XDG_RUNTIME_DIR has no fallback - if not set, return empty
    # Caller must handle the empty case
    echo "${XDG_RUNTIME_DIR:-}"
}

# System-wide directories (for completeness, rarely used in personal scripts)
get_xdg_data_dirs() {
    echo "${XDG_DATA_DIRS:-/usr/local/share/:/usr/share/}"
}

get_xdg_config_dirs() {
    echo "${XDG_CONFIG_DIRS:-/etc/xdg}"
}

# Global variable to store initialized app name
_COMMON_APP_NAME=""

# Generic app directory functions with init_common integration
get_app_state_dir() {
    local app_name="${1:-$_COMMON_APP_NAME}"
    if [[ -z "$app_name" ]]; then
        echo "Error: App name not provided and init_common() not called" >&2
        return 1
    fi
    echo "$(get_xdg_state_dir)/$app_name"
}

get_app_config_dir() {
    local app_name="${1:-$_COMMON_APP_NAME}"
    if [[ -z "$app_name" ]]; then
        echo "Error: App name not provided and init_common() not called" >&2
        return 1
    fi
    echo "$(get_xdg_config_dir)/$app_name"
}

get_app_cache_dir() {
    local app_name="${1:-$_COMMON_APP_NAME}"
    if [[ -z "$app_name" ]]; then
        echo "Error: App name not provided and init_common() not called" >&2
        return 1
    fi
    echo "$(get_xdg_cache_dir)/$app_name"
}

get_app_data_dir() {
    local app_name="${1:-$_COMMON_APP_NAME}"
    if [[ -z "$app_name" ]]; then
        echo "Error: App name not provided and init_common() not called" >&2
        return 1
    fi
    echo "$(get_xdg_data_dir)/$app_name"
}

get_app_log_dir() {
    local app_name="${1:-$_COMMON_APP_NAME}"
    if [[ -z "$app_name" ]]; then
        echo "Error: App name not provided and init_common() not called" >&2
        return 1
    fi
    echo "$(get_app_state_dir "$app_name")/logs"
}

# Cross-platform log file path
get_app_log_file() {
    local app_name="${1:-$_COMMON_APP_NAME}"
    local log_filename="${2:-$app_name.log}"
    
    if [[ -z "$app_name" ]]; then
        echo "Error: App name not provided and init_common() not called" >&2
        return 1
    fi
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: Use traditional location for compatibility with LaunchAgent
        echo "$HOME/Library/Logs/$log_filename"
    else
        # Linux: Use XDG compliant location
        echo "$(get_app_log_dir "$app_name")/$log_filename"
    fi
}

get_app_status_file() {
    local app_name="${1:-$_COMMON_APP_NAME}"
    if [[ -z "$app_name" ]]; then
        echo "Error: App name not provided and init_common() not called" >&2
        return 1
    fi
    echo "$(get_app_state_dir "$app_name")/status"
}


# Detect if running under a daemon/service
is_running_under_daemon() {
    # Check for systemd
    if [[ -n "$INVOCATION_ID" ]] || [[ "$JOURNAL_STREAM" ]]; then
        return 0
    fi
    
    # Check for launchd (macOS)
    if [[ -n "$LAUNCHD_SOCKET" ]] || pgrep -x "launchd" > /dev/null 2>&1; then
        # Additional check: see if we're in a LaunchAgent context
        if [[ "$PPID" != "1" ]] && ps -p "$PPID" -o comm= 2>/dev/null | grep -q "launchd"; then
            return 0
        fi
    fi
    
    # Check for cron
    if [[ -n "$CRON_TZ" ]] || [[ "$0" == *"cron"* ]]; then
        return 0
    fi
    
    return 1
}

# Get execution context information
get_execution_context() {
    if is_running_under_daemon; then
        if [[ -n "$INVOCATION_ID" ]]; then
            echo "daemon:systemd"
        elif [[ -n "$LAUNCHD_SOCKET" ]] || pgrep -x "launchd" > /dev/null 2>&1; then
            echo "daemon:launchd"
        else
            echo "daemon:unknown"
        fi
    else
        echo "standalone"
    fi
}

# Logging function that adapts based on context
log_message() {
    local level="$1"
    local message="$2"
    local log_file
    if [[ -n "$3" ]]; then
        log_file="$3"
    else
        if ! log_file="$(get_app_log_file)"; then
            echo "Error: Cannot determine log file - init_common() not called?" >&2
            return 1
        fi
    fi
    
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    if is_running_under_daemon; then
        # When running under daemon, log to file and also echo for daemon capture
        echo "[$level] $timestamp: $message" | tee -a "$log_file"
    else
        # When running standalone, only log to file
        echo "[$level] $timestamp: $message" >> "$log_file"
    fi
}

# Specific logging functions
log_info() {
    log_message "INFO" "$1" "$2"
}

log_error() {
    log_message "ERROR" "$1" "$2"
}

log_warn() {
    log_message "WARN" "$1" "$2"
}

# Cross-platform connectivity check
check_internet_connectivity() {
    if command -v curl &> /dev/null; then
        curl -s --connect-timeout 5 https://github.com &> /dev/null
    elif command -v wget &> /dev/null; then
        wget -q --timeout=5 --tries=1 https://github.com -O /dev/null &> /dev/null
    else
        # Fallback to ping with platform-specific flags
        if [[ "$OSTYPE" == "darwin"* ]]; then
            ping -c 1 -W 1000 github.com &> /dev/null
        else
            ping -c 1 -w 1 github.com &> /dev/null
        fi
    fi
}

# Setup Homebrew PATH (cross-platform)
setup_homebrew_path() {
    if command -v brew &> /dev/null; then
        # Use brew --prefix to get the correct path
        local brew_prefix
        brew_prefix=$(brew --prefix)
        export PATH="$brew_prefix/bin:$PATH"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Try common macOS Homebrew locations
        if [[ -d "/opt/homebrew/bin" ]]; then
            export PATH="/opt/homebrew/bin:$PATH"
        elif [[ -d "/usr/local/bin" ]]; then
            export PATH="/usr/local/bin:$PATH"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]] && [[ -d "/home/linuxbrew/.linuxbrew/bin" ]]; then
        # Linux Homebrew
        export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
    fi
}

# Create required directories
ensure_directories() {
    local app_name="${1:-$_COMMON_APP_NAME}"
    if [[ -z "$app_name" ]]; then
        echo "Error: App name not provided and init_common() not called" >&2
        return 1
    fi
    
    local state_dir
    local log_dir
    local cache_dir
    state_dir="$(get_app_state_dir "$app_name")"
    log_dir="$(get_app_log_dir "$app_name")"
    cache_dir="$(get_app_cache_dir "$app_name")"
    
    mkdir -p "$state_dir" "$log_dir" "$cache_dir"
    
    # Also ensure platform-specific log directory exists
    mkdir -p "$(dirname "$(get_app_log_file "$app_name")")"
}

# Update status for any app
update_app_status() {
    # If first argument looks like a status value, assume current app
    if [[ "$1" =~ ^(RUNNING|SUCCESS|ERROR|SKIPPED|UPDATING)$ ]] && [[ -n "$_COMMON_APP_NAME" ]]; then
        local app_name="$_COMMON_APP_NAME"
        local status_value="$1"
        local message="$2"
    else
        local app_name="${1:-$_COMMON_APP_NAME}"
        local status_value="$2"
        local message="$3"
    fi
    
    if [[ -z "$app_name" ]]; then
        echo "Error: App name not provided and init_common() not called" >&2
        return 1
    fi
    
    local status_file
    status_file="$(get_app_status_file "$app_name")"
    echo "$(date '+%Y-%m-%d %H:%M:%S')|$status_value|$message" > "$status_file"
}

# Update status for any app with extended information
update_app_status_extended() {
    # If first argument looks like a status value, assume current app
    if [[ "$1" =~ ^(RUNNING|SUCCESS|ERROR|SKIPPED|UPDATING)$ ]] && [[ -n "$_COMMON_APP_NAME" ]]; then
        local app_name="$_COMMON_APP_NAME"
        local status_value="$1"
        local message="$2"
        local has_changes="${3:-false}"
        local change_count="${4:-0}"
        local summary="${5:-}"
    else
        local app_name="${1:-$_COMMON_APP_NAME}"
        local status_value="$2"
        local message="$3"
        local has_changes="${4:-false}"
        local change_count="${5:-0}"
        local summary="${6:-}"
    fi
    
    if [[ -z "$app_name" ]]; then
        echo "Error: App name not provided and init_common() not called" >&2
        return 1
    fi
    
    local status_file
    status_file="$(get_app_status_file "$app_name")"
    echo "$(date '+%Y-%m-%d %H:%M:%S')|$status_value|$message|$has_changes|$change_count|$summary" > "$status_file"
}

# Calculate human-readable time since timestamp
get_time_since() {
    local timestamp="$1"
    local now
    local then
    now=$(date +%s)
    
    # Try different date parsing approaches for cross-platform compatibility
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        then=$(date -j -f "%Y-%m-%d %H:%M:%S" "$timestamp" +%s 2>/dev/null)
    else
        # Linux
        then=$(date -d "$timestamp" +%s 2>/dev/null)
    fi
    
    if [[ -z "$then" ]]; then
        echo "unknown"
        return
    fi
    
    local diff=$((now - then))
    
    if [[ $diff -lt 60 ]]; then
        echo "just now"
    elif [[ $diff -lt 3600 ]]; then
        local mins=$((diff / 60))
        if [[ $mins -eq 1 ]]; then
            echo "1 minute ago"
        else
            echo "$mins minutes ago"
        fi
    elif [[ $diff -lt 86400 ]]; then
        local hours=$((diff / 3600))
        if [[ $hours -eq 1 ]]; then
            echo "1 hour ago"
        else
            echo "$hours hours ago"
        fi
    elif [[ $diff -lt 604800 ]]; then
        local days=$((diff / 86400))
        if [[ $days -eq 1 ]]; then
            echo "1 day ago"
        else
            echo "$days days ago"
        fi
    else
        local weeks=$((diff / 604800))
        if [[ $weeks -eq 1 ]]; then
            echo "1 week ago"
        else
            echo "$weeks weeks ago"
        fi
    fi
}

# Acquire lock file to prevent concurrent runs
acquire_lock() {
    local app_name="${1:-$_COMMON_APP_NAME}"
    local lock_file="/tmp/${app_name}.lock"
    local timeout=30
    local elapsed=0
    
    if [[ -z "$app_name" ]]; then
        echo "Error: App name not provided and init_common() not called" >&2
        return 1
    fi
    
    while [[ -f "$lock_file" ]] && [[ $elapsed -lt $timeout ]]; do
        sleep 1
        ((elapsed++))
    done
    
    if [[ -f "$lock_file" ]]; then
        log_error "Could not acquire lock after ${timeout}s"
        return 1
    fi
    
    echo $$ > "$lock_file"
    return 0
}

# Release lock file
release_lock() {
    local app_name="${1:-$_COMMON_APP_NAME}"
    if [[ -z "$app_name" ]]; then
        echo "Error: App name not provided and init_common() not called" >&2
        return 1
    fi
    rm -f "/tmp/${app_name}.lock"
}

# Store diff for later viewing
store_diff() {
    # Check if first parameter is diff content (no app name provided)
    if [[ $# -eq 1 ]] && [[ -n "$_COMMON_APP_NAME" ]]; then
        local app_name="$_COMMON_APP_NAME"
        local diff_content="$1"
    else
        local app_name="${1:-$_COMMON_APP_NAME}"
        local diff_content="$2"
    fi
    
    if [[ -z "$app_name" ]]; then
        echo "Error: App name not provided and init_common() not called" >&2
        return 1
    fi
    
    local diff_file="$(get_app_cache_dir "$app_name")/last-diff.txt"
    echo "$diff_content" > "$diff_file"
    echo "$diff_file"
}

# Get stored diff path
get_last_diff_path() {
    local app_name="${1:-$_COMMON_APP_NAME}"
    if [[ -z "$app_name" ]]; then
        echo "Error: App name not provided and init_common() not called" >&2
        return 1
    fi
    echo "$(get_app_cache_dir "$app_name")/last-diff.txt"
}

# Check if changes exist based on status file
has_pending_changes() {
    local app_name="${1:-$_COMMON_APP_NAME}"
    if [[ -z "$app_name" ]]; then
        echo "Error: App name not provided and init_common() not called" >&2
        return 1
    fi
    
    local status_file="$(get_app_status_file "$app_name")"
    if [[ -f "$status_file" ]]; then
        local has_changes
        has_changes=$(cut -d'|' -f4 "$status_file" 2>/dev/null)
        [[ "$has_changes" == "true" ]]
    else
        return 1
    fi
}

# Initialize common setup (call this at start of scripts)
init_common() {
    local app_name="${1:?App name required}"
    
    # Store app name globally for default usage
    _COMMON_APP_NAME="$app_name"
    
    # Ensure required directories exist
    ensure_directories "$app_name"
    
    # Setup Homebrew PATH if needed
    setup_homebrew_path
}