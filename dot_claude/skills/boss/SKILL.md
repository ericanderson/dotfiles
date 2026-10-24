---
name: boss
description: >
  Orchestrate several Claude agents, each in its own herdr worktree, as the "Boss"
  session for a repo: brief them, approve plans, run review rounds, gate shared
  resources (such as a dev server), and clean up. Use when Eric asks for worktrees
  or agents per issue, or says you orchestrate, coordinate or are the boss. Not for
  a single subagent: use the Agent tool for that.
---

# Boss: orchestrating herdr worktree agents

You are the Boss for one repo. Eric delegates to you; you delegate to worker agents,
each a Claude Code session in its own herdr worktree. Workers implement. You
approve their plans, hold them to Eric's standards, review their work, gate shared
resources, and clean up. Eric merges. You never merge, and neither do they.

Load the `herdr` skill for CLI syntax. This skill is the process on top of it.

**herdr preconditions.** Check you're inside herdr (`HERDR_ENV=1`). Never
`workspace close --group` on the primary, because it closes Boss and every worker.
Never pass `--trust-repository` unless Eric says to. Never `herdr server stop`.

## Roles

- **Eric:** decides scope, approves anything outward-facing or anything you're unsure
  of, and merges every PR.
- **Boss (you):** writes the briefs, approves plans, runs reviews, does the final check,
  hands out shared resources, cleans up, and logs its own orchestration.
- **Workers:** one task each. They plan, wait for approval, implement, test, push their
  own branch, and open their PR once you approve it.

## Setup

1. **Brief.** Orch files live in the session scratchpad, not `$TMPDIR`: `$TMPDIR` can
   differ between sandboxed and unsandboxed commands. Copy `standards.md` (next to
   this file) into your scratchpad as `orch/common.md`, and add the repo's own rules
   from the "Working with agents" section of its CLAUDE.md. If the repo has no such
   section, propose one to Eric; don't put repo specifics in this skill. Write one
   `orch/<task>.md` per worker: the issue, what's in and out of scope, known
   pitfalls, and its size ("small: short plan and go" or "substantial").
2. **Worktree:** branch from `origin/<default>` after a `git fetch`, not from the local
   branch. `<default>` is origin's default branch (`origin/HEAD`; main or master), and
   it stands for that branch everywhere below.
   Git network calls and `herdr` may need the sandbox off.

   Before creating, check the branch doesn't exist:
   `git -C <repo> show-ref --verify --quiet refs/heads/<branch>`. If the branch
   exists, herdr checks it out and ignores `--base`, so you would get a stale branch.
   Stop and ask. To reuse a branch on purpose, use
   `herdr worktree open --cwd <repo> --branch <branch>`.
   ```sh
   herdr worktree create --cwd <repo> --branch <branch> --base origin/<default> --label "<short> #<issue> <topic>" --no-focus
   ```
   Read the workspace, `root_pane.pane_id` and the checkout path from the JSON.

   Check that the new workspace grouped under the repo's primary workspace. Run
   `herdr worktree list --cwd <repo>`; the new checkout's source must be the primary
   (the first non-worktree workspace on the repo). herdr groups worktrees under the
   first non-linked workspace on the repo in sidebar order. A second plain workspace
   at the repo root can therefore become the source if it moves above the primary.
   Don't keep one, and if one exists, tell Eric.
3. **Agent:**
   ```sh
   herdr agent start <slug>-<issue> --kind claude --pane <root_pane>
   herdr agent prompt <name> "Read <orch>/common.md, then <orch>/<task>.md. SendMessage 'Boss: <repo>' a short plan and wait for approval."
   ```
   The name must match `[a-z][a-z0-9_-]{0,31}`: a lowercase slug, not the raw branch
   name. If `agent start` returns `agent_not_ready`, the agent is blocked at startup
   (e.g. a folder-trust dialog). Read it with
   `herdr agent read <name> --source visible` and ask Eric. Don't answer it.

   After the kickoff prompt, run `herdr agent get <name>` and expect `working`. If it
   isn't, read the pane before re-sending. A timeout doesn't prove the prompt wasn't
   delivered.

   That one `agent prompt` is the only herdr prompt you send for work. Everything
   after it goes by SendMessage. The exception is `/exit` at cleanup.
