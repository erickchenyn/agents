#!/bin/bash

# workspace-clean.sh - Clean specified git worktree and merge its Claude configuration back to main workspace
# Script implementation of workspace-clean skill

set -e  # Exit on error

# Import common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/workspace-util.sh"

# Configuration
DRY_RUN=false

# Show help information
show_help() {
    cat << EOF
workspace-clean.sh - Clean git worktree and merge Claude settings

Usage: $0 [OPTIONS]

Options:
    -h, --help          Show this help message
    -d, --dry-run       Preview mode, don't actually execute operations

Examples:
    $0                  # Clean all safe worktrees, skip unsafe ones
    $0 -d               # Preview cleaning of all worktrees

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                log_error "Unexpected argument: $1"
                log_info "No arguments needed, script processes all worktrees automatically"
                show_help
                exit 1
                ;;
        esac
    done
}

# Check environment
check_environment() {
    # Use common environment check function
    check_workspace_environment "workspace-clean"

    # Check GitHub CLI availability
    check_gh_available
}


# Check worktree status
check_worktree_safety() {
    local worktree_path="$1"
    local branch_name="$2"
    local safety_report=""
    local is_safe=true

    log_info "Checking safety for: $worktree_path ($branch_name)"

    # Check if worktree exists
    if [[ ! -d "$worktree_path" ]]; then
        safety_report+="⚠️  Worktree directory not found\n"
        is_safe=false
        echo -e "$is_safe|$safety_report"
        return
    fi

    # Check worktree status
    if ! (cd "$worktree_path" && git diff --quiet && git diff --cached --quiet); then
        safety_report+="⚠️  Uncommitted changes detected\n"
        is_safe=false
    fi

    # Check unpushed commits
    if (cd "$worktree_path" && [[ $(git rev-list --count "@{u}"..) -gt 0 ]] 2>/dev/null); then
        safety_report+="⚠️  Unpushed commits detected\n"
        is_safe=false
    fi

    # Check PR status (if GitHub CLI available)
    if [[ "$GH_AVAILABLE" == "true" ]]; then
        local pr_status
        if pr_status=$(gh pr list --head "$branch_name" --json number,state --jq '.[0].state' 2>/dev/null) && [[ -n "$pr_status" ]]; then
            if [[ "$pr_status" == "OPEN" ]]; then
                safety_report+="⚠️  Open PR exists for this branch\n"
                is_safe=false
            elif [[ "$pr_status" == "MERGED" ]]; then
                safety_report+="✅ PR has been merged\n"
            fi
        fi
    fi

    # Check remote branch
    if git ls-remote --heads origin "$branch_name" | grep -q "$branch_name" 2>/dev/null; then
        safety_report+="ℹ️ Remote branch still exists\n"
    else
        safety_report+="✅ Remote branch has been deleted\n"
    fi

    if [[ "$is_safe" == "true" ]]; then
        safety_report="✅ Safe to clean\n$safety_report"
    fi

    echo -e "$is_safe|$safety_report"
}


# Backup and merge Claude settings
backup_claude_settings() {
    local worktree_path="$1"
    local worktree_settings="$worktree_path/.claude/settings.local.json"
    local main_settings=".claude/settings.local.json"

    if [[ ! -f "$worktree_settings" ]]; then
        return 0
    fi

    log_info "Backing up Claude settings from: $worktree_path"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "[DRY RUN] Would merge Claude settings:"
        log_warning "  From: $worktree_settings"
        log_warning "  To: $main_settings"
        return 0
    fi

    # Simple merge: copy if main settings don't exist, warn if they do exist
    if [[ ! -f "$main_settings" ]]; then
        mkdir -p "$(dirname "$main_settings")"
        cp "$worktree_settings" "$main_settings"
        log_success "Copied Claude settings to main worktree"
    else
        log_warning "Main worktree already has Claude settings, manual merge may be needed"
        log_info "Worktree settings: $worktree_settings"
        log_info "Main settings: $main_settings"
    fi
}

