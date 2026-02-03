#!/bin/bash

# workspace-clean.sh - Clean specified git worktree
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
workspace-clean.sh - Clean git worktrees safely

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

        local safety_json=$(check_worktree_safety "$path" "$branch")
        local is_safe=$(echo "$safety_json" | jq -r '.safe')

        echo "Worktree: $(basename "$path") ($branch)"

        # Display warnings
        echo "$safety_json" | jq -r '.warnings[]' 2>/dev/null | while read -r warning; do
            [[ -n "$warning" ]] && echo "⚠️  $warning"
        done

        # Display info
        echo "$safety_json" | jq -r '.info[]' 2>/dev/null | while read -r info; do
            [[ -n "$info" ]] && echo "ℹ️ $info"
        done

        if [[ "$is_safe" == "true" ]]; then
            echo "✅ Safe to clean"
        fi

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

        local safety_json=$(check_worktree_safety "$path" "$branch")
        local is_safe=$(echo "$safety_json" | jq -r '.safe')

        if [[ "$is_safe" == "true" ]]; then
            safe_worktrees+=("$worktree")
        else
            # Store JSON with worktree info for unsafe items
            unsafe_worktrees+=("$worktree|$safety_json")
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
        local safety_json=$(echo "$unsafe_entry" | cut -d'|' -f3-)

        log_warning "Skipped unsafe worktree: $(basename "$path") ($branch)"

        # Display warnings from JSON
        echo "$safety_json" | jq -r '.warnings[]' 2>/dev/null | while read -r warning; do
            [[ -n "$warning" ]] && echo "  ⚠️  $warning"
        done

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