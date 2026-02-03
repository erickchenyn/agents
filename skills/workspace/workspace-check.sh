#!/bin/bash

# workspace-check.sh - Check all workspace worktrees and their safety status
# Script implementation of workspace-check skill

set -e  # Exit on error

# Import common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/workspace-util.sh"

# Show help information
show_help() {
    cat << EOF
Usage: $0

Description:
    Check all workspace worktrees and their detailed status.
    Shows comprehensive information for all worktrees including safety, modifications,
    remote branch status, PR information, and current workspace indicator.

Examples:
    $0                      # Check all worktrees
    wcheck                  # Using the wc-functions wrapper

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
            *)
                log_error "Unknown argument: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Check all worktrees and display detailed results
check_worktrees() {
    local all_worktrees=()
    local non_main_worktrees=()
    mapfile -t all_worktrees < <(get_all_worktrees)

    if [[ ${#all_worktrees[@]} -eq 0 ]]; then
        log_info "No worktrees found"
        return 0
    fi

    # Filter out main branches
    for worktree in "${all_worktrees[@]}"; do
        local branch=$(echo "$worktree" | cut -d'|' -f2)
        if [[ "$branch" != "main" ]]; then
            non_main_worktrees+=("$worktree")
        fi
    done

    # If no non-main worktrees, just show simple message
    if [[ ${#non_main_worktrees[@]} -eq 0 ]]; then
        log_info "No non-main worktrees found"
        log_info "Only main branch workspace exists"
        return 0
    fi

    echo
    # Table header with detailed columns
    printf "%-3s %-20s %-25s %-5s %-6s %-7s %-8s %-12s\n" \
        "CUR" "WORKTREE" "BRANCH" "SAFE" "CLEAN" "REMOTE" "PR" "STATUS"
    printf "%-3s %-20s %-25s %-5s %-6s %-7s %-8s %-12s\n" \
        "===" "===================" "=========================" "=====" \
        "======" "=======" "========" "============"

    local safe_count=0
    local unsafe_count=0

    for worktree in "${non_main_worktrees[@]}"; do
        local path=$(echo "$worktree" | cut -d'|' -f1)
        local branch=$(echo "$worktree" | cut -d'|' -f2)
        local is_current=$(echo "$worktree" | cut -d'|' -f3)
        local name=$(basename "$path")

        # Current worktree indicator
        local current_marker=""
        if [[ "$is_current" == "true" ]]; then
            current_marker="*"
        else
            current_marker=""
        fi

        # Check safety
        local safe_status=""
        if check_worktree_safety "$path" "$branch" >/dev/null 2>&1; then
            safe_status="Y"
            safe_count=$((safe_count + 1))
        else
            safe_status="N"
            unsafe_count=$((unsafe_count + 1))
        fi

        # Check local modifications (inverted logic - CLEAN column shows if clean)
        local clean_status=""
        if has_uncommitted_changes "$path"; then
            clean_status="N"
        else
            clean_status="Y"
        fi

        # Check remote branch
        local remote_status=""
        if remote_branch_exists "$branch"; then
            remote_status="Y"
        else
            remote_status="N"
        fi

        # Check PR status
        local pr_status=""
        local pr_number=$(get_pr_number "$branch")
        if [[ -n "$pr_number" ]]; then
            if has_open_pr "$branch"; then
                pr_status="#$pr_number"
            else
                pr_status="($pr_number)"
            fi
        else
            pr_status="-"
        fi

        # Overall status
        local overall_status=""
        if [[ "$is_current" == "true" ]]; then
            overall_status="Current"
        elif [[ "$safe_status" == "Y" ]]; then
            overall_status="Ready"
        else
            overall_status="In Use"
        fi

        # Print row
        printf "%-3s %-20s %-25s %-5s %-6s %-7s %-8s %-12s\n" \
            "$current_marker" \
            "${name:0:20}" \
            "${branch:0:25}" \
            "$safe_status" \
            "$clean_status" \
            "$remote_status" \
            "$pr_status" \
            "$overall_status"
    done

    echo
    echo "Legend:"
    echo "  CUR: * = Current workspace"
    echo "  SAFE: Y = Safe to remove, N = Not safe"
    echo "  CLEAN: Y = No changes, N = Has uncommitted changes"
    echo "  REMOTE: Y = Remote exists, N = Remote deleted"
    echo "  PR: #123 = Open PR, (123) = Merged/closed PR, - = No PR"
    echo
    echo "Summary:"
    echo "  Total worktrees: ${#non_main_worktrees[@]}"
    echo "  Safe to clean: $safe_count"
    echo "  Not safe to clean: $unsafe_count"

    if [[ $safe_count -gt 0 ]]; then
        echo
        log_info "Use 'wclean' to clean up safe worktrees"
    fi
}

# Main function
main() {
    parse_args "$@"

    # Basic git repository check (no main worktree requirement)
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_error "Not in a git repository"
        exit 1
    fi

    # Check GitHub CLI availability for PR status
    check_gh_available

    log_info "Checking all workspace worktrees..."

    check_worktrees
}

# If script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi