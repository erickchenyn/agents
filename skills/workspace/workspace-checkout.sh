#!/bin/bash

# workspace-checkout.sh - 根据分支名或 PR ID 切换到对应的 worktree，如果不存在则创建
# 基于 workspace-checkout skill 的脚本化实现

set -e  # 遇到错误立即退出

# 导入公共函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/workspace-util.sh"

# 配置部分
DRY_RUN=false

# 显示帮助信息
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

# 解析命令行参数
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

# 检查环境
check_environment() {
    # 使用公共环境检查函数
    check_workspace_environment "workspace-checkout"

    # 检查必要的命令 - GitHub CLI 是必需的
    if ! command -v gh >/dev/null 2>&1; then
        log_error "GitHub CLI (gh) is required but not installed"
        exit 1
    fi
}

# 解析输入获取有效分支名
resolve_branch_name() {
    local input="$1"
    local branch_name=""

    log_info "Resolving branch name for: $input"

    # 检查是否为数字（PR ID）
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        log_info "Input appears to be a PR ID: $input"
        # 获取 PR 对应的分支名
        if ! branch_name=$(gh pr view "$input" --json headRefName -q '.headRefName' 2>/dev/null); then
            log_error "Failed to get branch name for PR #$input"
            exit 1
        fi
        log_info "PR #$input corresponds to branch: $branch_name"
    else
        # 假设为分支名，检查是否存在
        branch_name="$input"
        if ! git ls-remote --heads origin "$branch_name" | grep -q "$branch_name"; then
            log_error "Branch '$branch_name' does not exist on remote"
            exit 1
        fi
        log_info "Branch '$branch_name' exists on remote"
    fi

    echo "$branch_name"
}

# 查找现有 worktree
find_existing_worktree() {
    local branch_name="$1"
    local worktree_path=""

    log_info "Looking for existing worktree for branch: $branch_name"

    # 查找现有的 worktree
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

# 创建新的 worktree
create_worktree() {
    local branch_name="$1"

    log_info "Creating new worktree for branch: $branch_name"

    # 获取项目信息
    local origin_url=$(git remote get-url origin)
    local project_name=$(basename "$origin_url" .git)
    local project_dir=$(pwd)
    local root_dir=$(dirname "$project_dir")

    # 创建安全的目录名（替换 / 为 -）
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

    # 创建 worktree
    if ! git worktree add "$worktree_path" "origin/$branch_name"; then
        log_error "Failed to create worktree"
        exit 1
    fi

    log_success "Created worktree: $worktree_path"
    echo "$worktree_path"
}

# 设置工作区
setup_worktree() {
    local worktree_path="$1"
    local branch_name="$2"

    log_info "Setting up worktree: $worktree_path"

    # 获取 git 用户信息（优先本地配置，再全局配置）
    local git_user_name=$(git config user.name)
    local git_user_email=$(git config user.email)

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "[DRY RUN] Would setup worktree:"
        log_warning "  cd \"$worktree_path\""
        log_warning "  git config user.name \"$git_user_name\""
        log_warning "  git config user.email \"$git_user_email\""
        log_warning "  git pull"
        log_warning "  q generate"
        log_warning "  Copy .claude/settings.local.json"
        return 0
    fi

    # 切换到新工作区
    cd "$worktree_path"

    # 设置 git 用户信息
    git config user.name "$git_user_name"
    git config user.email "$git_user_email"
    log_success "Set git user: $git_user_name <$git_user_email>"

    # 更新代码
    log_info "Updating code..."
    git pull

    # 执行代码生成
    if command -v q >/dev/null 2>&1; then
        log_info "Running q generate..."
        q generate --cache=false || log_warning "q generate failed, but continuing..."
    else
        log_warning "Command 'q' not found, skipping code generation"
    fi

    # 拷贝 Claude 设置
    local main_settings="../$(basename "$(dirname "$worktree_path")")/.claude/settings.local.json"
    if [[ -f "$main_settings" ]]; then
        mkdir -p ".claude"
        cp "$main_settings" ".claude/settings.local.json"
        log_success "Copied Claude settings"
    else
        log_warning "Main worktree Claude settings not found: $main_settings"
    fi
}

# 主执行函数
main() {
    parse_args "$@"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "=== DRY RUN MODE - No actual changes will be made ==="
    fi

    check_environment

    # 解析分支名
    local branch_name
    branch_name=$(resolve_branch_name "$BRANCH_OR_PR")

    # 查找现有 worktree
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

# 错误处理
cleanup_on_error() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Operation failed with exit code $exit_code"
    fi
    exit $exit_code
}

trap cleanup_on_error ERR

# 执行主函数
main "$@"