#!/bin/bash

# workspace-checkout.sh - Checkout or create workspace for branch/PR based on branch name or GitHub PR ID
# Script implementation of workspace-checkout skill

set -e  # Exit on error

# Import common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/workspace-util.sh"

# Configuration
DRY_RUN=false

# Show help information
show_help() {
    cat << EOF
workspace-checkout.sh - Checkout or create workspace for branch/PR

Usage: $0 [OPTIONS] <branch-name|pr-id>

Arguments:
    branch-name|pr-id    Branch name or GitHub PR ID to checkout

Options:
    -h, --help          Show this help message
    -d, --dry-run       Preview mode, don't actually execute operations

Examples:
    $0 feature-auth                    # Checkout branch feature-auth
    $0 123                            # Checkout PR #123
    $0 -d chenyn/fix-bug              # Preview checkout operation

Note:
    Git user configuration is required (local or global):
    git config user.name "Your Name" (local)
    git config user.email "your.email@example.com" (local)
    or
    git config --global user.name "Your Name" (global)
    git config --global user.email "your.email@example.com" (global)

EOF
}

# Parse command line arguments
parse_args() {
    BRANCH_OR_PR=""

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
                if [[ -z "$BRANCH_OR_PR" ]]; then
                    BRANCH_OR_PR="$1"
                else
                    log_error "Too many arguments. Expected one branch name or PR ID."
                    exit 1
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$BRANCH_OR_PR" ]]; then
        log_error "Branch name or PR ID is required"
        show_help
        exit 1
    fi
}

# Check environment
check_environment() {
    # Use common environment check function
    check_workspace_environment "workspace-checkout"

    # Check necessary commands - GitHub CLI is required
    if ! command -v gh >/dev/null 2>&1; then
        log_error "GitHub CLI (gh) is required but not installed"
        exit 1
    fi
}

# Parse input to get valid branch name
resolve_branch_name() {
    local input="$1"
    local branch_name=""

    log_info "Resolving branch name for: $input"

    # Check if input is numeric (PR ID)
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        log_info "Input appears to be a PR ID: $input"
        # Get branch name corresponding to PR
        if ! branch_name=$(gh pr view "$input" --json headRefName -q '.headRefName' 2>/dev/null); then
            log_error "Failed to get branch name for PR #$input"
            exit 1
        fi
        log_info "PR #$input corresponds to branch: $branch_name"
    else
        # Assume it's a branch name, check if it exists
        branch_name="$input"
        if ! git ls-remote --heads origin "$branch_name" | grep -q "$branch_name"; then
            log_error "Branch '$branch_name' does not exist on remote"
            exit 1
        fi
        log_info "Branch '$branch_name' exists on remote"
    fi

    echo "$branch_name"
}

# Find existing worktree
find_existing_worktree() {
    local branch_name="$1"
    local worktree_path=""

    log_info "Looking for existing worktree for branch: $branch_name"

    # Look for existing worktree
    while IFS= read -r line; do
        if [[ "$line" =~ ^worktree ]]; then
            worktree_path=$(echo "$line" | cut -d' ' -f2-)
        elif [[ "$line" =~ ^branch ]]; then
            local existing_branch=$(echo "$line" | sed 's/^branch refs\/heads\///')
            if [[ "$existing_branch" == "$branch_name" ]]; then
                echo "$worktree_path"
                return 0
            fi
        fi
    done < <(git worktree list --porcelain)

    return 1
}

# Create new worktree
create_worktree() {
    local branch_name="$1"

    log_info "Creating new worktree for branch: $branch_name"

    # Get project information
    local origin_url=$(git remote get-url origin)
    local project_name=$(basename "$origin_url" .git)
    local project_dir=$(pwd)
    local root_dir=$(dirname "$project_dir")

    # Create safe directory name (replace / with -)
    local safe_branch_name=$(echo "$branch_name" | sed 's/\//-/g')
    local worktree_name="${project_name}-${safe_branch_name}"
    local worktree_path="${root_dir}/${worktree_name}"

    log_info "Project: $project_name"
    log_info "Root directory: $root_dir"
    log_info "Worktree path: $worktree_path"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "[DRY RUN] Would create worktree:"
        log_warning "  git worktree add \"$worktree_path\" \"origin/$branch_name\""
        echo "$worktree_path"
        return 0
    fi

    # Create worktree
    if ! git worktree add "$worktree_path" "origin/$branch_name"; then
        log_error "Failed to create worktree"
        exit 1
    fi

    log_success "Created worktree: $worktree_path"
    echo "$worktree_path"
}

# Setup worktree
setup_worktree() {
    local worktree_path="$1"
    local branch_name="$2"

    log_info "Setting up worktree: $worktree_path"

    # Get git user information (local config first, then global)
    local git_user_name=$(git config user.name)
    local git_user_email=$(git config user.email)

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "[DRY RUN] Would setup worktree:"
        log_warning "  cd \"$worktree_path\""
        log_warning "  git config user.name \"$git_user_name\""
        log_warning "  git config user.email \"$git_user_email\""
        log_warning "  git pull"
        log_warning "  Copy .claude/settings.local.json"
        execute_hook "post-checkout" "$worktree_path" "true"
        return 0
    fi

    # Switch to new worktree
    cd "$worktree_path"

    # Set git user information
    git config user.name "$git_user_name"
    git config user.email "$git_user_email"
    log_success "Set git user: $git_user_name <$git_user_email>"

    # Update code
    log_info "Updating code..."
    git pull

    # Copy Claude settings
    local main_settings="../$(basename "$(dirname "$worktree_path")")/.claude/settings.local.json"
    if [[ -f "$main_settings" ]]; then
        mkdir -p ".claude"
        cp "$main_settings" ".claude/settings.local.json"
        log_success "Copied Claude settings"
    else
        log_warning "Main worktree Claude settings not found: $main_settings"
    fi

    # Execute post-checkout hook
    execute_hook "post-checkout" "$worktree_path" "false"
}

# Main execution function
main() {
    parse_args "$@"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "=== DRY RUN MODE - No actual changes will be made ==="
    fi

    check_environment

    # Parse branch name
    local branch_name
    branch_name=$(resolve_branch_name "$BRANCH_OR_PR")

    # Look for existing worktree
    local existing_worktree
    if existing_worktree=$(find_existing_worktree "$branch_name"); then
        log_success "Found existing worktree: $existing_worktree"
        setup_worktree "$existing_worktree" "$branch_name"

        show_worktree_switch_info "$existing_worktree"
    else
        log_info "No existing worktree found, creating new one..."
        local new_worktree
        new_worktree=$(create_worktree "$branch_name")
        setup_worktree "$new_worktree" "$branch_name"

        log_success "Created and switched to new worktree"

        show_worktree_switch_info "$new_worktree"
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