# cenv

A bash CLI for switching between named environment configurations stored in `~/.config/env.d/`.

## Concept

Each file under `~/.config/env.d/` is a shell script that exports environment variables for a specific context (e.g. a project, a cloud account, a deployment target). `cenv` lets you activate one of those files, inspect the variables it defines, or list what is available.

## Usage

```
cenv set <name>    Source ~/.config/env.d/<name> into the current shell
cenv list          List available environment files
cenv print         Print all exported variables defined across every env file, with their current values
cenv print last    Print only the variables from the last activated env file
```

## Commands

### `cenv set <name>`

Sources `~/.config/env.d/<name>` into the current shell session, making its exports available as environment variables. Sets `ENV_SET=<name>` so the active environment is tracked.

```bash
cenv set staging
```

### `cenv list`

Lists the filenames in `~/.config/env.d/`, sorted alphabetically.

```bash
cenv list
# dev
# prod
# staging
```

### `cenv print`

Scans every file in `~/.config/env.d/` for `export VAR` declarations, deduplicates the variable names, and prints each one alongside its current value in the shell.

```bash
cenv print
# AWS_PROFILE=staging
# DATABASE_URL=
# REGION=eu-west-1
```

### `cenv print last`

Like `cenv print`, but restricted to variables declared in the last file activated with `cenv set`. Requires that `cenv set` has been called at least once in the session.

```bash
cenv print last
# env: staging
#   AWS_PROFILE=staging
#   REGION=eu-west-1
```

## Tab completion

When sourced into bash, `cenv` registers tab completion:

- `cenv <TAB>` completes to `set`, `print`, or `list`
- `cenv set <TAB>` completes to filenames in `~/.config/env.d/`
- `cenv print <TAB>` completes to `last`

## Setup

Source the script in your `.bashrc` or equivalent:

```bash
source ~/path/to/cenv.sh
```

Requires `bash-completion` (`_get_comp_words_by_ref`) for tab completion to work.
