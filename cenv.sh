#!/usr/bin/env bash

# ---------------------------------------------------------------------------
# cenv — unified CLI for managing environment files from ~/.config/env.d/
#
# Usage:
#   cenv set <name>    Source ~/.config/env.d/<name>
#   cenv print         Print all env.d variables and their current values
#   cenv print last    Print variables from the last sourced env
#   cenv list          List available environment files
# ---------------------------------------------------------------------------

mkdir -p "${HOME}/.config/env.d"

# -- helpers ----------------------------------------------------------------

_cenv_files() {
  find "$HOME/.config/env.d/" -maxdepth 1 -type f -exec basename {} \;
}

_cenv_usage() {
  cat <<'EOF'
Usage: cenv <command>
  set <name> [name2 ...]    Source one or more ~/.config/env.d/<name> files
  print                     Print all env.d variables and their current values
  print last                Print variables from the last sourced env(s)
  list                      List available environment files
EOF
}

# -- subcommands ------------------------------------------------------------

_cenv_set() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: cenv set <name> [name2 ...]"; return 1
  fi
  local name
  for name in "$@"; do
    if [[ ! -f "${HOME}/.config/env.d/${name}" ]]; then
      echo "Error: env settings not found: ~/.config/env.d/${name}"; return 1
    fi
  done
  for name in "$@"; do
    source "${HOME}/.config/env.d/${name}"
    echo "set env to ${name}"
  done
  export ENV_SET="$*"
}

_cenv_print() {
  local all_vars=""
  for file in ${HOME}/.config/env.d/*; do
    local vars
    vars=$(grep -oP '(?<=export )\w+' "$file" 2>/dev/null)
    [[ -n "$vars" ]] && all_vars+=$'\n'"$vars"
  done
  local sorted
  sorted=$(echo "$all_vars" | sort -u)
  while read -r var; do
    [[ -z "$var" ]] && continue
    echo "${var}=${!var}"
  done <<< "$sorted"
}

_cenv_print_last() {
  if [[ -z "$ENV_SET" ]]; then
    echo "No env set"; return 1
  fi
  local name
  for name in $ENV_SET; do
    local file="${HOME}/.config/env.d/${name}"
    echo "env: ${name}"
    grep -oP '(?<=export )\w+' "$file" | while read -r var; do
      echo "  ${var}=${!var}"
    done
  done
}

_cenv_list() {
  _cenv_files | sort
}

# -- dispatch ---------------------------------------------------------------

function cenv() {
  local cmd="$1"; shift
  case "$cmd" in
    set)    _cenv_set "$@" ;;
    print)
      [[ "$1" == "last" ]] && { _cenv_print_last; return; }
      _cenv_print ;;
    list)   _cenv_list ;;
    *)      _cenv_usage; return 1 ;;
  esac
}
export -f cenv

# -- tab completion ---------------------------------------------------------

_cenv_completions() {
  local cur prev words cword
  _get_comp_words_by_ref -n : cur prev words cword

  case $cword in
    1) COMPREPLY=($(compgen -W "set print list" -- "$cur")) ;;
    *)
      case "${words[1]}" in
        set)
          local all i name
          all=$(_cenv_files)
          for ((i=2; i<cword; i++)); do
            all=$(echo "$all" | grep -v "^${words[i]}$")
          done
          COMPREPLY=($(compgen -W "$all" -- "$cur")) ;;
        print)
          [[ $cword -eq 2 ]] && COMPREPLY=($(compgen -W "last" -- "$cur")) ;;
      esac ;;
  esac
}

complete -F _cenv_completions cenv
