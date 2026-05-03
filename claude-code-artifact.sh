# claude-code-artifact.sh
# Source this file in your .bashrc to add the claude-code-artifact command to your shell

_CC_GREEN='\033[0;32m'
_CC_RED='\033[0;31m'
_CC_BLUE='\033[0;34m'
_CC_YELLOW='\033[1;33m'
_CC_NC='\033[0m'

_cca-usage() {
    echo "Usage: claude-code-artifact [options] <action> [artifact] [name|state]"
    echo ""
    echo "Options:"
    echo "  -o FORMAT        Output format for list action: 'raw' or 'json'"
    echo ""
    echo "Actions:"
    echo "  list             List artifacts (optionally filter by artifact type and state)"
    echo "  enable           Enable an artifact (move from disabled to enabled)"
    echo "  disable          Disable an artifact (move from enabled to disabled)"
    echo "  copy-to-user     Copy artifact from project to user ~/.claude/ (preserves state)"
    echo "  copy-to-project  Copy artifact from user to project .claude/ (preserves state)"
    echo "  move-to-user     Move artifact from project to user ~/.claude/ (preserves state)"
    echo "  move-to-project  Move artifact from user to project .claude/ (preserves state)"
    echo ""
    echo "Artifacts:"
    echo "  skill            Claude Code skill"
    echo "  agent            Claude Code agent"
    echo "  command          Claude Code command"
    echo "  all              All artifact types"
    echo ""
    echo "State (for list action):"
    echo "  enabled          Show only enabled artifacts"
    echo "  disabled         Show only disabled artifacts"
    echo "  any              Show both enabled and disabled artifacts"
    echo ""
    echo "Output Formats:"
    echo "  (default)        Formatted output with colors, headers, and bullets"
    echo "  raw              Plain text, one name per line"
    echo "  json             JSON array with name and state fields"
    echo ""
    echo "Examples:"
    echo "  claude-code-artifact list                           # List all artifacts (formatted)"
    echo "  claude-code-artifact list skill                     # List only skills (formatted)"
    echo "  claude-code-artifact -o raw list skill              # List only skills (raw output)"
    echo "  claude-code-artifact -o json list skill             # List only skills (JSON output)"
    echo "  claude-code-artifact list skill enabled             # List enabled skills (formatted)"
    echo "  claude-code-artifact -o raw list skill enabled      # List enabled skills (raw names)"
    echo "  claude-code-artifact -o json list agent disabled    # List disabled agents (JSON)"
    echo "  claude-code-artifact list skill any                 # List all skills (formatted)"
    echo "  claude-code-artifact disable skill verify-docs      # Disable single skill"
    echo "  claude-code-artifact disable agent all              # Disable all agents"
    echo "  claude-code-artifact disable all                    # Disable ALL artifacts"
    echo "  claude-code-artifact enable agent web-researcher    # Enable single agent"
    echo "  claude-code-artifact enable skill all               # Enable all skills"
    echo "  claude-code-artifact enable all                     # Enable ALL artifacts"
    echo "  claude-code-artifact copy-to-user agent web-researcher"
    echo "  claude-code-artifact copy-to-project command local-commit"
    echo "  claude-code-artifact move-to-user skill my-custom-skill"
    echo "  claude-code-artifact move-to-project agent api-documenter"
    return 1
}

_cca-get-artifact-dir() {
    case "$1" in
        skill)   echo "skills" ;;
        agent)   echo "agents" ;;
        command) echo "commands" ;;
    esac
}

_cca-artifact-exists() {
    local path="$1"
    if [[ -d "$path" ]] || [[ -f "$path.md" ]]; then
        return 0
    fi
    return 1
}

_cca-get-existing-path() {
    local base_path="$1"
    if [[ -d "$base_path" ]]; then
        echo "$base_path"
    elif [[ -f "$base_path.md" ]]; then
        echo "$base_path.md"
    else
        echo "$base_path"
    fi
}

