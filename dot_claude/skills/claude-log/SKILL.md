---
name: claude-log
description: >
  Log significant Claude Code actions to Obsidian vault. Invoke after completing
  features, bug fixes, refactors, deployments, cleanups, or any substantial task.
allowed-tools:
  - Read(~/Vaults/Personal/ClaudeLog/*)
  - Write(~/Vaults/Personal/ClaudeLog/*)
  - Edit(~/Vaults/Personal/ClaudeLog/*)
  - Bash(date +%Y%m%d-%H%M%S)
  - Bash(date +%Y-%m-%d)
  - Bash(date +%H:%M:%S)
  - Bash(hostname)
  - Bash(pwd)
  - Bash(git remote get-url origin)
  - Bash(git branch --show-current)
---

# Claude Action Logger

Log significant actions to the Obsidian vault at `~/Vaults/Personal/ClaudeLog/`.

## Instructions

1. Derive a 3-5 word slug from `$ARGUMENTS` (lowercase, hyphen-separated)
2. Construct filename: !`date +%Y%m%d-%H%M%S`-slug.md
3. Write markdown file to `~/Vaults/Personal/ClaudeLog/` using the output template below
4. Create a concise summary (1-2 sentences) for the frontmatter
5. List specific actions taken (files changed, commands run, tests executed, etc.)
6. Include git commit information ONLY if commits were made during this session
7. Add any relevant notes or context

<output-template>
---
date: "!`date +%Y-%m-%d`"
time: "!`date +%H:%M:%S`"
hostname: !`hostname`
directory: !`pwd`
git_remote: !`git remote get-url origin`
git_branch: !`git branch --show-current`
session_id: ${CLAUDE_SESSION_ID}
summary: "{1-2 sentence summary of what was done}"
---

# {Short Title Based on Arguments}

## Actions Taken
- {Bullet list of specific actions}
- {Files created/modified}
- {Commands run}
- {Tests executed}

## Commits
{Only include this section if commits were made during this session:}
- {commit hash}: {commit message}

{Otherwise omit this section entirely}

## Notes
{Any additional context, warnings, follow-up items, or observations}
</output-template>
