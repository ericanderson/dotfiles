# Cleanroom Skill Design

## Overview

A Claude Code skill (`/cleanroom`) that launches an isolated background agent with no conversation context. The skill uses the current conversation's full context to craft a detailed, self-contained prompt, then dispatches a read-only background agent to execute it.

## Problem

When you want an unbiased analysis or report, the current conversation's context (assumptions, prior decisions, debugging rabbit holes) can contaminate the agent's reasoning. A "clean room" agent that only sees a carefully crafted prompt produces more objective results.

## Design

### Skill Location

- **Chezmoi source**: `dot_claude/skills/cleanroom/SKILL.md`
- **Deployed to**: `~/.claude/skills/cleanroom/SKILL.md`
- **Scope**: Personal (available in all projects)

### Frontmatter

```yaml
name: cleanroom
description: >
  Launch an isolated read-only background agent with no conversation context.
  Crafts a self-contained prompt from current context for unbiased analysis/reporting.
argument-hint: <what to analyze or report on>
allowed-tools: Agent, Read, Grep, Glob, Bash
```

- `Agent` — needed to launch the background subagent
- `Read`, `Grep`, `Glob` — needed to gather context for prompt crafting
- `Bash` — needed for context gathering commands like `git log`, `chezmoi data`, etc.
- No `context: fork` — the skill itself needs conversation context to craft the prompt
- No `disable-model-invocation` — Claude can suggest using cleanroom when appropriate

### Execution Flow

1. User invokes `/cleanroom <rough description>` (if no argument, infer the task from conversation context or ask the user)
2. Skill instructs Claude to analyze the conversation context and codebase
3. Claude crafts a self-contained prompt following strict decontextualization rules
4. Claude launches `Agent` with `run_in_background: true`, subagent_type `general-purpose`
5. User sees a brief confirmation message summarizing what was dispatched (1-2 sentences describing the analysis task)
6. Background agent completes; user is notified with results

### Prompt Crafting Rules

The skill enforces these rules when crafting the prompt for the background agent:

1. **Self-contained**: The prompt must make complete sense to an agent with zero prior context. No "the file we discussed", no "as mentioned above".
2. **Specific**: Include all file paths, function names, class names, and relevant identifiers by their full names.
3. **Inline critical context**: When code snippets or file contents are central to the analysis, include them directly in the prompt rather than expecting the agent to find them.
4. **Explicit goal**: State exactly what the agent should analyze, what questions it should answer, and what format the output should take.
5. **Scoped**: Define clear boundaries — what's in scope, what's out of scope.
6. **Read-only enforcement**: The prompt explicitly instructs the agent that it may only read and search — no writes, edits, or mutations.

### Background Agent Constraints

The crafted prompt includes these constraints for the dispatched agent:

- **Read-only**: May use `Read`, `Grep`, `Glob`, `Bash` (read-only commands only). No `Write`, `Edit`, `MultiEdit`, or destructive bash.
- **No conversation context**: The agent receives only the crafted prompt. It has no access to the parent conversation's history.
- **Report format**: The agent should return a structured report with findings, not take actions.

### Example Usage

```
/cleanroom analyze whether our SSH config template handles all edge cases for work vs personal machines
```

Claude (with full context) would craft something like:

> You are a clean room analyst. You have no prior context about this project.
>
> Analyze the SSH configuration template at `~/.local/share/chezmoi/private_dot_ssh/private_config.tmpl`. This is a chezmoi template that generates `~/.ssh/config` with different settings based on whether the machine is a work machine (hostname matches `eanderson[0-9]+-mac`) or personal.
>
> Evaluate:
> 1. Are there edge cases where the hostname detection could fail?
> 2. Are all SSH options properly scoped to the right Host blocks?
> 3. Could any configuration leak between work/personal contexts?
>
> Return a structured report with findings and severity ratings.

### Read-Only Enforcement

The Agent tool does not support restricting a subagent's available tools. Read-only enforcement is therefore **prompt-level only** — the crafted prompt instructs the agent not to write or modify anything. This is a known limitation; the agent could technically use write tools if it ignored the instructions. This is acceptable because:
- The agent has no adversarial motivation to ignore constraints
- The user can review the agent's output and tool usage after completion
- Adding enforcement would require platform changes outside our control

## Decisions

- **Single skill, not two**: Originally considered `/cleanroom` + `/cleanroom-pure`, but `context: fork` doesn't support background execution. One skill that uses the Agent tool directly is simpler.
- **Fire-and-forget**: No review step for the crafted prompt. Speed over control.
- **Read-only**: Clean rooms are for reporting/analysis, not modification. Enforcement is prompt-level (see above).
- **Background by default**: These can take time; don't block the user.
- **No prompt size limits**: Claude naturally manages token budgets when crafting the prompt. Arbitrary limits would over-constrain without clear benefit.
- **Flexible report format**: The crafted prompt specifies output format per-invocation rather than enforcing a fixed template.
