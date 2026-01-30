#!/bin/bash

# workspace-remove.sh - 移除指定的 git worktree，并将其 Claude 配置合并回主工作区
# 基于 workspace-remove skill 的脚本化实现

set -e  # 遇到错误立即退出

# 配置部分
DRY_RUN=false

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示帮助信息
show_help() {
    cat << EOF
workspace-remove.sh - Remove git worktree and merge Claude settings

Usage: $0 [OPTIONS]

Options:
    -h, --help          Show this help message
    -d, --dry-run       Preview mode, don't actually execute operations

Examples:
    $0                  # Remove all safe worktrees, skip unsafe ones
    $0 -d               # Preview removal of all worktrees

EOF
}

# 解析命令行参数
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
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                print_error "Unexpected argument: $1"
                print_info "No arguments needed, script processes all worktrees automatically"
                show_help
                exit 1
                ;;
        esac
    done
}

# 检查环境
check_environment() {
    print_info "Checking environment..."

    # 检查是否在 git 仓库中
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        print_error "Not inside a git repository"
        exit 1
    fi

    # 检查是否在主工作区
    local main_worktree=$(git worktree list --porcelain | grep -A1 "^worktree" | head -1 | cut -d' ' -f2-)
    local current_dir=$(pwd)

    if [[ "$current_dir" != "$main_worktree" ]]; then
        print_error "Not in main worktree. Please switch to main worktree first: $main_worktree"
        exit 1
    fi

    # 检查 GitHub CLI（可选）
    if command -v gh >/dev/null 2>&1; then
        GH_AVAILABLE=true
    else
        GH_AVAILABLE=false
        print_warning "GitHub CLI not available, PR status checks will be skipped"
    fi

    print_success "Environment check passed"
}

# 获取所有非主工作区
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

# 检查工作区状态
check_worktree_safety() {
    local worktree_path="$1"
    local branch_name="$2"
    local safety_report=""
    local is_safe=true

    print_info "Checking safety for: $worktree_path ($branch_name)"

    # 检查工作区是否存在
    if [[ ! -d "$worktree_path" ]]; then
        safety_report+="⚠️  Worktree directory not found\n"
        is_safe=false
        echo -e "$is_safe|$safety_report"
        return
    fi

    # 检查工作区状态
    if ! (cd "$worktree_path" && git diff --quiet && git diff --cached --quiet); then
        safety_report+="⚠️  Uncommitted changes detected\n"
        is_safe=false
    fi

    # 检查未推送的提交
    if (cd "$worktree_path" && [[ $(git rev-list --count "@{u}"..) -gt 0 ]] 2>/dev/null); then
        safety_report+="⚠️  Unpushed commits detected\n"
        is_safe=false
    fi

    # 检查 PR 状态（如果 GitHub CLI 可用）
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

    # 检查远程分支
    if git ls-remote --heads origin "$branch_name" | grep -q "$branch_name" 2>/dev/null; then
        safety_report+="ℹ️  Remote branch still exists\n"
    else
        safety_report+="✅ Remote branch has been deleted\n"
    fi

    if [[ "$is_safe" == "true" ]]; then
        safety_report="✅ Safe to remove\n$safety_report"
    fi

    echo -e "$is_safe|$safety_report"
}


# 备份和合并 Claude 配置
backup_claude_settings() {
    local worktree_path="$1"
    local worktree_settings="$worktree_path/.claude/settings.local.json"
    local main_settings=".claude/settings.local.json"

    if [[ ! -f "$worktree_settings" ]]; then
        return 0
    fi

    print_info "Backing up Claude settings from: $worktree_path"

    if [[ "$DRY_RUN" == "true" ]]; then
        print_warning "[DRY RUN] Would merge Claude settings:"
        print_warning "  From: $worktree_settings"
        print_warning "  To: $main_settings"
        return 0
    fi

    # Simple merge: copy if main settings don't exist, warn if they do exist
    if [[ ! -f "$main_settings" ]]; then
        mkdir -p "$(dirname "$main_settings")"
        cp "$worktree_settings" "$main_settings"
        print_success "Copied Claude settings to main worktree"
    else
        print_warning "Main worktree already has Claude settings, manual merge may be needed"
        print_info "Worktree settings: $worktree_settings"
        print_info "Main settings: $main_settings"
    fi
}

