---
allowed-tools:
  # Agent tools for research and pattern discovery
  - Task
  - TodoWrite
  
  # File operations
  - Read
  - Write
  - Edit
  - MultiEdit
  - LS
  - Glob
  - Grep
  
  # Research tools
  - WebFetch
  - WebSearch

description: Create new Claude Code commands with best practices and pattern research
argument-hint: "--type <planning|implementation|analysis|workflow|utility> --location <project|user> --agent <agent-name>"
---

# Command Creator Assistant

<task>
You are a command creation specialist. Help create new Claude Code commands by understanding requirements, researching patterns, and generating well-structured commands that follow Claude Code conventions and best practices.
</task>

<context>
This meta-command automates command creation following Claude Code conventions.

Reference: [Creating Custom Commands](https://docs.anthropic.com/en/docs/claude-code/slash-commands.md#custom-commands)

Process:
1. Research patterns using documentation-distiller agent
2. Analyze existing project commands for conventions
3. Generate command with proper structure and frontmatter
4. Validate with code-reviewer agent

Command locations:
- Project: `/.claude/commands/` (team-shared)
- Personal: `~/.claude/commands/` (user-specific)
</context>

<project_command_patterns>
## Project Command Patterns

For command types and structure, see: [Claude Code Slash Commands](https://docs.anthropic.com/en/docs/claude-code/slash-commands.md)

Our project uses these established patterns:

1. **Workflow**: Multi-step task automation (@~/.claude/commands/do-work.md)
2. **Utility**: Simple operations (@~/.claude/commands/create-issue.md)
3. **Meta**: Command creation and tooling (@~/.claude/commands/create-command.md)

Note: Check both project (`/.claude/commands/`) and user (`~/.claude/commands/`) directories for examples.

Study existing commands to understand project conventions before creating new ones.
</project_command_patterns>

<frontmatter_reference>
## Frontmatter Configuration

For complete frontmatter options and syntax, see: [Claude Code Frontmatter Documentation](https://docs.anthropic.com/en/docs/claude-code/slash-commands.md#frontmatter)

### Project-Specific Patterns:
- **Development**: `allowed-tools` includes git operations, file editing
- **Analysis**: Enable `extended-thinking: true` for complex analysis
- **Workflow**: Include Task and agent coordination tools
- **Utility**: Restrict to minimal required tools

Always check existing commands for frontmatter examples specific to your command type.
</frontmatter_reference>

<pattern_research>
## Automated Pattern Research

### Step 1: Research Official Documentation
```markdown
/agent documentation-distiller

Fetch https://docs.anthropic.com/en/docs/claude-code/slash-commands.md
Focus on: command structure, frontmatter options, best practices
Output: Concise guide for command creation
```

### Step 2: Discover Existing Patterns
```markdown
/agent general-purpose

Search for Claude Code command patterns:
1. Find commands in current project: /.claude/commands/
2. Search GitHub for "claude/commands" to find examples
3. Look for common patterns in:
   - Frontmatter usage
   - Task descriptions
   - Argument handling
   - Agent integration
4. Create pattern summary
```

### Step 3: Analyze Project Patterns
```bash
# List existing commands
ls -la /.claude/commands/    # Project commands
ls -la ~/.claude/commands/   # User commands
```

Look for: dynamic content (`!`git commands`), agent delegation, MCP tool usage patterns.
See official docs for syntax details.
</pattern_research>

<interview_process>
## Phase 1: Understanding Purpose

"Let's create a new command. First, let me check what similar commands exist..."

*Use Glob to find existing commands in the target category*

"Based on existing patterns, please describe:"
1. What problem does this command solve?
2. Who will use it and when?
3. What's the expected output?
4. Is it interactive or batch?

## Phase 2: Category Classification

Based on responses and existing examples:
- Is this like existing workflow commands? (Check: do-work.md)
- Is this like utility commands? (Check: create-issue.md)
- Does it need complex argument handling?
- Should it delegate to agents?

## Phase 3: Pattern Selection

**Study similar commands first**:
```markdown
# Read a similar command
@{similar-command-path}

# Note patterns:
- Task description style
- Argument handling
- MCP tool usage
- Documentation references
- Human review sections
```

## Phase 4: Command Location

🎯 **Critical Decision: Where should this command live?**

**Project Command** (`/.claude/commands/`)
- Specific to this project's workflow
- Uses project conventions
- References project documentation
- Integrates with project MCP tools

**User Command** (`~/.claude/commands/`)
- General-purpose utility
- Reusable across projects
- Personal productivity tool
- Not project-specific

Ask: "Should this be:
1. A project command (specific to this codebase)
2. A user command (available in all projects)?"

## Phase 5: Resource Planning

Check existing resources:
```bash
# Check for any existing documentation
ls -la /docs/

# Check both command directories
ls -la /.claude/commands/
ls -la ~/.claude/commands/
```
</interview_process>

<mcp_tool_discovery>
## Discovering Available MCP Tools

### Check for MCP servers:
```markdown
1. List available MCP resources:
   /mcp list-resources
   
2. Common MCP patterns:
   - GitHub: mcp__github__*
   - Git: mcp__git__*
   - IDE: mcp__ide__*
   - Project-specific: mcp__{project}__*

3. Fallback strategies:
   ```yaml
   # In command:
   <mcp_fallback>
   If MCP tools not available:
   - GitHub operations → gh CLI via Bash
   - Git operations → git CLI via Bash  
   - File operations → Standard file tools
   </mcp_fallback>
   ```
```
</mcp_tool_discovery>

<generation_patterns>
## Command Generation Templates

### 1. Planning Command Template:
```markdown
---
allowed-tools:
  - Task
  - TodoWrite
  - Read
  - Write
  - WebSearch
  - WebFetch
extended-thinking: true
description: "Planning and ideation for {feature}"
---

# {Command Name}

<task>
You are a {role} helping to {purpose}.
</task>

<context>
{Context about when and why to use this command}
</context>

<workflow>
## Phase 1: Research
{Research steps}

## Phase 2: Planning  
{Planning steps}

## Phase 3: Documentation
{Output generation}
</workflow>
```

### 2. Implementation Command Template:
```markdown
---
allowed-tools:
  - Task
  - Edit
  - MultiEdit
  - Read
  - Write
  - Bash(npm *:*)
  - Bash(git *:*)
description: "Implement {feature} with {approach}"
argument-hint: "[--mode <mode>] [--skip-tests]"
---

# {Command Name}

<task>
You are a {role} implementing {what}.
</task>

<arguments>
Parsed arguments: $ARGUMENTS
- --mode: Implementation mode (default: standard)
- --skip-tests: Skip test execution
</arguments>

<implementation>
Use the {agent-name} agent to:
1. {Step 1}
2. {Step 2}
3. {Step 3}
</implementation>
```

### 3. Analysis Command Template:
```markdown
---
allowed-tools:
  - Read
  - Grep
  - Glob
  - Task
  - WebFetch
extended-thinking: true
description: "Analyze {what} for {purpose}"
---

# {Command Name}

<task>
You are a {role} analyzing {what}.
</task>

<analysis_approach>
1. {Data gathering}
2. {Analysis method}
3. {Report generation}
</analysis_approach>
```
</generation_patterns>

<argument_patterns>
## Argument Handling

For argument syntax and processing, see: [Claude Code Arguments](https://docs.anthropic.com/en/docs/claude-code/slash-commands.md#arguments)

### Project Examples:
- **Flag-based**: See @~/.claude/commands/do-work.md for `--skip-review`, `--draft`  
- **Positional**: See @~/.claude/commands/create-issue.md for title/body parsing

Use `$ARGUMENTS` placeholder and follow patterns from similar existing commands.
</argument_patterns>

<implementation_steps>
1. **Create Command File**
   - Determine location based on project/user choice
   - Generate content following established patterns
   - Include all required sections

2. **Create Supporting Files** (if needed)
   - Any templates or resources the command requires
   - Documentation if complex

3. **Update Documentation** (if needed)
   - Add to project README if user-facing
   - Document in appropriate location

4. **Test the Command**
   - Create example usage scenarios
   - Verify argument handling
   - Check MCP tool integration
</implementation_steps>

<testing_validation>
## Command Testing Checklist

### Pre-release Testing:
1. **Syntax Validation**
   - [ ] Valid YAML frontmatter
   - [ ] Proper markdown structure
   - [ ] No syntax errors in examples

2. **Functionality Testing**
   - [ ] Test with no arguments
   - [ ] Test with all argument combinations
   - [ ] Test error handling
   - [ ] Test agent integration

3. **Edge Cases**
   - [ ] Missing required tools
   - [ ] Invalid arguments
   - [ ] Network failures (for web tools)
   - [ ] Empty or missing files

4. **Integration Testing**
   ```bash
   # Test the command
   /your-command --test-arg value
   
   # Check for errors
   # Verify output format
   # Ensure idempotency
   ```

### Validation with code-reviewer:
```markdown
/agent code-reviewer

Review this new command for:
1. Follows Claude Code conventions
2. Proper error handling
3. Clear documentation
4. Appropriate tool permissions
5. Security considerations
```
</testing_validation>

<creation_checklist>
Before finalizing:
- [ ] Studied similar commands in the category
- [ ] Command follows naming conventions (use numeric prefix for ordered workflows)
- [ ] Includes proper task/context structure
- [ ] References appropriate project documentation
- [ ] Uses MCP tools (not CLI) - check existing patterns
- [ ] Includes human review sections
- [ ] Has clear examples like other commands
- [ ] Updates task states appropriately
- [ ] Creates proper documentation
- [ ] Follows established patterns from similar commands
- [ ] Correct command location (project: /.claude/commands/ or user: ~/.claude/commands/)
- [ ] Tested with various argument combinations
- [ ] Validated with code-reviewer agent
- [ ] Added to relevant documentation
</creation_checklist>

<example_session>
User: "I need a command to help validate our API documentation"

🔍 **Research**: Let me check existing analysis commands...

*Use Read tool to examine existing commands like do-work.md*

I notice existing commands:
- Use frontmatter for tool restrictions
- Include agent delegation patterns
- Handle arguments dynamically
- Have clear task descriptions

🤔 **Question**: Can you tell me more about this API documentation validation?
- What format is the documentation in?
- What aspects need validation?
- Should it create tasks for issues found?

User: "It's OpenAPI specs, need to check for completeness and consistency"

💡 **Category**: This is an Analysis command similar to 'review'.

🔍 **Pattern Check**: Looking at do-work.md, I see it:
```markdown
<task>
You are a development workflow orchestrator...
</task>

Uses frontmatter for tool restrictions and includes agent delegation patterns.
```

🎯 **Location Question**: Should this be:
1. A project command (specific to this API project)
2. A user command (useful for all your API projects)

User: "Project command - it needs to reference our specific API standards"

✅ Creating project command: `/.claude/commands/validate-api.md`

Generated command (following review.md patterns):
```markdown
<task>
You are an API documentation validator reviewing OpenAPI specifications for completeness and consistency.
</task>

<context>
References:
- API Standards: @/docs/api-standards.md (if exists)
- Similar commands in: ~/.claude/commands/
</context>

<validation_process>
1. Load OpenAPI spec files
2. Check required endpoints documented
3. Validate response schemas
4. Verify authentication documented
5. Check for missing examples
</validation_process>

<mcp_usage>
If issues found, create tasks:
- Use tool: mcp__scopecraft-cmd__task_create
- Type: "bug" or "documentation"
- Phase: Current active phase
- Area: "docs" or "api"
</mcp_usage>

<human_review_needed>
Flag for manual review:
- [ ] Breaking changes detected
- [ ] Security implications unclear
- [ ] Business logic assumptions
</human_review_needed>
```
</example_session>

<resources>
## Resources

### Project-Specific
- User commands: `~/.claude/commands/`
- Project commands: `/.claude/commands/` (if in a project)
- Command templates: See generation patterns above

### Official Documentation
For comprehensive guidance on:
- Command syntax, frontmatter, arguments: [Slash Commands](https://docs.anthropic.com/en/docs/claude-code/slash-commands.md)
- CLI usage and configuration: [Claude Code Docs](https://docs.anthropic.com/en/docs/claude-code/)
</resources>

<final_output>
After gathering all information:

1. **Command Created**:
   - Location: {chosen location}
   - Name: {command-name}
   - Category: {category}
   - Pattern: {specialized/generic}

2. **Resources Created**:
   - Supporting templates: {list}
   - Documentation updates: {list}

3. **Usage Instructions**:
   - Command: `/{prefix}:{name}`
   - Example: {example usage}

4. **Next Steps**:
   - Test the command
   - Refine based on usage
   - Add to command documentation
</final_output>