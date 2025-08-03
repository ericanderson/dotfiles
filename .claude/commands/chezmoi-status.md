---
description: Comprehensive chezmoi and dotfiles status overview
allowed-tools: Bash(chezmoi:*), Bash(git:*), Bash(ls:*), Bash(du:*), Read
---

# /chezmoi-status

## Repository Status
- Location: ~/.local/share/chezmoi
- Branch: !`cd ~/.local/share/chezmoi && git branch --show-current`
- Last commit: !`cd ~/.local/share/chezmoi && git log -1 --oneline`
- Uncommitted changes: !`cd ~/.local/share/chezmoi && git status --porcelain | wc -l`

## Chezmoi Status
- Managed files: !`chezmoi managed | wc -l`
- Unmanaged files: !`chezmoi unmanaged | wc -l`
- Files with changes: !`chezmoi diff --exclude=externals | grep '^diff' | wc -l`
- Total removals pending: !`chezmoi diff --exclude=externals | grep '^-' | grep -v '^---' | wc -l`
- Total additions pending: !`chezmoi diff --exclude=externals | grep '^+' | grep -v '^+++' | wc -l`

## Backup Status
- Total backups: !`ls -d ~/.chezmoi-backups/*/ 2>/dev/null | grep -v latest | wc -l`
- Latest backup: !`readlink ~/.chezmoi-backups/latest 2>/dev/null | xargs basename 2>/dev/null || echo "No backups yet"`
- Backup directory size: !`du -sh ~/.chezmoi-backups 2>/dev/null | cut -f1 || echo "0"`

<task>
You are a chezmoi status assistant that provides a comprehensive overview of the current dotfiles state, helping users understand their configuration status at a glance.
</task>

<workflow>
1. Display repository information from embedded commands above
2. Show chezmoi management statistics
3. Summarize any pending changes
4. Display backup information
5. Provide actionable recommendations based on current state
6. Suggest appropriate next commands
</workflow>

<status_sections>

### 1. Repository Overview
Display information about the git repository:
- Current branch and sync status
- Recent commits
- Any uncommitted changes in the chezmoi source

### 2. File Management Status
Show statistics about:
- How many files are managed by chezmoi
- How many files are unmanaged
- Quick summary of pending changes

### 3. Pending Changes Summary
If there are pending changes, categorize them:
- High risk (removals)
- Medium risk (modifications)  
- Low risk (additions only)

### 4. Backup Information
Display:
- Number of backups available
- When the last backup was created
- Total space used by backups

### 5. Recommendations
Based on the current state, suggest actions:
- If many unmanaged files: suggest `/chezmoi-unmanaged`
- If pending changes: suggest `/integrate-changes`
- If no recent backup and changes pending: suggest `/chezmoi-backup`
- If uncommitted changes in repo: suggest committing
</status_sections>

<output_format>
# Chezmoi Status Overview

## 📁 Repository
- **Branch**: [branch-name]
- **Status**: [Clean|X uncommitted changes]
- **Last commit**: [hash] [message]

## 📊 File Management
- **Managed files**: [count]
- **Unmanaged files**: [count] [⚠️ if > 10]
- **Pending changes**: [count] files affected

## 🔄 Pending Changes
[If changes exist, show summary]
- ⚠️ **Removals**: [count] lines would be removed
- 🔄 **Additions**: [count] lines would be added
- 📝 **Files affected**: [list top 5]

## 💾 Backups
- **Total backups**: [count]
- **Latest backup**: [timestamp or "None"]
- **Storage used**: [size]

## 💡 Recommendations

[Dynamic recommendations based on state]

### Quick Actions
- Review changes: `/integrate-changes`
- Process unmanaged: `/chezmoi-unmanaged`
- Create backup: `/chezmoi-backup`
- View all commands: `/help chezmoi`
</output_format>

<smart_recommendations>
Provide contextual recommendations:

1. **If unmanaged files > 10**:
   ```
   ⚠️ You have [X] unmanaged files. Consider reviewing them:
   Run: /chezmoi-unmanaged
   ```

2. **If pending changes exist without recent backup**:
   ```
   ⚠️ You have pending changes but no recent backup.
   Recommend: /chezmoi-backup before applying changes
   ```

3. **If high-risk removals detected**:
   ```
   🔴 Warning: [X] lines would be removed if you apply changes.
   Review carefully: /integrate-changes
   ```

4. **If repository has uncommitted changes**:
   ```
   📝 You have uncommitted changes in your chezmoi repository.
   Consider committing: cd ~/.local/share/chezmoi && git add -A && git commit
   ```

5. **If everything is clean**:
   ```
   ✅ Everything is in sync! No actions needed.
   ```
</smart_recommendations>

<detailed_info>
If user wants more detail on any section, provide:

1. **For pending changes**: Show first few files with changes
2. **For unmanaged files**: Show first 10 unmanaged files
3. **For backups**: Show recent backup timestamps
4. **For repository**: Show recent commit history
</detailed_info>