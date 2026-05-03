# favourite

A bash CLI for saving and running named shell commands from `~/.config/favourite.d/`.

## Concept

Each file under `~/.config/favourite.d/` is a small executable bash script wrapping a single command. `favourite` lets you save commands under a memorable name, run them, inspect them, or remove them.

## Usage

```
favourite add <name> <command>   Save a command as a favourite
favourite list                   List saved favourites
favourite show <name>            Print the command stored in a favourite
favourite run <name>             Execute a favourite
favourite remove <name>          Delete a favourite
```

## Commands

### `favourite add <name> <command>`

Creates `~/.config/favourite.d/<name>` as an executable bash script containing `<command>`. Fails if a favourite with that name already exists.

```bash
favourite add deploy kubectl rollout restart deployment/api
# Added favourite 'deploy': kubectl rollout restart deployment/api
```

### `favourite list`

Lists the filenames in `~/.config/favourite.d/`, sorted alphabetically.

```bash
favourite list
# build
# deploy
# lint
```

### `favourite show <name>`

Prints the full contents of the stored script, so you can verify what a favourite does before running it.

```bash
favourite show deploy
# #!/usr/bin/env bash
# kubectl rollout restart deployment/api
```

### `favourite run <name>`

Executes `~/.config/favourite.d/<name>` in a new bash process.

```bash
favourite run deploy
```

### `favourite remove <name>`

Deletes `~/.config/favourite.d/<name>`. Fails if the favourite does not exist.

```bash
favourite remove deploy
# Removed favourite 'deploy'
```

## Tab completion

When sourced into bash, `favourite` registers tab completion:

- `favourite <TAB>` completes to `add`, `list`, `remove`, `run`, or `show`
- `favourite remove <TAB>`, `favourite run <TAB>`, and `favourite show <TAB>` complete to filenames in `~/.config/favourite.d/`

## Setup

Source the script in your `.bashrc` or equivalent:

```bash
source ~/path/to/favourite.sh
```

Requires `bash-completion` (`_get_comp_words_by_ref`) for tab completion to work.
