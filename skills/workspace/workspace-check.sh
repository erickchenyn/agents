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
    Check all non-main worktrees and their cleanup safety status.
    Shows branch information and whether each worktree can be safely cleaned.

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

# Check worktrees and display results
check_worktrees() {
    local worktrees=()
    mapfile -t worktrees < <(get_worktrees)

    if [[ ${#worktrees[@]} -eq 0 ]]; then
        log_info "No non-main worktrees found"
        return 0
    fi

    echo
    printf "%-40s %-30s %-20s\n" "WORKTREE" "BRANCH" "STATUS"
    printf "%-40s %-30s %-20s\n" "$(printf '=%.0s' {1..40})" "$(printf '=%.0s' {1..30})" "$(printf '=%.0s' {1..20})"

    local safe_count=0
    local unsafe_count=0

    for worktree in "${worktrees[@]}"; do
        local path=$(echo "$worktree" | cut -d'|' -f1)
        local branch=$(echo "$worktree" | cut -d'|' -f2)
        local name=$(basename "$path")

        # Get safety status
        local safety_json=$(check_worktree_safety "$path" "$branch")
        local is_safe=$(echo "$safety_json" | jq -r '.safe')

        printf "%-40s %-30s " "$name" "$branch"

        if [[ "$is_safe" == "true" ]]; then
            echo "✅ Safe to clean"
            safe_count=$((safe_count + 1))
        else
            echo "⚠️  Not safe"
            unsafe_count=$((unsafe_count + 1))
        fi
    done

    echo
    echo "Summary:"
    echo "  Total worktrees: ${#worktrees[@]}"
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

    # Check workspace environment
    check_workspace_environment "workspace-check"

    # Check GitHub CLI availability for PR status
    check_gh_available

    log_info "Checking workspace worktrees..."

    check_worktrees
}

# If script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi