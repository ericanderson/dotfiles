---
name: claude-log
description: >
  Log significant Claude Code actions to Obsidian vault. Invoke after completing
  features, bug fixes, refactors, deployments, cleanups, or any substantial task.
  Only for top-level sessions. Do NOT invoke this if you are a subagent that
  another agent launched with the Agent tool inside its own session.
allowed-tools:
  - Agent
  - Read(~/Vaults/Personal/ClaudeLog/*)
  - Write(~/Vaults/Personal/ClaudeLog/*)
  - Edit(~/Vaults/Personal/ClaudeLog/*)
  - Grep(~/Vaults/Personal/ClaudeLog/*)
  - Bash(date +%Y%m%d-%H%M%S)
  - Bash(date +%Y-%m-%d)
  - Bash(date +%H:%M:%S)
  - Bash(date +%H:%M)
  - Bash(hostname)
  - Bash(pwd)
  - Bash(git branch --show-current 2>/dev/null || echo 'n/a')
---

# Claude Action Logger

Log significant actions to the Obsidian vault at `~/Vaults/Personal/ClaudeLog/`.

## Stop: only the top-level agent logs

**Check this before doing anything else.**

This log is a record of a session with the human, written once, by the agent
that talked to them. If you are a subagent, you are one step inside someone
else's session and must not write your own entry.

This rule is about subagents launched with the Agent tool inside one session.
A separate Claude Code session running in its own pane or terminal (for example
a herdr worker started and briefed by a Boss session) is a top-level session and
logs its own work, even though another session gave it its task.

You are a subagent if another agent launched you in-process with the Agent tool
rather than you running as your own session. The clearest tell is your own
instructions: if they refer to "the agent that launched you" or describe you as
having been spawned or delegated to with the Agent tool, then that is what you
are. A brief from a Boss session, such as a herdr worker's `common.md`, does not
make you a subagent. Do not go looking in the environment for proof —
subagents share the main agent's process, PID and session id, so nothing there
will tell you either way. `CLAUDE_CODE_CHILD_SESSION` in particular is set for
the main agent too and means nothing here.

If you are a subagent: **stop now.** Do not draft, do not write a file. Say in
your final report that you skipped logging because the agent that launched you
owns it, and put anything worth recording in that report instead — the agent
that launched you can then log it as part of the wider session.

If you are unsure, do not log. A missing subagent entry costs nothing; the
top-level agent still logs the same work with better context. Duplicate
fragments from three subagents are noise nobody asked for.

## What an entry is for

Almost nobody reads these entries, so each one has to be quick to write and
quick to read. An entry holds only what git history and pull requests do not:

- why the work was done
- decisions, and the reason for each
- what was not verified
- what is still open, including steps left for Eric and ideas that were parked

Leave out file-by-file lists, commands run, commit lists, glossaries, and
anything a PR body or commit message already says. Point to those instead: a PR
URL, an issue number with its repo, or a commit hash.

**Length: at most 15 lines of body per entry or per appended section**, not
counting frontmatter and the AI-generated callout. If the work landed in a PR
whose body covers the problem, the change and the verification, the body is the
PR link plus whatever is unverified or open. That can be three lines.

## One entry per session

A session has one entry. Before drafting, search for an entry this session
already wrote:

    Grep for "session_id: <your session id>" in ~/Vaults/Personal/ClaudeLog/

- **No match:** write a new entry (Phase 1 to 3 below).
- **Match:** append to that file. Read it, then use Edit to add a new section
  at the end, headed `## HH:MM <short title>`, under the same 15-line limit.
  Update the frontmatter `summary` so it covers the whole session. Never
  rewrite or shorten the earlier sections.

If you do not know your session id, write `session_id: unknown` and always
create a new entry.

## Instructions

### Phase 1: Draft

1. Derive a 3-5 word slug from `$ARGUMENTS` (lowercase, hyphen-separated).
2. New entry: the filename is !`date +%Y%m%d-%H%M%S`-slug.md and the content
   follows the template below. Appending: draft only the new section.
3. Do not write the file yet.

### Phase 2: Clean room inspection

Launch the `log-inspector` agent (subagent_type: "log-inspector"). Its prompt
is the draft and nothing else: no summary of the session, no instructions. When
appending, send the existing entry with the new section added at the end.

It replies with at most three gaps, or "No gaps."

If `log-inspector` is not an available agent type, skip this phase and say so in
your final message. Do not substitute another agent type.

### Phase 3: Revise and write

4. Fix the gaps that are real, using what you know from the session. Fix them
   by making a line more specific, not by adding lines. The 15-line limit still
   holds; if a fix does not fit, cut something less important.
5. Write the new file, or apply the Edit that appends the section.

<output-template>
---
date: "!`date +%Y-%m-%d`"
time: "!`date +%H:%M:%S`"
hostname: !`hostname`
directory: !`pwd`
git_branch: !`git branch --show-current 2>/dev/null || echo 'n/a'`
session_id: {the current session id}
summary: "{1-2 sentences covering the whole session so far}"
---

> [!warning] AI-generated content
> This log entry was written by Claude, not by EA. It records what Claude did in one session.

# {Short title}

**Why:** {1-2 sentences: the trigger, pain point or request}

**Done:** {1-3 sentences on the outcome, with the PR URL, issue or commit hash that holds the detail}

**Decisions:** {only if any: each decision with its reason}

**Not verified:** {only if any}

**Open:** {only if any: steps left for Eric, parked ideas, known issues, each specific enough to pick up}
</output-template>
