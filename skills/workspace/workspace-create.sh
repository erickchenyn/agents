#!/bin/bash

# workspace-create.sh - Create new git worktree and branch for parallel development
# Script implementation of workspace-create skill

set -e  # Exit on error

# Import common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/workspace-util.sh"

# Configuration
BRANCH_PREFIX="${BRANCH_PREFIX:-chenyn}"
DRY_RUN=false

# Show help information
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -h, --help              Show help information
    -d, --dry-run           Only show operations to execute, don't actually run

Examples:
    $0                      # Create workspace
    $0 -d                   # Preview mode, don't actually execute

Note:
    Git user configuration is required (local or global):
    git config user.name "Your Name" (local setting)
    git config user.email "your.email@example.com" (local setting)
    or
    git config --global user.name "Your Name" (global setting)
    git config --global user.email "your.email@example.com" (global setting)
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
            *)
                log_error "Unknown argument: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Check workspace environment
check_environment() {
    # Use common environment check function
    check_workspace_environment "workspace-create"

    # Check for uncommitted changes
    if ! git diff --quiet || ! git diff --staged --quiet; then
        log_warning "Detected uncommitted changes"
        if [[ "$DRY_RUN" == false ]]; then
            read -p "Continue? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Operation cancelled"
                exit 0
            fi
        fi
    fi

    log_success "Environment check passed"
}

# Get project information
get_project_info() {
    log_info "Getting project information..."

    # Get remote repository URL
    if ! ORIGIN_URL=$(git remote get-url origin 2>/dev/null); then
        log_error "Cannot get origin remote repository URL"
        exit 1
    fi

    # Extract project name from URL
    if [[ "$ORIGIN_URL" =~ github\.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
        PROJECT_NAME="${BASH_REMATCH[2]%.git}"
    else
        log_error "Cannot parse project name from origin URL: $ORIGIN_URL"
        exit 1
    fi

    # Get project root directory (parent directory)
    CURRENT_DIR=$(pwd)
    ROOT_DIR=$(dirname "$CURRENT_DIR")

    # Generate timestamp
    TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

    # Build names
    BRANCH_NAME="${BRANCH_PREFIX}/${TIMESTAMP}"
    WORKTREE_NAME="${PROJECT_NAME}-${TIMESTAMP}"
    WORKTREE_PATH="${ROOT_DIR}/${WORKTREE_NAME}"

    log_success "Project information retrieved"
    log_info "Project name: $PROJECT_NAME"
    log_info "Worktree name: $WORKTREE_NAME"
    log_info "Branch name: $BRANCH_NAME"
    log_info "Worktree path: $WORKTREE_PATH"
}

# Check and fetch latest code
fetch_latest() {
    log_info "Checking and fetching latest origin/main..."

    if [[ "$DRY_RUN" == false ]]; then
        git fetch origin main
        log_success "Code fetch completed"
    else
        log_info "[DRY RUN] Would execute: git fetch origin main"
    fi
}

# Create worktree
create_worktree() {
    log_info "Creating new worktree and branch..."

    # Check if worktree path already exists
    if [[ -d "$WORKTREE_PATH" ]]; then
        log_error "Worktree path already exists: $WORKTREE_PATH"
        exit 1
    fi

    # Check if branch already exists
    if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
        log_error "Branch already exists: $BRANCH_NAME"
        exit 1
    fi

    if [[ "$DRY_RUN" == false ]]; then
        # Create new branch and worktree based on origin/main
        git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" origin/main
        log_success "Worktree created: $WORKTREE_PATH"
    else
        log_info "[DRY RUN] Would execute: git worktree add -b $BRANCH_NAME $WORKTREE_PATH origin/main"
    fi
}

# Initialize new workspace
initialize_workspace() {
    log_info "Initializing new workspace..."

    # Get git user information from main workspace (local config first, then global)
    local git_user_name=$(git config user.name)
    local git_user_email=$(git config user.email)

    if [[ "$DRY_RUN" == false ]]; then
        # Enter new workspace
        cd "$WORKTREE_PATH"

        # Set git user information to new workspace
        git config user.name "$git_user_name"
        git config user.email "$git_user_email"
        log_success "Git user information configured: $git_user_name <$git_user_email>"

        # Copy Claude settings
        local source_settings="${CURRENT_DIR}/.claude/settings.local.json"
        local target_settings=".claude/settings.local.json"

        if [[ -f "$source_settings" ]]; then
            mkdir -p .claude
            cp "$source_settings" "$target_settings"
            log_success "Claude settings copied"
        else
            log_warning "Claude settings file not found: $source_settings"
        fi

        # Execute post-create hook
        execute_hook "post-create" "$WORKTREE_PATH" "$CURRENT_DIR" "false"

        # Return to original directory
        cd "$CURRENT_DIR"

    else
        log_info "[DRY RUN] Would execute in new workspace:"
        log_info "[DRY RUN]   - Set git user: $git_user_name <$git_user_email>"
        log_info "[DRY RUN]   - Copy: .claude/settings.local.json"
        execute_hook "post-create" "$WORKTREE_PATH" "$CURRENT_DIR" "true"
    fi
}

# Show completion information
show_completion() {
    log_success "New workspace created successfully!"
    echo
    log_info "Workspace information:"
    log_info "  Path: $WORKTREE_PATH"
    log_info "  Branch: $BRANCH_NAME"
    echo

    # Output switch command directly, users can call with eval $(wc create ...) style
    echo "cd \"$WORKTREE_PATH\" && cc"
}

# Cleanup function (called on error)
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 && "$DRY_RUN" == false && -n "$WORKTREE_PATH" ]]; then
        log_warning "Error detected, cleaning up created workspace..."
        if [[ -d "$WORKTREE_PATH" ]]; then
            git worktree remove --force "$WORKTREE_PATH" 2>/dev/null || true
        fi
        if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
            git branch -D "$BRANCH_NAME" 2>/dev/null || true
        fi
    fi
}

# Main function
main() {
    # Set error cleanup
    trap cleanup EXIT

    parse_args "$@"

    if [[ "$DRY_RUN" == true ]]; then
        log_warning "Preview mode - no actual operations will be executed"
        echo
    fi

    check_environment
    get_project_info
    fetch_latest
    create_worktree
    initialize_workspace

    if [[ "$DRY_RUN" == false ]]; then
        show_completion
    else
        log_info "[DRY RUN] Preview completed, use $0 to actually execute operations"
    fi
}

# If script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi