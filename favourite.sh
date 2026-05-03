#!/usr/bin/env bash

# ---------------------------------------------------------------------------
# favourite — CLI for running favourite scripts from ~/.config/favourite.d/
#
# Usage:
#   favourite add <name> <command>   Save a command as a favourite
#   favourite list                   List available scripts
#   favourite remove <name>          Delete ~/.config/favourite.d/<name>
#   favourite run <name>             Run ~/.config/favourite.d/<name>
# ---------------------------------------------------------------------------

# -- helpers ----------------------------------------------------------------

_favourite_files() {
  find "$HOME/.config/favourite.d/" -maxdepth 1 -type f -exec basename {} \;
}

_favourite_usage() {
  cat <<'EOF'
Usage: favourite <command>
  list                   List available scripts in ~/.config/favourite.d/
  show <name>            Show the command stored in a favourite
  run <name>             Run favourite with provided name (run file in ~/.config/favourite.d/<name>)
  add <name> <command>   Create favourite with provided name and command (add file in ~/.config/favourite.d/<name>)
  remove <name>          Delete favourite with provided name (delete file in ~/.config/favourite.d/<name>)
EOF
}

# -- subcommands ------------------------------------------------------------

_favourite_add() {
  local name="$1"; shift
  if [[ -z "$name" || $# -eq 0 ]]; then
    echo "Usage: favourite add <name> <command>"; return 1
  fi
  local dest="${HOME}/.config/favourite.d/${name}"
  if [[ -f "$dest" ]]; then
    echo "Error: favourite already exists: ~/.config/favourite.d/${name}"; return 1
  fi
  printf '#!/usr/bin/env bash\n%s\n' "$*" > "$dest"
  chmod +x "$dest"
  echo "Added favourite '${name}': $*"
}

_favourite_remove() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo "Usage: favourite remove <name>"; return 1
  fi
  local dest="${HOME}/.config/favourite.d/${name}"
  if [[ ! -f "$dest" ]]; then
    echo "Error: favourite not found: ~/.config/favourite.d/${name}"; return 1
  fi
  rm "$dest"
  echo "Removed favourite '${name}'"
}

_favourite_list() {
  _favourite_files | sort
}

_favourite_show() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo "Usage: favourite show <name>"; return 1
  fi
  local script="${HOME}/.config/favourite.d/${name}"
  if [[ ! -f "$script" ]]; then
    echo "Error: favourite not found: ~/.config/favourite.d/${name}"; return 1
  fi
  cat "$script"
}

_favourite_run() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo "Usage: favourite run <name>"; return 1
  fi
  local script="${HOME}/.config/favourite.d/${name}"
  if [[ ! -f "$script" ]]; then
    echo "Error: script not found: ~/.config/favourite.d/${name}"; return 1
  fi
  bash "$script"
}

# -- dispatch ---------------------------------------------------------------

function favourite() {
  local cmd="$1"; shift
  case "$cmd" in
    add)    _favourite_add "$@" ;;
    list)   _favourite_list ;;
    remove) _favourite_remove "$@" ;;
    run)    _favourite_run "$@" ;;
    show)   _favourite_show "$@" ;;
    *)     _favourite_usage; return 1 ;;
  esac
}
export -f favourite

# -- tab completion ---------------------------------------------------------

_favourite_completions() {
  local cur prev words cword
  _get_comp_words_by_ref -n : cur prev words cword

  case $cword in
    1) COMPREPLY=($(compgen -W "add list remove run show" -- "$cur")) ;;
    2)
      case "${words[1]}" in
        remove|run|show) COMPREPLY=($(compgen -W "$(_favourite_files)" -- "$cur")) ;;
      esac ;;
    *) ;;
  esac
}

complete -F _favourite_completions favourite
