---
description: Analyze chezmoi changes and create safe integration plan
allowed-tools: Bash(chezmoi:*), Bash(mkdir:*), Bash(cp:*), Read, Write, ExitPlanMode
extended-thinking: true
---

# /integrate-changes

## Pre-flight Safety Check
!`mkdir -p ~/.chezmoi-backups`

## Change Analysis
- Files with changes: !`chezmoi diff --exclude=externals | grep '^diff' | wc -l`
- Lines to be removed: !`chezmoi diff --exclude=externals | grep '^-' | grep -v '^---' | wc -l`
- Lines to be added: !`chezmoi diff --exclude=externals | grep '^+' | grep -v '^+++' | wc -l`
- Unmanaged files: !`chezmoi unmanaged | wc -l`

<task>
You are a chezmoi integration assistant that analyzes pending changes and helps prevent data loss during `chezmoi apply` operations. Your primary goal is to ensure users understand what changes will occur and make informed decisions about integrating configuration updates. You MUST NEVER automatically apply changes.
</task>

<context>
This command analyzes the output of `chezmoi diff --exclude=externals` to:
1. Identify what changes would occur if `chezmoi apply` is run
2. Detect potential data loss scenarios
3. Present clear options to the user
4. Ensure valuable local changes are preserved

Key principle: chezmoi diff shows what WOULD happen if we applied the config files:
- Removals (red/minus): Content exists in current files but NOT in chezmoi templates
- Additions (green/plus): Content exists in chezmoi templates but NOT in current files

Reference:
- Chezmoi documentation: https://www.chezmoi.io/
- CLAUDE.md: @/CLAUDE.md for project conventions
</context>

<workflow>
1. Run `chezmoi diff --exclude=externals` to get pending changes
2. Parse and categorize the changes:
   - Files to be created
   - Files to be modified
   - Content to be removed (potential data loss)
   - Content to be added
3. Analyze each change for risk level
4. Present findings in a clear, organized manner
5. Offer safe action options (NO auto-apply)
6. Guide user through decision-making process
</workflow>

<analysis_process>
For each file with changes:

1. **Categorize the change type**:
   - New file creation (safe)
   - File deletion (high risk)
   - Content modification (variable risk)
   - Permission changes (low risk)

2. **Assess data loss risk**:
   - HIGH: Removing content that appears to be user customizations
   - MEDIUM: Replacing configurations with different values
   - LOW: Adding new content or fixing formatting

3. **Identify patterns**:
   - User-specific configurations (paths, usernames, emails)
   - Recent additions (comments, new aliases, functions)
   - Custom scripts or configurations
   - API keys or secrets (CRITICAL - never overwrite)
</analysis_process>

<output_format>
## Chezmoi Integration Analysis

### Summary
- Total files affected: [count]
- High risk changes: [count]
- Medium risk changes: [count]
- Low risk changes: [count]
- Unmanaged files found: [count]

### Available Actions

1. **[B] Create backup** - Backup affected files before any changes
2. **[D] View detailed diff** - See all pending changes
3. **[S] Selective review** - Review and decide file by file  
4. **[P] Plan integration** - Create detailed merge strategy
5. **[U] Process unmanaged** - Handle unmanaged files first
6. **[C] Cancel** - Exit without changes

**IMPORTANT: This command will NEVER automatically apply changes.**
**You must explicitly run `chezmoi apply` after review.**

Enter your choice:
</output_format>

<user_options>
## Option Details

### [B] Create backup
- Runs `/chezmoi-backup` to save current state
- Creates timestamped backup in ~/.chezmoi-backups/
- Allows safe experimentation

### [D] View detailed diff
- Shows full output of `chezmoi diff --exclude=externals`
- Color-coded additions/removals
- File-by-file breakdown

### [S] Selective review
- Review each file individually
- Choose which changes to accept
- Create custom apply strategy

### [P] Plan integration
- Enter planning mode for complex merges
- Create detailed strategy document
- Identify conflicts to resolve manually

### [U] Process unmanaged
- Launch `/chezmoi-unmanaged` command
- Add/ignore files before integration
- Return here when complete

### [C] Cancel
- Exit without making any changes
- Suggest next steps
</user_options>

<selective_review_workflow>
When user chooses [S] Selective review:

For each file with changes:
```
File: ~/.example
Changes: [brief summary]
Risk: [High/Medium/Low]

Options:
[V] View full diff for this file
[A] Mark for apply (accept chezmoi version)
[K] Keep current (preserve local version)
[M] Merge manually later
[S] Skip to next file

Choice:
```

After review, provide summary and next steps.
</selective_review_workflow>

<safety_features>
- NO automatic `chezmoi apply` - user must run explicitly
- Backup recommendations before any changes
- Clear risk assessment for each change
- Preserve user customizations by default
- Detailed diff viewing before decisions
</safety_features>

<detailed_changes_display>
When showing detailed changes, format as:

#### 🔴 High Risk - Potential Data Loss
These changes would remove content from your current files:

**File: ~/.zshrc**
```diff
- alias myproject='cd ~/projects/important-work'
- export CUSTOM_VAR="my-special-value"
```
**Risk**: These appear to be custom additions that would be lost
**Recommendation**: Save these changes before applying

#### 🟡 Medium Risk - Configuration Changes
These changes modify existing configurations:

**File: ~/.gitconfig**
```diff
- email = old@example.com
+ email = new@example.com
```
**Risk**: Email configuration would be changed
**Recommendation**: Verify the new email is correct

#### 🟢 Low Risk - Safe Additions
These changes add new content without removing anything:

**File: ~/.bashrc**
```diff
+ source ~/.bash_aliases
+ export PATH="$PATH:/usr/local/bin"
```
**Risk**: Only adding content, no data loss
**Recommendation**: Safe to apply
</detailed_changes_display>

<next_steps>
After analysis, always remind user:

1. Review the analysis carefully
2. Create a backup with `/chezmoi-backup` if needed
3. When ready, manually run `chezmoi apply` or `chezmoi apply [specific-file]`
4. Use `/chezmoi-undo` if you need to restore from backup
</next_steps>