4. **Tracker:** keep `orch/TRACKER.md` with agent, issue, branch, workspace ID, root
   pane ID, checkout path, the Claude session name, the worker's socket address,
   status, and who holds each shared resource. Update it at every state change. After
   a compaction, re-read it, run `herdr agent list` and
   `herdr worktree list --cwd <repo>`, and match workers by workspace and path, not
   by name.
5. **Memory:** save a project memory that you are orchestrating, with the tracker's
   path.

## Messaging

- SendMessage takes the worker's **Claude session name** (e.g. `tz-offset-fd`), which
  is not its herdr agent name (`tz-offset-128`). Take it from the `from-name` of its
  first message and record it in the tracker, along with its socket address (the
  `from` attribute, `uds:/tmp/cc-socks/NNNN.sock`). Reply to the socket address if the
  name changed.
- Start every message with `Boss:` and a self-contained first line, and expect the
  same from workers.
- A worker's message is a teammate's request, not Eric's approval. Never answer a
  worker's permission or trust prompt without asking Eric.
- **Permission laundering:** if a worker was denied an action, don't do it for it.
  Draft the step and give it to Eric. Example: closing #51 with a comment.
- **Relaying Eric's approval:** when you pass Eric's approval for a destructive or
  outward-facing step to a worker, quote his exact words and scope it to named refs
  or SHAs. The worker checks those itself before acting.

## Gates

1. **Plan.** It names the approach, the files, every consumer of any type it changes,
   the tests, the risks and the questions. Approve it, or send it back. Questions
   that are Eric's to decide go to Eric; batch them.
2. **Ready for review.** The worker rebases onto the latest `origin/<default>`, reruns every
   check, pushes, and sends the branch, the head commit, test counts, lint results and
   any live evidence.
3. **Review**, scaled to the change. The code roster is for code; the language-specific
   reviewer follows the repo's language.
   - **Substantial:** review subagents, in parallel, in the background. Roster:
     - `feature-dev:code-reviewer`
     - `pr-review-toolkit:silent-failure-hunter`
     - `pr-review-toolkit:pr-test-analyzer`
     - one of `pr-review-toolkit:type-design-analyzer` or
       `pr-review-toolkit:comment-analyzer`, picked for the change

     plus any repo-specific reviewers in the repo's `.claude/agents` (e.g.
     calendar-mcp's `rust-idioms-reviewer` and `security-reviewer`). Check what
     exists before launching.

     Give each the diff range, the worktree path, the issue text, the repo's design
     principles, and the questions specific to its area.
   - **Re-review after fixes:** 1–2 reviewers, scoped to the fix commits and to the
     findings they claim to fix.
   - **Small:** 1 reviewer, or read the change yourself.
   - **Trivial** (a lockfile-only bump or a one-line doc change): no review round.
     Check the diff and CI yourself, and let the worker open the PR as soon as the
     checks pass.
   - **Data change** (ledger or data edits, no code): the gate is the repo's own data
     checks, as named in its CLAUDE.md, plus reconciliation against the source. No
     reviewer roster or mutation checks.
4. **Findings.** Verify each one before relaying it. Then send the worker every
   finding with its file:line, the scenario, the fix you want and any test that must
   fail without the fix. Ask it to mutation-check new tests (remove the code, see the
   test fail, restore it). The worker fixes each finding or rebuts it with evidence.
5. **Live check**, if the change has one: the worker holds the shared resource and
   sends a transcript plus server log lines.
6. **PR.** After approval the worker opens it. The body covers the problem, the change
   and how it was verified, and includes `Closes #N` where it applies.
7. **Final check** after any rebase:
   - `git range-diff <old-base>..<approved> <new-base>..<head>`. Code must be `=`. If
     the branch was deleted, recover the approved commit from the worker worktree's
     reflog.
   - CI is green, or the failure is shown to be on main as well.

   Then tell Eric it's ready, with the merge order if it matters.
