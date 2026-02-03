#!/bin/bash

# workspace-util.sh - Common workspace environment checks and utility functions
# Shared by all workspace scripts

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check git user configuration
check_git_config() {
    log_info "Checking git user configuration..."

    # Check local and global configurations separately
    local git_user_name_local=$(git config --local user.name 2>/dev/null || echo "")
    local git_user_email_local=$(git config --local user.email 2>/dev/null || echo "")
    local git_user_name_global=$(git config --global user.name 2>/dev/null || echo "")
    local git_user_email_global=$(git config --global user.email 2>/dev/null || echo "")

    # Determine final configuration to use (local takes precedence, git config default behavior)
    local git_user_name=$(git config user.name 2>/dev/null || echo "")
    local git_user_email=$(git config user.email 2>/dev/null || echo "")

    # Determine configuration source
    local config_source="unknown"
    local name_is_local=false
    local email_is_local=false

    if [[ -n "$git_user_name_local" ]]; then
        name_is_local=true
    fi

    if [[ -n "$git_user_email_local" ]]; then
        email_is_local=true
    fi

    if [[ "$name_is_local" == true && "$email_is_local" == true ]]; then
        config_source="local"
    elif [[ "$name_is_local" == false && "$email_is_local" == false ]]; then
        config_source="global"
    else
        config_source="mixed (local + global)"
    fi

    if [[ -z "$git_user_name" ]]; then
        log_error "Git user.name is not set"
        log_error "Please set it using one of these commands:"
        log_error "  Local setting: git config user.name \"Your Name\""
        log_error "  Global setting: git config --global user.name \"Your Name\""
        exit 1
    fi

    if [[ -z "$git_user_email" ]]; then
        log_error "Git user.email is not set"
        log_error "Please set it using one of these commands:"
        log_error "  Local setting: git config user.email \"your.email@example.com\""
        log_error "  Global setting: git config --global user.email \"your.email@example.com\""
        exit 1
    fi

    log_success "Git user configuration check passed ($config_source): $git_user_name <$git_user_email>"
}

# Check basic environment
check_workspace_environment() {
    local script_name="${1:-workspace script}"

    log_info "Checking workspace environment..."

    # Check if in git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Current directory is not a git repository"
        exit 1
    fi

    # Check if in main worktree
    local current_dir=$(pwd)
    local main_worktree=$(git worktree list --porcelain | grep "^worktree " | head -1 | cut -d' ' -f2-)

    if [[ "$current_dir" != "$main_worktree" ]]; then
        log_error "Not currently in main worktree"
        log_error "Main worktree: $main_worktree"
        log_error "Current directory: $current_dir"
        log_error "Please switch to main worktree and run again"
        exit 1
    fi

    # Check git user configuration
    check_git_config

    log_success "Environment check passed"
}

# Get project information
get_project_info() {
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

    # Get project root directory
    PROJECT_DIR=$(pwd)
    ROOT_DIR=$(dirname "$PROJECT_DIR")

    log_info "Project name: $PROJECT_NAME"
    log_info "Project directory: $PROJECT_DIR"
    log_info "Root directory: $ROOT_DIR"
}

# Get all non-main worktrees
get_worktrees() {
    local worktrees=()
    local current_worktree=""
    local current_branch=""

    while IFS= read -r line; do
        if [[ "$line" =~ ^worktree ]]; then
            current_worktree=$(echo "$line" | cut -d' ' -f2-)
        elif [[ "$line" =~ ^branch ]]; then
            current_branch=$(echo "$line" | sed 's/^branch refs\/heads\///')
        elif [[ "$line" =~ ^bare ]] || [[ -z "$line" ]]; then
            # Skip bare repository or empty line
            if [[ ! "$line" =~ ^bare ]] && [[ -n "$current_worktree" ]] && [[ -n "$current_branch" ]]; then
                # Skip main worktree (current directory)
                if [[ "$current_worktree" != "$(pwd)" ]]; then
                    worktrees+=("$current_worktree|$current_branch")
                fi
            fi
            current_worktree=""
            current_branch=""
        fi
    done < <(git worktree list --porcelain)

    printf '%s\n' "${worktrees[@]}"
}

# Check if necessary commands are available
check_gh_available() {
    if command -v gh >/dev/null 2>&1; then
        export GH_AVAILABLE=true
        log_info "GitHub CLI is available"
    else
        export GH_AVAILABLE=false
        log_warning "GitHub CLI is not available, some features will be limited"
    fi
}

# Safe branch name conversion (replace / with -)
safe_branch_name() {
    local branch_name="$1"
    echo "$branch_name" | sed 's/\//-/g'
}

# Check if worktree is clean
is_worktree_clean() {
    local worktree_path="$1"

    if [[ ! -d "$worktree_path" ]]; then
        return 1
    fi

    # Switch to worktree and check status
    (cd "$worktree_path" && git diff --quiet && git diff --cached --quiet)
}

# Check if there are unpushed commits
has_unpushed_commits() {
    local worktree_path="$1"

    if [[ ! -d "$worktree_path" ]]; then
        return 1
    fi

    # Switch to worktree and check unpushed commits
    local unpushed_count
    unpushed_count=$(cd "$worktree_path" && git rev-list --count "@{u}".. 2>/dev/null || echo "0")
    [[ "$unpushed_count" -gt 0 ]]
}

# Output worktree switch command
show_worktree_switch_info() {
    local worktree_path="$1"

    # Output switch command directly, users can call with eval $(wc ...) style
    echo "cd \"$worktree_path\" && cc"
}

# Execute project hook if it exists
execute_hook() {
    local hook_name="$1"
    local worktree_path="$2"
    local dry_run="${3:-false}"

    # Get main worktree directory (where we're currently running from)
    local main_worktree=$(pwd)
    local hook_script="$main_worktree/.workspace-config/$hook_name.sh"

    # Check if hook script exists and is executable
    if [[ ! -f "$hook_script" ]]; then
        log_info "No $hook_name hook found (.workspace-config/$hook_name.sh)"
        return 0
    fi

    if [[ ! -x "$hook_script" ]]; then
        log_warning "Hook script exists but is not executable: $hook_script"
        log_info "Run: chmod +x $hook_script"
        return 0
    fi

    log_info "Executing $hook_name hook..."

    if [[ "$dry_run" == "true" ]]; then
        log_warning "[DRY RUN] Would execute hook: $hook_script"
        log_warning "[DRY RUN] Working directory: $worktree_path"
        return 0
    fi

    # Execute hook in the context of the new worktree
    if (cd "$worktree_path" && "$hook_script"); then
        log_success "$hook_name hook executed successfully"
    else
        log_warning "$hook_name hook failed, but continuing..."
        return 1
    fi
}