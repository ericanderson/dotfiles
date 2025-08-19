# bin/ Directory Documentation

This directory contains executable scripts and utilities for the dotfiles system.

## Architecture Guidelines

### Shell Script Patterns

1. **Always use common library**: Source `lib-common.sh` for shared functionality
2. **Avoid templates when possible**: Write scripts to detect environment dynamically
3. **Use proper XDG paths**: Follow XDG Base Directory specification
4. **Namespace properly**: Use specific names (e.g., `chezmoi-auto-update`, not generic `chezmoi`)

### Common Library Usage

All scripts should follow this pattern:

```bash
#!/bin/bash

# Get the directory where this script is located (resolves symlinks)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

# Source common utilities
source "$SCRIPT_DIR/lib-common.sh"

# Initialize common setup (stores app name for defaults)
init_common "your-script-name"

# Get app-specific paths (no app name needed after init)
LOG_FILE="$(get_app_log_file)"
STATUS_FILE="$(get_app_status_file)"
CACHE_DIR="$(get_app_cache_dir)"

# Update status (simplified API)
update_app_status "RUNNING" "Starting processing..."
```

### XDG Directory Conventions

Follow the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/) for proper data organization:

**Available Functions:**
- `get_xdg_data_dir()` - User data files (`$HOME/.local/share`)
- `get_xdg_config_dir()` - Configuration files (`$HOME/.config`)
- `get_xdg_state_dir()` - Persistent state/logs (`$HOME/.local/state`)
- `get_xdg_cache_dir()` - Non-essential cache (`$HOME/.cache`)
- `get_xdg_runtime_dir()` - Runtime files (no fallback)

**Generic App Functions:**
- `get_app_state_dir [app-name]` - App state directory
- `get_app_config_dir [app-name]` - App config directory  
- `get_app_cache_dir [app-name]` - App cache directory
- `get_app_data_dir [app-name]` - App data directory
- `get_app_log_dir [app-name]` - App logs subdirectory
- `get_app_log_file [app-name] [filename]` - Cross-platform log file path
- `get_app_status_file [app-name]` - App status file path
- `update_app_status [app-name] status message` - Update app status

**Smart API Design:**
- After `init_common "app-name"`, all functions use that app as default
- Functions can still take explicit app names for cross-app access
- `update_app_status` detects if first arg is status and uses current app

**Usage Examples:**
```bash
# Simplified API (current app after init_common)
init_common "my-script"
LOG_FILE="$(get_app_log_file)"  # Uses my-script
update_app_status "RUNNING" "Processing..."  # Uses my-script

# Explicit app access (for multi-app tools like motd)
OTHER_LOG="$(get_app_log_file "other-app")"
update_app_status "other-app" "SUCCESS" "Done"
```

**Current Usage (✅ Correct):**
- Logs → `XDG_STATE_HOME` (persistent state)
- Status files → `XDG_STATE_HOME` (persistent state) 
- Preview files → `XDG_CACHE_HOME` (temporary cache)

### Script Directory Resolution

**Robust SCRIPT_DIR Pattern:**
```bash
# Symlink-safe version (recommended)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

# Simple version (not symlink-safe)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

**Why the robust version matters:**
- ✅ Resolves symlinks to actual script location
- ✅ Works when script is called via symlink
- ✅ Ensures lib-common.sh is found correctly
- ✅ Critical for chezmoi-managed scripts in `~/bin/`

### Logging Strategy

#### Daemon vs Script Logs

**Problem**: Daemons (systemd/launchd) capture stdout/stderr AND scripts log internally - conflicts arise when both write to the same file.

**Solution**: Use separate files:
- Script internal logs: `script-name.log`
- Daemon capture logs: `script-name.out.log`

#### Cross-Platform Logging

macOS maintains traditional `~/Library/Logs/` for compatibility with LaunchAgent, while Linux uses XDG paths.

```bash
# Use common library functions
log_info "This message"      # Adapts to daemon context
log_error "Error message"
log_warn "Warning message"
```

### Execution Context Detection

The common library provides functions to detect execution context:

```bash
# Get execution context info
context=$(get_execution_context)
# Returns: "standalone", "daemon:systemd", "daemon:launchd", etc.
```

### Daemon Environment Considerations

**Key Issue**: Daemons run with minimal environment:
- No `.bashrc` sourcing
- Limited PATH
- No user environment variables

**Detection Results**:
- **Direct execution**: `standalone`
- **systemd**: `daemon:systemd`
- **LaunchAgent**: `daemon:launchd`

**Solutions**:
1. Use `/bin/bash -l -c` for login shell behavior
2. Set up PATH within scripts using common library
3. Don't rely on user profile variables
4. Log execution context for debugging

### Testing Procedures

#### Standalone Testing
```bash
# Test script directly
./script-name

# Check logs
tail -f ~/.local/state/script-name/logs/script-name.log
```

#### Daemon Testing

**systemd (Linux)**:
```bash
# Start service manually
systemctl --user start chezmoi-update.service

# Check status
systemctl --user status chezmoi-update.service

# View daemon logs
tail -f ~/.local/state/chezmoi-auto-update/logs/chezmoi-auto-update.out.log
```

**LaunchAgent (macOS)**:
```bash
# Load agent
launchctl load ~/Library/LaunchAgents/com.user.chezmoi.update.plist

# Start manually
launchctl start com.user.chezmoi.update

# Check daemon logs
tail -f ~/Library/Logs/chezmoi-auto-update.out.log
```

## Current Scripts

### chezmoi-auto-update.sh
- **Purpose**: Safe, automated chezmoi updates with status tracking
- **App Name**: `chezmoi-auto-update`
- **Logs**: Internal to `chezmoi-auto-update.log`, daemon capture to `chezmoi-auto-update.out.log`
- **Status**: Uses generic `update_app_status()` function
- **Safety**: Checks connectivity, git status, runs dry-run first

### motd
- **Purpose**: Message of the Day showing system status
- **Usage**: Call `show_motd` function or run directly
- **Displays**: System info, any app status (currently chezmoi-auto-update)
- **Extensible**: Easy to add other app status displays

### lib-common.sh
- **Purpose**: Generic, reusable utilities for any script
- **Functions**: XDG paths, logging, daemon detection, app management
- **API**: All functions use `app-name` parameter for consistency
- **Usage**: Source at start of all scripts with `APP_NAME` variable

## Best Practices

1. **Never hardcode paths** - use common library functions
2. **Test both standalone and daemon execution**
3. **Use proper variable prefixes** (e.g., `CHEZMOI_UPDATE_*`)
4. **Check for command availability** before using tools
5. **Provide meaningful status messages**
6. **Clean up temporary files**
7. **Handle errors gracefully with proper exit codes**

## Future Enhancements

- Consider structured logging (JSON) for better parsing
- Add metrics collection for update frequency/success rates
- Implement retry logic with exponential backoff
- Add notification support (desktop/email)