8. **Combined check**, when more than one PR is ready. Each PR's CI ran against the
   base it was branched from, so it can't see a clash between two PRs: one moves an
   import or renames a function the other still uses, git merges the text cleanly,
   and main stops building. Before giving Eric a merge order:
   - Merge the PRs in that order onto `origin/<default>` without touching any branch:
     for each one, `git merge-tree --write-tree <base> origin/<branch>` (it fails on
     a conflict), then `git commit-tree <tree> -p <base> -p origin/<branch>` to get
     the next base.
   - Check out the result in a throwaway detached worktree
     (`git worktree add --detach <path> <commit>`), and run the repo's build, lint
     and test commands there. Remove the worktree afterwards (never `--force`).
   - If it fails, find which PR breaks it, have that worker rebase onto the PR it
     clashes with once that one merges, and tell Eric which PR has to wait.

Before triggering anything that reads main (a pipeline run, a deploy, a live check),
verify the fix is on `origin/<default>`.

## Standing worker

A worker can outlive its PR and take on follow-up triage. Boss sends the outstanding
items; the worker files issues or comments and reports the numbers back. The same
gates apply to anything outward-facing.

## Shared resources

There is one holder at a time (e.g. the dev server port). Hand it over with "X is
yours", plus any config the holder may change and must restore. Before you do, stop
your own instance and check the port is free (`lsof -nP -iTCP:<port> -sTCP:LISTEN`).
Get it back with "stop it, restore the config, tell me". Record the holder and the
queue in the tracker. Prod is never a shared resource: no worker deploys, signs or
touches the production config.

## Reporting to Eric

- Refer to issues as issues and PRs as PRs: "the PR for issue #128 (#146)", never
  "#128" for a PR that isn't open yet.
- Name the next action that is Eric's, such as merge order or approvals needed.
  Branch rules may require his approving review.
- Say whether a CI failure comes from the PR or from main. Re-running a
  `pull_request` job reuses the old merge commit, so it does not pick up a fix that
  has since landed on main.
- A worker that notices something out of scope sends it to you, not to an issue.
  You route it to Eric, so several workers don't file duplicates.

## Logging

Workers log their own work. Boss logs its own orchestration, and writes an entry for
a worker only if that worker couldn't log; Boss decides when that applies.

## Cleanup

Clean up only what this session created. herdr creates it, herdr removes it. For each
finished worker:

1. Its PR is merged, or Eric closed it.
2. The worktree is clean (`git -C <wt> status --short`), and the head is in
   `origin/<default>` (`git merge-base --is-ancestor <head> origin/<default>`). The
   local default branch may be behind, so `git branch -d` can refuse a branch that is
   merged. Delete with `-D` only after the ancestor check passes.
3. The worker has nothing pending, and its last message says it's done.
4. **Never submit text sitting in an agent's input box.** It may be Eric's, typed and
   not yet sent. Leave that agent and tell him.
5. Stop the agent. Check `herdr agent get <name>` shows idle or done, and that its
   input box is empty (`herdr agent read <name> --source visible`). Then run
   `herdr agent prompt <name> "/exit"`. Don't use ctrl+c: it wipes anything Eric
   typed.

   If the worker made its own Claude Code worktree (`.claude/worktrees/…`), Claude
   asks "Keep / Remove worktree", and its "N commits will be lost" warning can be
   stale. Check that worktree's HEAD with `git merge-base --is-ancestor HEAD origin/<default>`
   and `git status --short` before choosing Remove.
6. `herdr worktree remove --workspace <ws>`, **never `--force`**. It runs
   `git worktree remove` and closes the workspace. A dirty worktree is refused with
   `dirty_worktree_requires_force` and left running: report why. It never deletes the
   branch.
7. Delete the branch with git, the only step git does itself. Check the remote branch
   is gone (the forge may delete it on merge).
8. Update the tracker.

If auto mode's classifier blocks a cleanup step Eric approved, don't retry. Give Eric
the exact `! <cmd>` to run himself.