_cca-action-enable() {
    if [[ "$ARTIFACT" == "all" ]]; then
        local total_count=0
        local total_failed=0

        for artifact_type in "skill" "agent" "command"; do
            local artifact_dir=$(_cca-get-artifact-dir "$artifact_type")
            local count=0
            local failed=0

            if [[ -d ".claude/${artifact_dir}-disabled" ]]; then
                mkdir -p ".claude/$artifact_dir"
                for item in .claude/${artifact_dir}-disabled/*; do
                    if [[ -e "$item" ]]; then
                        local name=$(basename "$item" .md)
                        local dst="${item/\/${artifact_dir}-disabled\//\/${artifact_dir}\/}"
                        if mv "$item" "$dst" 2>/dev/null; then
                            echo -e "${_CC_GREEN}✓ Enabled $artifact_type '$name' (project)${_CC_NC}"
                            count=$((count + 1))
                        else
                            echo -e "${_CC_RED}✗ Failed to enable $artifact_type '$name' (project)${_CC_NC}"
                            failed=$((failed + 1))
                        fi
                    fi
                done
            fi

            if [[ -d "$HOME/.claude/${artifact_dir}-disabled" ]]; then
                mkdir -p "$HOME/.claude/$artifact_dir"
                for item in $HOME/.claude/${artifact_dir}-disabled/*; do
                    if [[ -e "$item" ]]; then
                        local name=$(basename "$item" .md)
                        local dst="${item/\/${artifact_dir}-disabled\//\/${artifact_dir}\/}"
                        if mv "$item" "$dst" 2>/dev/null; then
                            echo -e "${_CC_GREEN}✓ Enabled $artifact_type '$name' (personal)${_CC_NC}"
                            count=$((count + 1))
                        else
                            echo -e "${_CC_RED}✗ Failed to enable $artifact_type '$name' (personal)${_CC_NC}"
                            failed=$((failed + 1))
                        fi
                    fi
                done
            fi

            total_count=$((total_count + count))
            total_failed=$((total_failed + failed))
        done

        if [[ $total_count -eq 0 && $total_failed -eq 0 ]]; then
            echo -e "${_CC_YELLOW}No disabled artifacts found${_CC_NC}"
        else
            echo ""
            echo -e "${_CC_BLUE}Summary: Enabled $total_count artifact(s), $total_failed failed${_CC_NC}"
        fi
        return 0
    fi

    if [[ "$NAME" == "all" ]]; then
        local count=0
        local failed=0

        if [[ -d ".claude/${ARTIFACT_DIR}-disabled" ]]; then
            mkdir -p ".claude/$ARTIFACT_DIR"
            for item in .claude/${ARTIFACT_DIR}-disabled/*; do
                if [[ -e "$item" ]]; then
                    local name=$(basename "$item" .md)
                    local dst="${item/\/${ARTIFACT_DIR}-disabled\//\/${ARTIFACT_DIR}\/}"
                    if mv "$item" "$dst" 2>/dev/null; then
                        echo -e "${_CC_GREEN}✓ Enabled $ARTIFACT '$name' (project)${_CC_NC}"
                        count=$((count + 1))
                    else
                        echo -e "${_CC_RED}✗ Failed to enable $ARTIFACT '$name' (project)${_CC_NC}"
                        failed=$((failed + 1))
                    fi
                fi
            done
        fi

        if [[ -d "$HOME/.claude/${ARTIFACT_DIR}-disabled" ]]; then
            mkdir -p "$HOME/.claude/$ARTIFACT_DIR"
            for item in $HOME/.claude/${ARTIFACT_DIR}-disabled/*; do
                if [[ -e "$item" ]]; then
                    local name=$(basename "$item" .md)
                    local dst="${item/\/${ARTIFACT_DIR}-disabled\//\/${ARTIFACT_DIR}\/}"
                    if mv "$item" "$dst" 2>/dev/null; then
                        echo -e "${_CC_GREEN}✓ Enabled $ARTIFACT '$name' (personal)${_CC_NC}"
                        count=$((count + 1))
                    else
                        echo -e "${_CC_RED}✗ Failed to enable $ARTIFACT '$name' (personal)${_CC_NC}"
                        failed=$((failed + 1))
                    fi
                fi
            done
        fi

        if [[ $count -eq 0 && $failed -eq 0 ]]; then
            echo -e "${_CC_YELLOW}No disabled ${ARTIFACT}s found${_CC_NC}"
        else
            echo ""
            echo -e "${_CC_BLUE}Summary: Enabled $count ${ARTIFACT}(s), $failed failed${_CC_NC}"
        fi
        return 0
    fi

    local project_disabled_exists=false
    local personal_disabled_exists=false

    if _cca-artifact-exists "$PROJECT_DISABLED"; then
        project_disabled_exists=true
    fi

    if _cca-artifact-exists "$PERSONAL_DISABLED"; then
        personal_disabled_exists=true
    fi

    if [[ "$project_disabled_exists" == true && "$personal_disabled_exists" == true ]]; then
        echo -e "${_CC_YELLOW}$ARTIFACT '$NAME' found in both project and personal disabled locations.${_CC_NC}"
        echo ""
        echo "Please specify which one to enable:"
        echo "  1) Project $ARTIFACT (.claude/${ARTIFACT_DIR}-disabled/$NAME)"
        echo "  2) Personal $ARTIFACT (~/.claude/${ARTIFACT_DIR}-disabled/$NAME)"
        echo ""
        read -p "Enter choice [1 or 2]: " choice
        case $choice in
            1) personal_disabled_exists=false ;;
            2) project_disabled_exists=false ;;
            *) echo -e "${_CC_RED}Invalid choice${_CC_NC}"; return 1 ;;
        esac
    fi

    if [[ "$project_disabled_exists" == true ]]; then
        mkdir -p ".claude/$ARTIFACT_DIR"
        local src=$(_cca-get-existing-path "$PROJECT_DISABLED")
        local dst="${src/\/${ARTIFACT_DIR}-disabled\//\/${ARTIFACT_DIR}\/}"
        if mv "$src" "$dst"; then
            echo -e "${_CC_GREEN}✓ $ARTIFACT '$NAME' enabled successfully (project)${_CC_NC}"
            echo -e "  Moved from: $src"
            echo -e "  Moved to:   $dst"
            return 0
        else
            echo -e "${_CC_RED}✗ Failed to enable $ARTIFACT '$NAME'${_CC_NC}"
            return 1
        fi
    elif [[ "$personal_disabled_exists" == true ]]; then
        mkdir -p "$HOME/.claude/$ARTIFACT_DIR"
        local src=$(_cca-get-existing-path "$PERSONAL_DISABLED")
        local dst="${src/\/${ARTIFACT_DIR}-disabled\//\/${ARTIFACT_DIR}\/}"
        if mv "$src" "$dst"; then
            echo -e "${_CC_GREEN}✓ $ARTIFACT '$NAME' enabled successfully (personal)${_CC_NC}"
            echo -e "  Moved from: $src"
            echo -e "  Moved to:   $dst"
            return 0
        else
            echo -e "${_CC_RED}✗ Failed to enable $ARTIFACT '$NAME'${_CC_NC}"
            return 1
        fi
    else
        if _cca-artifact-exists "$PROJECT_ACTIVE" || _cca-artifact-exists "$PERSONAL_ACTIVE"; then
            echo -e "${_CC_YELLOW}$ARTIFACT '$NAME' is already enabled${_CC_NC}"
            return 0
        else
            echo -e "${_CC_RED}✗ $ARTIFACT '$NAME' not found in disabled ${ARTIFACT_DIR}${_CC_NC}"
            return 1
        fi
    fi
}

_cca-action-disable() {
    if [[ "$ARTIFACT" == "all" ]]; then
        local total_count=0
        local total_failed=0

        for artifact_type in "skill" "agent" "command"; do
            local artifact_dir=$(_cca-get-artifact-dir "$artifact_type")
            local count=0
            local failed=0

            if [[ -d ".claude/$artifact_dir" ]]; then
                mkdir -p ".claude/${artifact_dir}-disabled"
                for item in .claude/$artifact_dir/*; do
                    if [[ -e "$item" ]]; then
                        local name=$(basename "$item" .md)
                        local dst="${item/\/${artifact_dir}\//\/${artifact_dir}-disabled\/}"
                        if mv "$item" "$dst" 2>/dev/null; then
                            echo -e "${_CC_GREEN}✓ Disabled $artifact_type '$name' (project)${_CC_NC}"
                            count=$((count + 1))
                        else
                            echo -e "${_CC_RED}✗ Failed to disable $artifact_type '$name' (project)${_CC_NC}"
                            failed=$((failed + 1))
                        fi
                    fi
                done
            fi

            if [[ -d "$HOME/.claude/$artifact_dir" ]]; then
                mkdir -p "$HOME/.claude/${artifact_dir}-disabled"
                for item in $HOME/.claude/$artifact_dir/*; do
                    if [[ -e "$item" ]]; then
                        local name=$(basename "$item" .md)
                        local dst="${item/\/${artifact_dir}\//\/${artifact_dir}-disabled\/}"
                        if mv "$item" "$dst" 2>/dev/null; then
                            echo -e "${_CC_GREEN}✓ Disabled $artifact_type '$name' (personal)${_CC_NC}"
                            count=$((count + 1))
                        else
                            echo -e "${_CC_RED}✗ Failed to disable $artifact_type '$name' (personal)${_CC_NC}"
                            failed=$((failed + 1))
                        fi
                    fi
                done
            fi

            total_count=$((total_count + count))
            total_failed=$((total_failed + failed))
        done

        if [[ $total_count -eq 0 && $total_failed -eq 0 ]]; then
            echo -e "${_CC_YELLOW}No enabled artifacts found${_CC_NC}"
        else
            echo ""
            echo -e "${_CC_BLUE}Summary: Disabled $total_count artifact(s), $total_failed failed${_CC_NC}"
        fi
        return 0
    fi

    if [[ "$NAME" == "all" ]]; then
        local count=0
        local failed=0

        if [[ -d ".claude/$ARTIFACT_DIR" ]]; then
            mkdir -p ".claude/${ARTIFACT_DIR}-disabled"
            for item in .claude/$ARTIFACT_DIR/*; do
                if [[ -e "$item" ]]; then
                    local name=$(basename "$item" .md)
                    local dst="${item/\/${ARTIFACT_DIR}\//\/${ARTIFACT_DIR}-disabled\/}"
                    if mv "$item" "$dst" 2>/dev/null; then
                        echo -e "${_CC_GREEN}✓ Disabled $ARTIFACT '$name' (project)${_CC_NC}"
                        count=$((count + 1))
                    else
                        echo -e "${_CC_RED}✗ Failed to disable $ARTIFACT '$name' (project)${_CC_NC}"
                        failed=$((failed + 1))
                    fi
                fi
            done
        fi

        if [[ -d "$HOME/.claude/$ARTIFACT_DIR" ]]; then
            mkdir -p "$HOME/.claude/${ARTIFACT_DIR}-disabled"
            for item in $HOME/.claude/$ARTIFACT_DIR/*; do
                if [[ -e "$item" ]]; then
                    local name=$(basename "$item" .md)
                    local dst="${item/\/${ARTIFACT_DIR}\//\/${ARTIFACT_DIR}-disabled\/}"
                    if mv "$item" "$dst" 2>/dev/null; then
                        echo -e "${_CC_GREEN}✓ Disabled $ARTIFACT '$name' (personal)${_CC_NC}"
                        count=$((count + 1))
                    else
                        echo -e "${_CC_RED}✗ Failed to disable $ARTIFACT '$name' (personal)${_CC_NC}"
                        failed=$((failed + 1))
                    fi
                fi
            done
        fi

        if [[ $count -eq 0 && $failed -eq 0 ]]; then
            echo -e "${_CC_YELLOW}No enabled ${ARTIFACT}s found${_CC_NC}"
        else
            echo ""
            echo -e "${_CC_BLUE}Summary: Disabled $count ${ARTIFACT}(s), $failed failed${_CC_NC}"
        fi
        return 0
    fi

    local project_active_exists=false
    local personal_active_exists=false

    if _cca-artifact-exists "$PROJECT_ACTIVE"; then
        project_active_exists=true
    fi

    if _cca-artifact-exists "$PERSONAL_ACTIVE"; then
        personal_active_exists=true
    fi

    if [[ "$project_active_exists" == true && "$personal_active_exists" == true ]]; then
        echo -e "${_CC_YELLOW}$ARTIFACT '$NAME' found in both project and personal locations.${_CC_NC}"
        echo ""
        echo "Please specify which one to disable:"
        echo "  1) Project $ARTIFACT (.claude/$ARTIFACT_DIR/$NAME)"
        echo "  2) Personal $ARTIFACT (~/.claude/$ARTIFACT_DIR/$NAME)"
        echo ""
        read -p "Enter choice [1 or 2]: " choice
        case $choice in
            1) personal_active_exists=false ;;
            2) project_active_exists=false ;;
            *) echo -e "${_CC_RED}Invalid choice${_CC_NC}"; return 1 ;;
        esac
    fi

    if [[ "$project_active_exists" == true ]]; then
        mkdir -p ".claude/${ARTIFACT_DIR}-disabled"
        local src=$(_cca-get-existing-path "$PROJECT_ACTIVE")
        local dst="${src/\/${ARTIFACT_DIR}\//\/${ARTIFACT_DIR}-disabled\/}"
        if mv "$src" "$dst"; then
            echo -e "${_CC_GREEN}✓ $ARTIFACT '$NAME' disabled successfully (project)${_CC_NC}"
            echo -e "  Moved from: $src"
            echo -e "  Moved to:   $dst"
            return 0
        else
            echo -e "${_CC_RED}✗ Failed to disable $ARTIFACT '$NAME'${_CC_NC}"
            return 1
        fi
    elif [[ "$personal_active_exists" == true ]]; then
        mkdir -p "$HOME/.claude/${ARTIFACT_DIR}-disabled"
        local src=$(_cca-get-existing-path "$PERSONAL_ACTIVE")
        local dst="${src/\/${ARTIFACT_DIR}\//\/${ARTIFACT_DIR}-disabled\/}"
        if mv "$src" "$dst"; then
            echo -e "${_CC_GREEN}✓ $ARTIFACT '$NAME' disabled successfully (personal)${_CC_NC}"
            echo -e "  Moved from: $src"
            echo -e "  Moved to:   $dst"
            return 0
        else
            echo -e "${_CC_RED}✗ Failed to disable $ARTIFACT '$NAME'${_CC_NC}"
            return 1
        fi
    else
        if _cca-artifact-exists "$PROJECT_DISABLED" || _cca-artifact-exists "$PERSONAL_DISABLED"; then
            echo -e "${_CC_YELLOW}$ARTIFACT '$NAME' is already disabled${_CC_NC}"
            return 0
        else
            echo -e "${_CC_RED}✗ $ARTIFACT '$NAME' not found${_CC_NC}"
            return 1
        fi
    fi
}

_cca-action-copy-to-user() {
    local project_active_exists=false
    local project_disabled_exists=false
    local is_disabled=false

    if _cca-artifact-exists "$PROJECT_ACTIVE"; then
        project_active_exists=true
    fi

    if _cca-artifact-exists "$PROJECT_DISABLED"; then
        project_disabled_exists=true
        is_disabled=true
    fi

    if [[ "$project_active_exists" == true && "$project_disabled_exists" == true ]]; then
        echo -e "${_CC_YELLOW}$ARTIFACT '$NAME' found in both enabled and disabled project locations.${_CC_NC}"
        echo ""
        echo "Please specify which one to copy:"
        echo "  1) Enabled (.claude/$ARTIFACT_DIR/$NAME)"
        echo "  2) Disabled (.claude/${ARTIFACT_DIR}-disabled/$NAME)"
        echo ""
        read -p "Enter choice [1 or 2]: " choice
        case $choice in
            1) project_disabled_exists=false; is_disabled=false ;;
            2) project_active_exists=false; is_disabled=true ;;
            *) echo -e "${_CC_RED}Invalid choice${_CC_NC}"; return 1 ;;
        esac
    fi

    if [[ "$project_active_exists" == true ]]; then
        local src=$(_cca-get-existing-path "$PROJECT_ACTIVE")
        local target_dir="$HOME/.claude/$ARTIFACT_DIR"
        local target_path="$PERSONAL_ACTIVE"
        mkdir -p "$target_dir"

        if _cca-artifact-exists "$target_path"; then
            echo -e "${_CC_YELLOW}$ARTIFACT '$NAME' already exists in personal ~/.claude/$ARTIFACT_DIR/${_CC_NC}"
            read -p "Overwrite? [y/N]: " confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                echo -e "${_CC_BLUE}Operation cancelled${_CC_NC}"
                return 0
            fi
            local dst=$(_cca-get-existing-path "$target_path")
            rm -rf "$dst"
        fi

        local dst="$target_dir/$(basename "$src")"
        if cp -r "$src" "$dst"; then
            echo -e "${_CC_GREEN}✓ $ARTIFACT '$NAME' copied to user successfully (enabled)${_CC_NC}"
            echo -e "  Copied from: $src"
            echo -e "  Copied to:   $dst"
            return 0
        else
            echo -e "${_CC_RED}✗ Failed to copy $ARTIFACT '$NAME'${_CC_NC}"
            return 1
        fi

    elif [[ "$project_disabled_exists" == true ]]; then
        local src=$(_cca-get-existing-path "$PROJECT_DISABLED")
        local target_dir="$HOME/.claude/${ARTIFACT_DIR}-disabled"
        local target_path="$PERSONAL_DISABLED"
        mkdir -p "$target_dir"

        if _cca-artifact-exists "$target_path"; then
            echo -e "${_CC_YELLOW}$ARTIFACT '$NAME' already exists in personal ~/.claude/${ARTIFACT_DIR}-disabled/${_CC_NC}"
            read -p "Overwrite? [y/N]: " confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                echo -e "${_CC_BLUE}Operation cancelled${_CC_NC}"
                return 0
            fi
            local dst=$(_cca-get-existing-path "$target_path")
            rm -rf "$dst"
        fi

        local dst="$target_dir/$(basename "$src")"
        if cp -r "$src" "$dst"; then
            echo -e "${_CC_GREEN}✓ $ARTIFACT '$NAME' copied to user successfully (disabled)${_CC_NC}"
            echo -e "  Copied from: $src"
            echo -e "  Copied to:   $dst"
            return 0
        else
            echo -e "${_CC_RED}✗ Failed to copy $ARTIFACT '$NAME'${_CC_NC}"
            return 1
        fi

    else
        echo -e "${_CC_RED}✗ $ARTIFACT '$NAME' not found in project${_CC_NC}"
        return 1
    fi
}

_cca-action-copy-to-project() {
    local personal_active_exists=false
    local personal_disabled_exists=false
    local is_disabled=false

    if _cca-artifact-exists "$PERSONAL_ACTIVE"; then
        personal_active_exists=true
    fi

    if _cca-artifact-exists "$PERSONAL_DISABLED"; then
        personal_disabled_exists=true
        is_disabled=true
    fi

    if [[ "$personal_active_exists" == true && "$personal_disabled_exists" == true ]]; then
        echo -e "${_CC_YELLOW}$ARTIFACT '$NAME' found in both enabled and disabled personal locations.${_CC_NC}"
        echo ""
        echo "Please specify which one to copy:"
        echo "  1) Enabled (~/.claude/$ARTIFACT_DIR/$NAME)"
        echo "  2) Disabled (~/.claude/${ARTIFACT_DIR}-disabled/$NAME)"
        echo ""
        read -p "Enter choice [1 or 2]: " choice
        case $choice in
            1) personal_disabled_exists=false; is_disabled=false ;;
            2) personal_active_exists=false; is_disabled=true ;;
            *) echo -e "${_CC_RED}Invalid choice${_CC_NC}"; return 1 ;;
        esac
    fi

    if [[ "$personal_active_exists" == true ]]; then
        local src=$(_cca-get-existing-path "$PERSONAL_ACTIVE")
        local target_dir=".claude/$ARTIFACT_DIR"
        local target_path="$PROJECT_ACTIVE"
        mkdir -p "$target_dir"

        if _cca-artifact-exists "$target_path"; then
            echo -e "${_CC_YELLOW}$ARTIFACT '$NAME' already exists in project .claude/$ARTIFACT_DIR/${_CC_NC}"
            read -p "Overwrite? [y/N]: " confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                echo -e "${_CC_BLUE}Operation cancelled${_CC_NC}"
                return 0
            fi
            local dst=$(_cca-get-existing-path "$target_path")
            rm -rf "$dst"
        fi

        local dst="$target_dir/$(basename "$src")"
        if cp -r "$src" "$dst"; then
            echo -e "${_CC_GREEN}✓ $ARTIFACT '$NAME' copied to project successfully (enabled)${_CC_NC}"
            echo -e "  Copied from: $src"
            echo -e "  Copied to:   $dst"
            return 0
        else
            echo -e "${_CC_RED}✗ Failed to copy $ARTIFACT '$NAME'${_CC_NC}"
            return 1
        fi

    elif [[ "$personal_disabled_exists" == true ]]; then
        local src=$(_cca-get-existing-path "$PERSONAL_DISABLED")
        local target_dir=".claude/${ARTIFACT_DIR}-disabled"
        local target_path="$PROJECT_DISABLED"
        mkdir -p "$target_dir"

        if _cca-artifact-exists "$target_path"; then
            echo -e "${_CC_YELLOW}$ARTIFACT '$NAME' already exists in project .claude/${ARTIFACT_DIR}-disabled/${_CC_NC}"
            read -p "Overwrite? [y/N]: " confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                echo -e "${_CC_BLUE}Operation cancelled${_CC_NC}"
                return 0
            fi
            local dst=$(_cca-get-existing-path "$target_path")
            rm -rf "$dst"
        fi

        local dst="$target_dir/$(basename "$src")"
        if cp -r "$src" "$dst"; then
            echo -e "${_CC_GREEN}✓ $ARTIFACT '$NAME' copied to project successfully (disabled)${_CC_NC}"
            echo -e "  Copied from: $src"
            echo -e "  Copied to:   $dst"
            return 0
        else
            echo -e "${_CC_RED}✗ Failed to copy $ARTIFACT '$NAME'${_CC_NC}"
            return 1
        fi

    else
        echo -e "${_CC_RED}✗ $ARTIFACT '$NAME' not found in personal${_CC_NC}"
        return 1
    fi
}

_cca-action-move-to-user() {
    local project_active_exists=false
    local project_disabled_exists=false
    local is_disabled=false

    if _cca-artifact-exists "$PROJECT_ACTIVE"; then
        project_active_exists=true
    fi

    if _cca-artifact-exists "$PROJECT_DISABLED"; then
        project_disabled_exists=true
        is_disabled=true
    fi

    if [[ "$project_active_exists" == true && "$project_disabled_exists" == true ]]; then
        echo -e "${_CC_YELLOW}$ARTIFACT '$NAME' found in both enabled and disabled project locations.${_CC_NC}"
        echo ""
        echo "Please specify which one to move:"
        echo "  1) Enabled (.claude/$ARTIFACT_DIR/$NAME)"
        echo "  2) Disabled (.claude/${ARTIFACT_DIR}-disabled/$NAME)"
        echo ""
        read -p "Enter choice [1 or 2]: " choice
        case $choice in
            1) project_disabled_exists=false; is_disabled=false ;;
            2) project_active_exists=false; is_disabled=true ;;
            *) echo -e "${_CC_RED}Invalid choice${_CC_NC}"; return 1 ;;
        esac
    fi

    if [[ "$project_active_exists" == true ]]; then
        local src=$(_cca-get-existing-path "$PROJECT_ACTIVE")
        local target_dir="$HOME/.claude/$ARTIFACT_DIR"
        local target_path="$PERSONAL_ACTIVE"
        mkdir -p "$target_dir"

        if _cca-artifact-exists "$target_path"; then
            echo -e "${_CC_YELLOW}$ARTIFACT '$NAME' already exists in personal ~/.claude/$ARTIFACT_DIR/${_CC_NC}"
            read -p "Overwrite and remove from project? [y/N]: " confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                echo -e "${_CC_BLUE}Operation cancelled${_CC_NC}"
                return 0
            fi
            local dst=$(_cca-get-existing-path "$target_path")
            rm -rf "$dst"
        fi

        local dst="$target_dir/$(basename "$src")"
        if mv "$src" "$dst"; then
            echo -e "${_CC_GREEN}✓ $ARTIFACT '$NAME' moved to user successfully (enabled)${_CC_NC}"
            echo -e "  Moved from: $src"
            echo -e "  Moved to:   $dst"
            return 0
        else
            echo -e "${_CC_RED}✗ Failed to move $ARTIFACT '$NAME'${_CC_NC}"
            return 1
        fi

    elif [[ "$project_disabled_exists" == true ]]; then
        local src=$(_cca-get-existing-path "$PROJECT_DISABLED")
        local target_dir="$HOME/.claude/${ARTIFACT_DIR}-disabled"
        local target_path="$PERSONAL_DISABLED"
        mkdir -p "$target_dir"

        if _cca-artifact-exists "$target_path"; then
            echo -e "${_CC_YELLOW}$ARTIFACT '$NAME' already exists in personal ~/.claude/${ARTIFACT_DIR}-disabled/${_CC_NC}"
            read -p "Overwrite and remove from project? [y/N]: " confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                echo -e "${_CC_BLUE}Operation cancelled${_CC_NC}"
                return 0
            fi
            local dst=$(_cca-get-existing-path "$target_path")
            rm -rf "$dst"
        fi

        local dst="$target_dir/$(basename "$src")"
        if mv "$src" "$dst"; then
            echo -e "${_CC_GREEN}✓ $ARTIFACT '$NAME' moved to user successfully (disabled)${_CC_NC}"
            echo -e "  Moved from: $src"
            echo -e "  Moved to:   $dst"
            return 0
        else
            echo -e "${_CC_RED}✗ Failed to move $ARTIFACT '$NAME'${_CC_NC}"
            return 1
        fi

    else
        echo -e "${_CC_RED}✗ $ARTIFACT '$NAME' not found in project${_CC_NC}"
        return 1
    fi
}

_cca-action-move-to-project() {
    local personal_active_exists=false
    local personal_disabled_exists=false
    local is_disabled=false

    if _cca-artifact-exists "$PERSONAL_ACTIVE"; then
        personal_active_exists=true
    fi

    if _cca-artifact-exists "$PERSONAL_DISABLED"; then
        personal_disabled_exists=true
        is_disabled=true
    fi

    if [[ "$personal_active_exists" == true && "$personal_disabled_exists" == true ]]; then
        echo -e "${_CC_YELLOW}$ARTIFACT '$NAME' found in both enabled and disabled personal locations.${_CC_NC}"
        echo ""
        echo "Please specify which one to move:"
        echo "  1) Enabled (~/.claude/$ARTIFACT_DIR/$NAME)"
        echo "  2) Disabled (~/.claude/${ARTIFACT_DIR}-disabled/$NAME)"
        echo ""
        read -p "Enter choice [1 or 2]: " choice
        case $choice in
            1) personal_disabled_exists=false; is_disabled=false ;;
            2) personal_active_exists=false; is_disabled=true ;;
            *) echo -e "${_CC_RED}Invalid choice${_CC_NC}"; return 1 ;;
        esac
    fi

    if [[ "$personal_active_exists" == true ]]; then
        local src=$(_cca-get-existing-path "$PERSONAL_ACTIVE")
        local target_dir=".claude/$ARTIFACT_DIR"
        local target_path="$PROJECT_ACTIVE"
        mkdir -p "$target_dir"

        if _cca-artifact-exists "$target_path"; then
            echo -e "${_CC_YELLOW}$ARTIFACT '$NAME' already exists in project .claude/$ARTIFACT_DIR/${_CC_NC}"
            read -p "Overwrite and remove from personal? [y/N]: " confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                echo -e "${_CC_BLUE}Operation cancelled${_CC_NC}"
                return 0
            fi
            local dst=$(_cca-get-existing-path "$target_path")
            rm -rf "$dst"
        fi

        local dst="$target_dir/$(basename "$src")"
        if mv "$src" "$dst"; then
            echo -e "${_CC_GREEN}✓ $ARTIFACT '$NAME' moved to project successfully (enabled)${_CC_NC}"
            echo -e "  Moved from: $src"
            echo -e "  Moved to:   $dst"
            return 0
        else
            echo -e "${_CC_RED}✗ Failed to move $ARTIFACT '$NAME'${_CC_NC}"
            return 1
        fi

    elif [[ "$personal_disabled_exists" == true ]]; then
        local src=$(_cca-get-existing-path "$PERSONAL_DISABLED")
        local target_dir=".claude/${ARTIFACT_DIR}-disabled"
        local target_path="$PROJECT_DISABLED"
        mkdir -p "$target_dir"

        if _cca-artifact-exists "$target_path"; then
            echo -e "${_CC_YELLOW}$ARTIFACT '$NAME' already exists in project .claude/${ARTIFACT_DIR}-disabled/${_CC_NC}"
            read -p "Overwrite and remove from personal? [y/N]: " confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                echo -e "${_CC_BLUE}Operation cancelled${_CC_NC}"
                return 0
            fi
            local dst=$(_cca-get-existing-path "$target_path")
            rm -rf "$dst"
        fi

        local dst="$target_dir/$(basename "$src")"
        if mv "$src" "$dst"; then
            echo -e "${_CC_GREEN}✓ $ARTIFACT '$NAME' moved to project successfully (disabled)${_CC_NC}"
            echo -e "  Moved from: $src"
            echo -e "  Moved to:   $dst"
            return 0
        else
            echo -e "${_CC_RED}✗ Failed to move $ARTIFACT '$NAME'${_CC_NC}"
            return 1
        fi

    else
        echo -e "${_CC_RED}✗ $ARTIFACT '$NAME' not found in personal${_CC_NC}"
        return 1
    fi
}

_cca-action-list() {
    local artifact_types=()

    if [[ "$ARTIFACT" == "all" ]]; then
        artifact_types=("skill" "agent" "command")
    else
        artifact_types=("$ARTIFACT")
    fi

    if [[ "$OUTPUT_FORMAT" != "formatted" && -z "$STATE" ]]; then
        STATE="any"
    fi

    if [[ "$OUTPUT_FORMAT" == "raw" ]]; then
        for type in "${artifact_types[@]}"; do
            local dir=$(_cca-get-artifact-dir "$type")

            if [[ "$STATE" == "enabled" || "$STATE" == "any" ]]; then
                if [[ -d ".claude/$dir" ]]; then
                    for item in .claude/$dir/*; do
                        if [[ -e "$item" ]]; then
                            basename "$item" .md
                        fi
                    done 2>/dev/null
                fi

                if [[ -d "$HOME/.claude/$dir" ]]; then
                    for item in $HOME/.claude/$dir/*; do
                        if [[ -e "$item" ]]; then
                            basename "$item" .md
                        fi
                    done 2>/dev/null
                fi
            fi

            if [[ "$STATE" == "disabled" || "$STATE" == "any" ]]; then
                if [[ -d ".claude/${dir}-disabled" ]]; then
                    for item in .claude/${dir}-disabled/*; do
                        if [[ -e "$item" ]]; then
                            basename "$item" .md
                        fi
                    done 2>/dev/null
                fi

                if [[ -d "$HOME/.claude/${dir}-disabled" ]]; then
                    for item in $HOME/.claude/${dir}-disabled/*; do
                        if [[ -e "$item" ]]; then
                            basename "$item" .md
                        fi
                    done 2>/dev/null
                fi
            fi
        done
        return 0
    fi

    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        echo -n "{"
        local first_type=true

        for type in "${artifact_types[@]}"; do
            local dir=$(_cca-get-artifact-dir "$type")
            local type_items=()

            if [[ "$STATE" == "enabled" || "$STATE" == "any" ]]; then
                if [[ -d ".claude/$dir" ]]; then
                    for item in .claude/$dir/*; do
                        if [[ -e "$item" ]]; then
                            local name=$(basename "$item" .md)
                            type_items+=("{\"name\":\"$name\",\"state\":\"enabled\"}")
                        fi
                    done 2>/dev/null
                fi

                if [[ -d "$HOME/.claude/$dir" ]]; then
                    for item in $HOME/.claude/$dir/*; do
                        if [[ -e "$item" ]]; then
                            local name=$(basename "$item" .md)
                            type_items+=("{\"name\":\"$name\",\"state\":\"enabled\"}")
                        fi
                    done 2>/dev/null
                fi
            fi

            if [[ "$STATE" == "disabled" || "$STATE" == "any" ]]; then
                if [[ -d ".claude/${dir}-disabled" ]]; then
                    for item in .claude/${dir}-disabled/*; do
                        if [[ -e "$item" ]]; then
                            local name=$(basename "$item" .md)
                            type_items+=("{\"name\":\"$name\",\"state\":\"disabled\"}")
                        fi
                    done 2>/dev/null
                fi

                if [[ -d "$HOME/.claude/${dir}-disabled" ]]; then
                    for item in $HOME/.claude/${dir}-disabled/*; do
                        if [[ -e "$item" ]]; then
                            local name=$(basename "$item" .md)
                            type_items+=("{\"name\":\"$name\",\"state\":\"disabled\"}")
                        fi
                    done 2>/dev/null
                fi
            fi

            if [[ ${#type_items[@]} -gt 0 ]]; then
                if [[ "$first_type" == true ]]; then
                    first_type=false
                else
                    echo -n ","
                fi

                echo -n "\"$type\":["
                local first_item=true
                for item in "${type_items[@]}"; do
                    if [[ "$first_item" == true ]]; then
                        first_item=false
                    else
                        echo -n ","
                    fi
                    echo -n "$item"
                done
                echo -n "]"
            fi
        done

        echo "}"
        return 0
    fi

    local found_any=false

    for type in "${artifact_types[@]}"; do
        local dir=$(_cca-get-artifact-dir "$type")
        local has_items=false

        if [[ -d ".claude/$dir" ]] && [[ -n "$(ls -A .claude/$dir 2>/dev/null)" ]]; then
            if [[ "$has_items" == false ]]; then
                echo -e "${_CC_BLUE}=== ${type^}s ===${_CC_NC}"
                has_items=true
                found_any=true
            fi
            echo -e "${_CC_GREEN}Project (enabled):${_CC_NC}"
            for item in .claude/$dir/*; do
                if [[ -e "$item" ]]; then
                    local name=$(basename "$item" .md)
                    echo "  • $name"
                fi
            done
        fi

        if [[ -d ".claude/${dir}-disabled" ]] && [[ -n "$(ls -A .claude/${dir}-disabled 2>/dev/null)" ]]; then
            if [[ "$has_items" == false ]]; then
                echo -e "${_CC_BLUE}=== ${type^}s ===${_CC_NC}"
                has_items=true
                found_any=true
            fi
            echo -e "${_CC_YELLOW}Project (disabled):${_CC_NC}"
            for item in .claude/${dir}-disabled/*; do
                if [[ -e "$item" ]]; then
                    local name=$(basename "$item" .md)
                    echo "  • $name"
                fi
            done
        fi

        if [[ -d "$HOME/.claude/$dir" ]] && [[ -n "$(ls -A $HOME/.claude/$dir 2>/dev/null)" ]]; then
            if [[ "$has_items" == false ]]; then
                echo -e "${_CC_BLUE}=== ${type^}s ===${_CC_NC}"
                has_items=true
                found_any=true
            fi
            echo -e "${_CC_GREEN}Personal (enabled):${_CC_NC}"
            for item in $HOME/.claude/$dir/*; do
                if [[ -e "$item" ]]; then
                    local name=$(basename "$item" .md)
                    echo "  • $name"
                fi
            done
        fi

        if [[ -d "$HOME/.claude/${dir}-disabled" ]] && [[ -n "$(ls -A $HOME/.claude/${dir}-disabled 2>/dev/null)" ]]; then
            if [[ "$has_items" == false ]]; then
                echo -e "${_CC_BLUE}=== ${type^}s ===${_CC_NC}"
                has_items=true
                found_any=true
            fi
            echo -e "${_CC_YELLOW}Personal (disabled):${_CC_NC}"
            for item in $HOME/.claude/${dir}-disabled/*; do
                if [[ -e "$item" ]]; then
                    local name=$(basename "$item" .md)
                    echo "  • $name"
                fi
            done
        fi

        if [[ "$has_items" == true ]]; then
            echo ""
        fi
    done

    if [[ "$found_any" == false ]]; then
        echo -e "${_CC_YELLOW}No artifacts found${_CC_NC}"
    fi
}

claude-code-artifact() {
    if [[ $# -lt 1 ]]; then
        echo -e "${_CC_RED}Error: Missing required arguments${_CC_NC}"
        echo ""
        _cca-usage
        return 1
    fi

    local ACTION=""
    local ARTIFACT=""
    local NAME=""
    local ARTIFACT_DIR=""
    local PROJECT_ACTIVE=""
    local PROJECT_DISABLED=""
    local PERSONAL_ACTIVE=""
    local PERSONAL_DISABLED=""
    local OUTPUT_FORMAT="formatted"
    local STATE=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -o)
                shift
                if [[ $# -eq 0 ]]; then
                    echo -e "${_CC_RED}Error: -o requires an argument (raw or json)${_CC_NC}"
                    return 1
                fi
                case "$1" in
                    raw|json)
                        OUTPUT_FORMAT="$1"
                        shift
                        ;;
                    *)
                        echo -e "${_CC_RED}Error: Invalid output format '$1'. Must be 'raw' or 'json'${_CC_NC}"
                        return 1
                        ;;
                esac
                ;;
            list|enable|disable|copy-to-user|copy-to-project|move-to-user|move-to-project)
                ACTION="$1"
                shift
                break
                ;;
            *)
                echo -e "${_CC_RED}Error: Invalid option or action '$1'${_CC_NC}"
                echo ""
                _cca-usage
                return 1
                ;;
        esac
    done

    if [[ -z "${ACTION:-}" ]]; then
        echo -e "${_CC_RED}Error: No action specified${_CC_NC}"
        echo ""
        _cca-usage
        return 1
    fi

    if [[ "$ACTION" == "list" ]]; then
        ARTIFACT="${1:-all}"
        STATE="${2:-}"

        case "$ARTIFACT" in
            skill|agent|command|all)
                ;;
            *)
                echo -e "${_CC_RED}Error: Invalid artifact type '$ARTIFACT' for list action${_CC_NC}"
                echo -e "${_CC_YELLOW}Valid options: skill, agent, command, all (default)${_CC_NC}"
                return 1
                ;;
        esac

        if [[ -n "$STATE" ]]; then
            case "$STATE" in
                enabled|disabled|any)
                    ;;
                *)
                    echo -e "${_CC_RED}Error: Invalid state '$STATE' for list action${_CC_NC}"
                    echo -e "${_CC_YELLOW}Valid options: enabled, disabled, any${_CC_NC}"
                    return 1
                    ;;
            esac
        fi
    else
        if [[ "$ACTION" == "enable" || "$ACTION" == "disable" ]] && [[ $# -eq 1 ]] && [[ "$1" == "all" ]]; then
            ARTIFACT="all"
            NAME="all"
        elif [[ $# -lt 2 ]]; then
            echo -e "${_CC_RED}Error: Missing required arguments for $ACTION action${_CC_NC}"
            echo ""
            _cca-usage
            return 1
        else
            ARTIFACT="$1"
            NAME="$2"
        fi

        case "$ARTIFACT" in
            skill|agent|command|all)
                ;;
            *)
                echo -e "${_CC_RED}Error: Invalid artifact type '$ARTIFACT'${_CC_NC}"
                echo ""
                _cca-usage
                return 1
                ;;
        esac

        if [[ "$ARTIFACT" == "all" ]] && [[ "$ACTION" != "enable" && "$ACTION" != "disable" ]]; then
            echo -e "${_CC_RED}Error: 'all' artifact type can only be used with enable/disable actions${_CC_NC}"
            echo ""
            _cca-usage
            return 1
        fi
    fi

    if [[ "$ACTION" != "list" ]]; then
        ARTIFACT_DIR=$(_cca-get-artifact-dir "$ARTIFACT")
        PROJECT_ACTIVE=".claude/$ARTIFACT_DIR/$NAME"
        PROJECT_DISABLED=".claude/${ARTIFACT_DIR}-disabled/$NAME"
        PERSONAL_ACTIVE="$HOME/.claude/$ARTIFACT_DIR/$NAME"
        PERSONAL_DISABLED="$HOME/.claude/${ARTIFACT_DIR}-disabled/$NAME"
    fi

    case "$ACTION" in
        list)           _cca-action-list ;;
        enable)         _cca-action-enable ;;
        disable)        _cca-action-disable ;;
        copy-to-user)   _cca-action-copy-to-user ;;
        copy-to-project) _cca-action-copy-to-project ;;
        move-to-user)   _cca-action-move-to-user ;;
        move-to-project) _cca-action-move-to-project ;;
    esac
}
