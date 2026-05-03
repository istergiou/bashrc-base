# claude-code-artifact

A bash run command (bashrc) utility for managing Claude Code artifacts (skills, agents, commands) across project and personal scopes.

## Installation

```bash
source /path/to/claude-code-artifact.sh
```

Or add it to your `.bashrc`:

```bash
echo 'source /path/to/claude-code-artifact.sh' >> ~/.bashrc
```

## Usage

```
claude-code-artifact [options] <action> [artifact] [name|state]
```

## Options

| Option | Description |
|--------|-------------|
| `-o raw` | Output one name per line (list action only) |
| `-o json` | Output JSON with `name` and `state` fields (list action only) |

## Actions

| Action | Description |
|--------|-------------|
| `list` | List artifacts, optionally filtered by type and state |
| `enable` | Move an artifact from its `-disabled` directory to active |
| `disable` | Move an artifact from active to its `-disabled` directory |
| `copy-to-user` | Copy an artifact from the project `.claude/` to `~/.claude/` |
| `copy-to-project` | Copy an artifact from `~/.claude/` to the project `.claude/` |
| `move-to-user` | Move an artifact from the project `.claude/` to `~/.claude/` |
| `move-to-project` | Move an artifact from `~/.claude/` to the project `.claude/` |

## Artifact types

| Type | Directory |
|------|-----------|
| `skill` | `skills/` |
| `agent` | `agents/` |
| `command` | `commands/` |
| `all` | All three types (enable/disable only) |

## States (list action)

| State | Description |
|-------|-------------|
| `enabled` | Only artifacts in the active directory |
| `disabled` | Only artifacts in the `-disabled` directory |
| `any` | Both enabled and disabled |

When no state is given, `list` defaults to formatted output showing all states. When `-o raw` or `-o json` is given without a state, `any` is assumed.

## Directory layout

The tool recognises two scopes:

- **Project** — `.claude/` relative to the current working directory
- **Personal** — `~/.claude/`

Within each scope, enabled artifacts live in e.g. `skills/` and disabled ones in `skills-disabled/`. The `enable` and `disable` actions move files between these two directories; state is therefore preserved across copy/move operations.

## Examples

```bash
# List all artifacts (formatted with colours)
claude-code-artifact list

# List only skills
claude-code-artifact list skill

# List enabled skills, plain names
claude-code-artifact -o raw list skill enabled

# List disabled agents as JSON
claude-code-artifact -o json list agent disabled

# Disable a single skill
claude-code-artifact disable skill verify-docs

# Disable all agents
claude-code-artifact disable agent all

# Disable every artifact in both scopes
claude-code-artifact disable all

# Enable a single agent
claude-code-artifact enable agent web-researcher

# Enable all skills
claude-code-artifact enable skill all

# Enable every artifact in both scopes
claude-code-artifact enable all

# Copy an agent from project to personal (preserves enabled/disabled state)
claude-code-artifact copy-to-user agent web-researcher

# Copy a command from personal to project
claude-code-artifact copy-to-project command local-commit

# Move a skill from project to personal
claude-code-artifact move-to-user skill my-custom-skill

# Move an agent from personal to project
claude-code-artifact move-to-project agent api-documenter
```

## Conflict resolution

When an artifact is found in both project and personal locations (or in both enabled and disabled directories), the tool prompts interactively to choose which one to act on.

When copying or moving to a location where an artifact already exists, the tool prompts before overwriting.

## Internal functions

All helper functions are prefixed `_cca-` and are not intended to be called directly:

| Function | Purpose |
|----------|---------|
| `_cca-usage` | Print help text |
| `_cca-get-artifact-dir` | Map artifact type to directory name |
| `_cca-artifact-exists` | Test whether a path exists as a file or directory |
| `_cca-get-existing-path` | Resolve the actual filesystem path (with or without `.md`) |
| `_cca-action-list` | Implement the `list` action |
| `_cca-action-enable` | Implement the `enable` action |
| `_cca-action-disable` | Implement the `disable` action |
| `_cca-action-copy-to-user` | Implement the `copy-to-user` action |
| `_cca-action-copy-to-project` | Implement the `copy-to-project` action |
| `_cca-action-move-to-user` | Implement the `move-to-user` action |
| `_cca-action-move-to-project` | Implement the `move-to-project` action |
