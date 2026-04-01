---
name: claude-log
description: >
  Log significant Claude Code actions to Obsidian vault. Invoke after completing
  features, bug fixes, refactors, deployments, cleanups, or any substantial task.
allowed-tools:
  - Agent
  - Read(~/Vaults/Personal/ClaudeLog/*)
  - Write(~/Vaults/Personal/ClaudeLog/*)
  - Edit(~/Vaults/Personal/ClaudeLog/*)
  - Bash(date +%Y%m%d-%H%M%S)
  - Bash(date +%Y-%m-%d)
  - Bash(date +%H:%M:%S)
  - Bash(hostname)
  - Bash(pwd)
  - Bash(git branch --show-current 2>/dev/null || echo 'n/a')
---

# Claude Action Logger

Log significant actions to the Obsidian vault at `~/Vaults/Personal/ClaudeLog/`.

## Instructions

### Phase 1: Draft the Log

1. Derive a 3-5 word slug from `$ARGUMENTS` (lowercase, hyphen-separated)
2. Construct filename: !`date +%Y%m%d-%H%M%S`-slug.md
3. Draft the log content using the output template below (do NOT write the file yet)
4. Create a concise summary (1-2 sentences) for the frontmatter
5. List specific actions taken (files changed, commands run, tests executed, etc.)
6. Include git commit information ONLY if commits were made during this session
7. Add any relevant notes or context

### Phase 2: Clean Room Inspection

Before writing the file, launch a subagent (subagent_type: "general-purpose") to perform a clean room review of the drafted log. The subagent has no access to the conversation history — it sees only the draft.

Provide this prompt to the subagent:

> You are a clean room inspector reviewing a work log entry. You have NO context about the session — only the draft below. Your job is to identify gaps, ambiguities, and missing information that would make this log less useful to someone reading it weeks or months later.
>
> Review the draft and return a list of specific questions and gaps. Focus on:
>
> - **Vague actions**: Are any bullet points too generic? (e.g., "updated the config" — which config? what changed?)
> - **Missing why**: Does the log explain WHY the work was done, not just what?
> - **Missing outcomes**: Did the work succeed? Were tests run? What was the result?
> - **Unclear scope**: Would a reader know which files, functions, or systems were affected?
> - **Missing context**: Are there decisions, trade-offs, or rejected alternatives worth noting?
> - **Dangling references**: Does the log mention things (issues, PRs, branches) without enough detail to find them later?
> - **Follow-up gaps**: If there are next steps or known issues, are they specific enough to act on?
>
> Return your findings as a numbered list of questions/gaps. If the log is thorough and clear, say so — don't invent issues.
>
> ---
>
> DRAFT LOG:
> ```
> {paste the full drafted log content here}
> ```

### Phase 3: Revise and Write

8. Review the inspector's feedback
9. Revise the draft to address legitimate gaps (you have the conversation context the inspector lacked — use it)
10. Write the final log file to `~/Vaults/Personal/ClaudeLog/`

<output-template>
---
date: "!`date +%Y-%m-%d`"
time: "!`date +%H:%M:%S`"
hostname: !`hostname`
directory: !`pwd`
git_branch: !`git branch --show-current 2>/dev/null || echo 'n/a'`
session_id: ${CLAUDE_SESSION_ID}
summary: "{1-2 sentence summary of what was done}"
---

# {Short Title Based on Arguments}

## Why
{1-2 sentences on what motivated this work — the trigger, pain point, or request}

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
