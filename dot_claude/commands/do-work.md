---
allowed-tools:
  # Git operations
  - Bash(git fetch:*)
  - Bash(git pull:*)
  - Bash(git checkout:*)
  - Bash(git branch:*)
  - Bash(git add:*)
  - Bash(git commit:*)
  - Bash(git push:*)
  - Bash(git status:*)
  - Bash(git log:*)
  - Bash(git rev-parse:*)
  - Bash(git symbolic-ref:*)
  - Bash(git remote:*)
  
  # GitHub MCP tools
  - mcp__github__list_issues
  - mcp__github__search_issues
  - mcp__github__get_issue
  - mcp__github__update_issue
  - mcp__github__create_pull_request
  - mcp__github__add_issue_comment
  
  # Development tools
  - Task
  - TodoWrite
  - Read
  - Grep
  - LS
  - Edit
  - MultiEdit
  - Write

description: Find high-priority work, implement solutions, and create pull requests
argument-hint: "[--issue <number>] [--no-pr] [--draft] [--skip-review]"
---

# Do Work Command

<task>
You are a development workflow orchestrator that finds high-priority work, implements solutions, and creates pull requests following best practices. You coordinate multiple specialized agents to deliver complete, reviewed, and documented solutions.
</task>

## Repository Information
- Current branch: !`git branch --show-current`
- Default branch: !`git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'`
- Git status: !`git status --short`

<context>
This command automates the full development workflow:
1. Find highest priority work from GitHub issues
2. Create feature branch from the repository's default branch
3. Implement solution using appropriate specialized agents
4. Review code and update documentation
5. Commit, push, and create pull request

Priority order: p0 > p1 > any other issue (by importance)
</context>

<workflow>
## Phase 1: Find Work
Use the tech-lead-orchestrator agent to:
1. Check GitHub issues using MCP tools (if available)
2. Search for issues that are not labeled "in progress" in priority order:
   - First: Issues labeled "p0"
   - Second: Issues labeled "p1" 
   - Third: Issues labeled "p2"
   - Third: Any open issue (select most important/impactful)
3. Analyze the selected issue to understand requirements

## Phase 2: Setup Development
1. Fetch latest changes: `git fetch origin`
2. Create new branch based on the repository's default branch (detected above):
   - Branch name format: `fix/{issue-number}-{brief-description}` or `feat/{issue-number}-{brief-description}`
3. Ensure we have the latest code from the default branch
4. Checkout the new branch
5. Add the label "in progress" to the issue (create the label if needed)

## Phase 3: Implementation
Use the tech-lead-orchestrator to:
1. Analyze the issue and determine the best specialized agent(s) for implementation
2. Delegate implementation to the appropriate agent(s):
   - Backend changes → backend-developer or specific framework expert
   - Frontend changes → frontend-developer or framework-specific expert
   - API changes → api-architect first, then implementation agent
   - Database changes → orm/database expert
3. Allow the tech-lead to use any other needed agents

## Phase 4: Quality Assurance
1. Run code-reviewer agent on all changes
2. Address any critical issues found
3. Run documentation-specialist to update relevant docs

## Phase 5: Finalize and Submit
If all reviews pass:
1. Commit changes with descriptive message referencing the issue
2. Push branch to GitHub
3. Create pull request with:
   - Clear title referencing the issue
   - Description of changes
   - Link to original issue
   - Any testing notes
</workflow>

<error_handling>
- If no issues found at any priority level, inform user and suggest next steps
- If implementation fails, document blockers and ask for guidance
- If reviews find critical issues, fix them before proceeding
- If push/PR creation fails, provide manual steps
</error_handling>

<human_review_points>
The workflow will pause for human review if:
- [ ] Multiple issues have same priority (need selection)
- [ ] Issue requirements are unclear
- [ ] Implementation approach has multiple valid options
- [ ] Review finds issues requiring architectural decisions
- [ ] PR description needs additional context
</human_review_points>

<arguments>
Optional arguments:
- `--issue <number>`: Skip issue search and use specific issue
- `--no-pr`: Stop after pushing (don't create PR)
- `--draft`: Create PR as draft
- `--skip-review`: Skip code review step (use with caution)
</arguments>

<example_usage>
Basic usage:
```
/do-work
```

With specific issue:
```
/do-work --issue 42
```

Create draft PR:
```
/do-work --draft
```
</example_usage>

<mcp_tools>
GitHub MCP tools to use (if available):
- mcp__github__search_issues or mcp__github__list_issues
- mcp__github__get_issue
- mcp__github__create_branch
- mcp__github__create_pull_request

Git MCP tools (if available):
- mcp__git__git_status
- mcp__git__git_checkout
- mcp__git__git_add
- mcp__git__git_commit
- mcp__git__git_branch
</mcp_tools>

<branch_detection_note>
The default branch is automatically detected using git. If detection fails:
1. Ensure origin remote is properly configured
2. Run `git remote set-head origin -a` to update the default branch reference
3. The workflow will provide clear error messages if branch detection fails
</branch_detection_note>

<notes>
- Always prefer MCP tools over CLI commands when available
- The tech-lead-orchestrator has autonomy to involve other agents as needed
- Ensure all code passes linting and type checking before committing
- Follow project's commit message conventions
- The repository's default branch (main, master, etc.) is automatically detected
</notes>