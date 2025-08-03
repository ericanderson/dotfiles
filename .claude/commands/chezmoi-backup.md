---
description: Create timestamped backup of files that would be changed by chezmoi
allowed-tools: Bash(chezmoi:*), Bash(mkdir:*), Bash(cp:*), Bash(ln:*), Write
---

# /chezmoi-backup

## Creating Backup
- Timestamp: !`date +%Y-%m-%d_%H-%M-%S`
- Affected files: !`chezmoi diff --exclude=externals | grep '^diff' | wc -l`
- Backup location: ~/.chezmoi-backups/

<task>
You are a chezmoi backup assistant that creates safe, timestamped backups of files before changes are applied. Your goal is to ensure users can safely experiment with chezmoi configurations knowing they can restore their original files if needed.
</task>

<workflow>
1. Create timestamped backup directory
2. Get list of files that would be modified by chezmoi apply
3. Copy current versions of those files to backup directory
4. Save the current diff output for reference
5. Create manifest file with metadata
6. Update 'latest' symlink to point to new backup
7. Report success with backup location
</workflow>

<backup_process>
Execute these steps:

1. **Create backup directory structure**:
   ```bash
   TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
   BACKUP_DIR="$HOME/.chezmoi-backups/$TIMESTAMP"
   mkdir -p "$BACKUP_DIR/files"
   ```

2. **Identify files to backup**:
   - Parse `chezmoi diff --exclude=externals`
   - Extract file paths that would be modified
   - Only backup files that exist (not new files)

3. **Copy files to backup**:
   ```bash
   # For each file that would be modified
   cp -p "$HOME/.example" "$BACKUP_DIR/files/.example"
   ```

4. **Save diff for reference**:
   ```bash
   chezmoi diff --exclude=externals > "$BACKUP_DIR/chezmoi-diff.txt"
   ```

5. **Create manifest.json**:
   ```json
   {
     "timestamp": "2025-01-03_14-30-45",
     "date": "2025-01-03 14:30:45",
     "files_backed_up": [
       ".zshrc",
       ".gitconfig"
     ],
     "chezmoi_version": "$(chezmoi --version)",
     "total_files": 2
   }
   ```

6. **Update latest symlink**:
   ```bash
   ln -sfn "$BACKUP_DIR" "$HOME/.chezmoi-backups/latest"
   ```
</backup_process>

<output_format>
## Backup Complete ✓

**Backup ID**: [timestamp]
**Location**: ~/.chezmoi-backups/[timestamp]/
**Files backed up**: [count]

### Backed up files:
- ~/.zshrc
- ~/.gitconfig
- [etc...]

### Next steps:
1. Review changes with `/integrate-changes`
2. Apply changes with `chezmoi apply` when ready
3. If needed, restore with `/chezmoi-undo [timestamp]`

**Tip**: Your backup is also available at `~/.chezmoi-backups/latest/`
</output_format>

<error_handling>
Handle these scenarios gracefully:

1. **No changes to backup**:
   - If `chezmoi diff` is empty, inform user no backup needed
   - Exit gracefully

2. **Backup directory exists**:
   - This shouldn't happen with timestamp, but check anyway
   - Add sub-second precision if needed

3. **Permission errors**:
   - Report which files couldn't be backed up
   - Continue with other files
   - Note failures in manifest

4. **Disk space issues**:
   - Check available space before starting
   - Warn if backup might fill disk
</error_handling>

<manifest_structure>
The manifest.json file should contain:
- timestamp: Directory name timestamp
- date: Human-readable date/time
- files_backed_up: Array of relative paths
- chezmoi_version: Version used for backup
- total_files: Count of backed up files
- failed_files: Array of files that couldn't be backed up (if any)
- notes: Any special conditions or warnings
</manifest_structure>