# Remove worktree
clean_worktree() {
    local worktree_path="$1"
    local branch_name="$2"

    log_info "Cleaning worktree: $worktree_path ($branch_name)"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "[DRY RUN] Would clean worktree:"
        log_warning "  git worktree remove \"$worktree_path\""
        return 0
    fi

    # Backup Claude settings
    backup_claude_settings "$worktree_path"

    # Remove worktree
    if git worktree remove "$worktree_path"; then
        log_success "Cleaned worktree: $worktree_path"
    else
        log_error "Failed to clean worktree: $worktree_path"
        return 1
    fi
}

# Main execution function
main() {
    parse_args "$@"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "=== DRY RUN MODE - No actual changes will be made ==="
    fi

    check_environment

    local worktrees_to_clean=()

    # Process all non-main worktrees
    mapfile -t worktrees_to_clean < <(get_worktrees)
    log_info "Processing all non-main worktrees"

    if [[ ${#worktrees_to_clean[@]} -eq 0 ]]; then
        log_warning "No worktrees selected for cleaning"
        exit 0
    fi

    # Safety checks - show status but continue with automatic filtering
    log_info "Performing safety checks..."

    for worktree in "${worktrees_to_clean[@]}"; do
        local path=$(echo "$worktree" | cut -d'|' -f1)
        local branch=$(echo "$worktree" | cut -d'|' -f2)

        local safety_result
        safety_result=$(check_worktree_safety "$path" "$branch")
        local is_safe=$(echo "$safety_result" | cut -d'|' -f1)
        local report=$(echo "$safety_result" | cut -d'|' -f2-)

        echo "Worktree: $(basename "$path") ($branch)"
        echo -e "$report"
        echo ""
    done

    # Execute cleaning - only for safe worktrees
    local success_count=0
    local skipped_count=0
    local total_count=${#worktrees_to_clean[@]}
    local safe_worktrees=()
    local unsafe_worktrees=()

    # Separate safe and unsafe worktrees
    for worktree in "${worktrees_to_clean[@]}"; do
        local path=$(echo "$worktree" | cut -d'|' -f1)
        local branch=$(echo "$worktree" | cut -d'|' -f2)

        local safety_result
        safety_result=$(check_worktree_safety "$path" "$branch")
        local is_safe=$(echo "$safety_result" | cut -d'|' -f1)
        local report=$(echo "$safety_result" | cut -d'|' -f2-)

        if [[ "$is_safe" == "true" ]]; then
            safe_worktrees+=("$worktree")
        else
            unsafe_worktrees+=("$worktree|$report")
        fi
    done

    # Clean safe worktrees
    for worktree in "${safe_worktrees[@]}"; do
        local path=$(echo "$worktree" | cut -d'|' -f1)
        local branch=$(echo "$worktree" | cut -d'|' -f2)

        if clean_worktree "$path" "$branch"; then
            success_count=$((success_count + 1))
        fi
    done

    # Report skipped unsafe worktrees
    for unsafe_entry in "${unsafe_worktrees[@]}"; do
        local worktree=$(echo "$unsafe_entry" | cut -d'|' -f1-2)
        local path=$(echo "$worktree" | cut -d'|' -f1)
        local branch=$(echo "$worktree" | cut -d'|' -f2)
        local reasons=$(echo "$unsafe_entry" | cut -d'|' -f3-)

        log_warning "Skipped unsafe worktree: $(basename "$path") ($branch)"
        echo -e "  Reasons: $reasons" | sed 's/\\n/\n  /g'
        skipped_count=$((skipped_count + 1))
    done

    # Report final results
    log_success "Cleaning completed: $success_count cleaned, $skipped_count skipped (unsafe)"

    if [[ "$skipped_count" -gt 0 ]]; then
        log_info "To clean unsafe worktrees, resolve the safety issues first:"
        log_info "- Commit or stash uncommitted changes"
        log_info "- Push unpushed commits to remote"
        log_info "- Close or merge open PRs"
    fi

    if [[ "$success_count" -gt 0 ]] || [[ "$skipped_count" -gt 0 ]]; then
        log_info "Current worktrees:"
        git worktree list
    fi
}

# Error handling
cleanup_on_error() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Operation failed with exit code $exit_code"
    fi
    exit $exit_code
}

trap cleanup_on_error ERR

# Execute main function
main "$@"