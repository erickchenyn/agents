#!/bin/bash

# workspace-checkout.sh - 根据分支名或 PR ID 切换到对应的 worktree，如果不存在则创建
# 基于 workspace-checkout skill 的脚本化实现

set -e  # 遇到错误立即退出

# 导入公共函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/workspace-common.sh"

# 配置部分
GIT_USER_NAME="${GIT_USER_NAME:-erick.chen}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-erick.chen@paraflow.com}"
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
    -u, --user <name>   Set git user name (default: $GIT_USER_NAME)
    -e, --email <email> Set git user email (default: $GIT_USER_EMAIL)

Examples:
    $0 feature-auth                    # Checkout branch feature-auth
    $0 123                            # Checkout PR #123
    $0 -d chenyn/fix-bug              # Preview checkout operation
    $0 -u "john" -e "john@example.com" 456  # Custom git config

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
            -u|--user)
                GIT_USER_NAME="$2"
                shift 2
                ;;
            -e|--email)
                GIT_USER_EMAIL="$2"
                shift 2
                ;;
            -*)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$BRANCH_OR_PR" ]]; then
                    BRANCH_OR_PR="$1"
                else
                    print_error "Too many arguments. Expected one branch name or PR ID."
                    exit 1
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$BRANCH_OR_PR" ]]; then
        print_error "Branch name or PR ID is required"
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
        print_error "GitHub CLI (gh) is required but not installed"
        exit 1
    fi
}

# 解析输入获取有效分支名
resolve_branch_name() {
    local input="$1"
    local branch_name=""

    print_info "Resolving branch name for: $input"

    # 检查是否为数字（PR ID）
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        print_info "Input appears to be a PR ID: $input"
        # 获取 PR 对应的分支名
        if ! branch_name=$(gh pr view "$input" --json headRefName -q '.headRefName' 2>/dev/null); then
            print_error "Failed to get branch name for PR #$input"
            exit 1
        fi
        print_info "PR #$input corresponds to branch: $branch_name"
    else
        # 假设为分支名，检查是否存在
        branch_name="$input"
        if ! git ls-remote --heads origin "$branch_name" | grep -q "$branch_name"; then
            print_error "Branch '$branch_name' does not exist on remote"
            exit 1
        fi
        print_info "Branch '$branch_name' exists on remote"
    fi

    echo "$branch_name"
}

# 查找现有 worktree
find_existing_worktree() {
    local branch_name="$1"
    local worktree_path=""

    print_info "Looking for existing worktree for branch: $branch_name"

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

    print_info "Creating new worktree for branch: $branch_name"

    # 获取项目信息
    local origin_url=$(git remote get-url origin)
    local project_name=$(basename "$origin_url" .git)
    local project_dir=$(pwd)
    local root_dir=$(dirname "$project_dir")

    # 创建安全的目录名（替换 / 为 -）
    local safe_branch_name=$(echo "$branch_name" | sed 's/\//-/g')
    local worktree_name="${project_name}-${safe_branch_name}"
    local worktree_path="${root_dir}/${worktree_name}"

    print_info "Project: $project_name"
    print_info "Root directory: $root_dir"
    print_info "Worktree path: $worktree_path"

    if [[ "$DRY_RUN" == "true" ]]; then
        print_warning "[DRY RUN] Would create worktree:"
        print_warning "  git worktree add \"$worktree_path\" \"origin/$branch_name\""
        echo "$worktree_path"
        return 0
    fi

    # 创建 worktree
    if ! git worktree add "$worktree_path" "origin/$branch_name"; then
        print_error "Failed to create worktree"
        exit 1
    fi

    print_success "Created worktree: $worktree_path"
    echo "$worktree_path"
}

# 设置工作区
setup_worktree() {
    local worktree_path="$1"
    local branch_name="$2"

    print_info "Setting up worktree: $worktree_path"

    if [[ "$DRY_RUN" == "true" ]]; then
        print_warning "[DRY RUN] Would setup worktree:"
        print_warning "  cd \"$worktree_path\""
        print_warning "  git config user.name \"$GIT_USER_NAME\""
        print_warning "  git config user.email \"$GIT_USER_EMAIL\""
        print_warning "  git pull"
        print_warning "  q generate"
        print_warning "  Copy .claude/settings.local.json"
        return 0
    fi

    # 切换到新工作区
    cd "$worktree_path"

    # 设置 git 用户信息
    git config user.name "$GIT_USER_NAME"
    git config user.email "$GIT_USER_EMAIL"
    print_success "Set git user: $GIT_USER_NAME <$GIT_USER_EMAIL>"

    # 更新代码
    print_info "Updating code..."
    git pull

    # 执行代码生成
    if command -v q >/dev/null 2>&1; then
        print_info "Running q generate..."
        q generate --cache=false || print_warning "q generate failed, but continuing..."
    else
        print_warning "Command 'q' not found, skipping code generation"
    fi

    # 拷贝 Claude 设置
    local main_settings="../$(basename "$(dirname "$worktree_path")")/.claude/settings.local.json"
    if [[ -f "$main_settings" ]]; then
        mkdir -p ".claude"
        cp "$main_settings" ".claude/settings.local.json"
        print_success "Copied Claude settings"
    else
        print_warning "Main worktree Claude settings not found: $main_settings"
    fi
}

# 主执行函数
main() {
    parse_args "$@"

    if [[ "$DRY_RUN" == "true" ]]; then
        print_warning "=== DRY RUN MODE - No actual changes will be made ==="
    fi

    check_environment

    # 解析分支名
    local branch_name
    branch_name=$(resolve_branch_name "$BRANCH_OR_PR")

    # 查找现有 worktree
    local existing_worktree
    if existing_worktree=$(find_existing_worktree "$branch_name"); then
        print_success "Found existing worktree: $existing_worktree"
        setup_worktree "$existing_worktree" "$branch_name"

        print_success "Switched to existing worktree"
        print_info "Worktree path: $existing_worktree"
        print_info "Branch: $branch_name"
        print_info ""
        print_info "To switch to this worktree, run:"
        print_info "  cd \"$existing_worktree\" && cc"
    else
        print_info "No existing worktree found, creating new one..."
        local new_worktree
        new_worktree=$(create_worktree "$branch_name")
        setup_worktree "$new_worktree" "$branch_name"

        print_success "Created and switched to new worktree"
        print_info "Worktree path: $new_worktree"
        print_info "Branch: $branch_name"
        print_info ""
        print_info "To switch to this worktree, run:"
        print_info "  cd \"$new_worktree\" && cc"
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