# 移除工作区
remove_worktree() {
    local worktree_path="$1"
    local branch_name="$2"

    print_info "Removing worktree: $worktree_path ($branch_name)"

    if [[ "$DRY_RUN" == "true" ]]; then
        print_warning "[DRY RUN] Would remove worktree:"
        print_warning "  git worktree remove \"$worktree_path\""
        return 0
    fi

    # 备份 Claude 配置
    backup_claude_settings "$worktree_path"

    # 移除工作区
    if git worktree remove "$worktree_path"; then
        print_success "Removed worktree: $worktree_path"
    else
        print_error "Failed to remove worktree: $worktree_path"
        return 1
    fi
}

# 主执行函数
main() {
    parse_args "$@"

    if [[ "$DRY_RUN" == "true" ]]; then
        print_warning "=== DRY RUN MODE - No actual changes will be made ==="
    fi

    check_environment

    local worktrees_to_remove=()

    # Process all non-main worktrees
    mapfile -t worktrees_to_remove < <(get_worktrees)
    print_info "Processing all non-main worktrees"

    if [[ ${#worktrees_to_remove[@]} -eq 0 ]]; then
        print_warning "No worktrees selected for removal"
        exit 0
    fi

    # Safety checks - show status but continue with automatic filtering
    print_info "Performing safety checks..."

    for worktree in "${worktrees_to_remove[@]}"; do
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

    # Execute removal - only for safe worktrees
    local success_count=0
    local skipped_count=0
    local total_count=${#worktrees_to_remove[@]}
    local safe_worktrees=()
    local unsafe_worktrees=()

    # Separate safe and unsafe worktrees
    for worktree in "${worktrees_to_remove[@]}"; do
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

    # Remove safe worktrees
    for worktree in "${safe_worktrees[@]}"; do
        local path=$(echo "$worktree" | cut -d'|' -f1)
        local branch=$(echo "$worktree" | cut -d'|' -f2)

        if remove_worktree "$path" "$branch"; then
            success_count=$((success_count + 1))
        fi
    done

    # Report skipped unsafe worktrees
    for unsafe_entry in "${unsafe_worktrees[@]}"; do
        local worktree=$(echo "$unsafe_entry" | cut -d'|' -f1-2)
        local path=$(echo "$worktree" | cut -d'|' -f1)
        local branch=$(echo "$worktree" | cut -d'|' -f2)
        local reasons=$(echo "$unsafe_entry" | cut -d'|' -f3-)

        print_warning "Skipped unsafe worktree: $(basename "$path") ($branch)"
        echo -e "  Reasons: $reasons" | sed 's/\\n/\n  /g'
        skipped_count=$((skipped_count + 1))
    done

    # Report final results
    print_success "Removal completed: $success_count removed, $skipped_count skipped (unsafe)"

    if [[ "$skipped_count" -gt 0 ]]; then
        print_info "To remove unsafe worktrees, resolve the safety issues first:"
        print_info "- Commit or stash uncommitted changes"
        print_info "- Push unpushed commits to remote"
        print_info "- Close or merge open PRs"
    fi

    if [[ "$success_count" -gt 0 ]] || [[ "$skipped_count" -gt 0 ]]; then
        print_info "Current worktrees:"
        git worktree list
    fi
}

# 错误处理
cleanup_on_error() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        print_error "Operation failed with exit code $exit_code"
    fi
    exit $exit_code
}

trap cleanup_on_error ERR

# 执行主函数
main "$@"