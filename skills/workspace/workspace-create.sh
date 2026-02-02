#!/bin/bash

# workspace-create.sh - 创建新的 git worktree 和分支，用于并行开发
# 基于 workspace-create skill 的脚本化实现

set -e  # 遇到错误立即退出

# 导入公共函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/workspace-util.sh"

# 配置部分
GIT_USER_NAME="${GIT_USER_NAME:-erick.chen}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-erick.chen@paraflow.com}"
BRANCH_PREFIX="${BRANCH_PREFIX:-chenyn}"
DRY_RUN=false

# 显示帮助信息
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
    -h, --help              显示帮助信息
    -d, --dry-run           只显示将要执行的操作，不实际执行
    -u, --user <name>       设置 git 用户名（默认: $GIT_USER_NAME）
    -e, --email <email>     设置 git 邮箱（默认: $GIT_USER_EMAIL）

示例:
    $0                      # 使用默认设置创建工作区
    $0 -d                   # 预览模式，不实际执行
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
            -u|--user)
                GIT_USER_NAME="$2"
                shift 2
                ;;
            -e|--email)
                GIT_USER_EMAIL="$2"
                shift 2
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 检查工作区环境
check_environment() {
    # 使用公共环境检查函数
    check_workspace_environment_zh "workspace-create"

    # 检查是否有未提交的更改
    if ! git diff --quiet || ! git diff --staged --quiet; then
        log_warning "检测到未提交的更改"
        if [[ "$DRY_RUN" == false ]]; then
            read -p "是否继续? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "操作已取消"
                exit 0
            fi
        fi
    fi

    log_success "环境检查通过"
}

# 获取项目信息
get_project_info() {
    log_info "获取项目信息..."

    # 获取远程仓库 URL
    if ! ORIGIN_URL=$(git remote get-url origin 2>/dev/null); then
        log_error "无法获取 origin 远程仓库 URL"
        exit 1
    fi

    # 从 URL 提取项目名
    if [[ "$ORIGIN_URL" =~ github\.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
        PROJECT_NAME="${BASH_REMATCH[2]%.git}"
    else
        log_error "无法从 origin URL 解析项目名: $ORIGIN_URL"
        exit 1
    fi

    # 获取项目根目录（上级目录）
    CURRENT_DIR=$(pwd)
    ROOT_DIR=$(dirname "$CURRENT_DIR")

    # 生成时间戳
    TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

    # 构建名称
    BRANCH_NAME="${BRANCH_PREFIX}/${TIMESTAMP}"
    WORKTREE_NAME="${PROJECT_NAME}-${TIMESTAMP}"
    WORKTREE_PATH="${ROOT_DIR}/${WORKTREE_NAME}"

    log_success "项目信息获取完成"
    log_info "项目名: $PROJECT_NAME"
    log_info "工作区名: $WORKTREE_NAME"
    log_info "分支名: $BRANCH_NAME"
    log_info "工作区路径: $WORKTREE_PATH"
}

# 检查并拉取最新代码
fetch_latest() {
    log_info "检查并拉取最新的 origin/main..."

    if [[ "$DRY_RUN" == false ]]; then
        git fetch origin main
        log_success "代码拉取完成"
    else
        log_info "[DRY RUN] 将执行: git fetch origin main"
    fi
}

# 创建工作区
create_worktree() {
    log_info "创建新的 worktree 和分支..."

    # 检查工作区路径是否已存在
    if [[ -d "$WORKTREE_PATH" ]]; then
        log_error "工作区路径已存在: $WORKTREE_PATH"
        exit 1
    fi

    # 检查分支是否已存在
    if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
        log_error "分支已存在: $BRANCH_NAME"
        exit 1
    fi

    if [[ "$DRY_RUN" == false ]]; then
        # 创建基于 origin/main 的新分支和 worktree
        git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" origin/main
        log_success "Worktree 创建完成: $WORKTREE_PATH"
    else
        log_info "[DRY RUN] 将执行: git worktree add -b $BRANCH_NAME $WORKTREE_PATH origin/main"
    fi
}

# 初始化新工作区
initialize_workspace() {
    log_info "初始化新工作区..."

    if [[ "$DRY_RUN" == false ]]; then
        # 进入新工作区
        cd "$WORKTREE_PATH"

        # 设置 git 用户信息
        git config user.name "$GIT_USER_NAME"
        git config user.email "$GIT_USER_EMAIL"
        log_success "Git 用户信息设置完成"

        # 检查是否存在 q 命令
        if command -v q > /dev/null 2>&1; then
            log_info "执行代码生成..."
            if q generate; then
                log_success "代码生成完成"
            else
                log_warning "代码生成失败，但继续进行"
            fi
        else
            log_warning "未找到 q 命令，跳过代码生成"
        fi

        # 拷贝 Claude 设置
        local source_settings="${CURRENT_DIR}/.claude/settings.local.json"
        local target_settings=".claude/settings.local.json"

        if [[ -f "$source_settings" ]]; then
            mkdir -p .claude
            cp "$source_settings" "$target_settings"
            log_success "Claude 设置拷贝完成"
        else
            log_warning "未找到 Claude 设置文件: $source_settings"
        fi

        # 返回原目录
        cd "$CURRENT_DIR"

    else
        log_info "[DRY RUN] 将在新工作区中执行:"
        log_info "[DRY RUN]   - 设置 git 用户: $GIT_USER_NAME <$GIT_USER_EMAIL>"
        log_info "[DRY RUN]   - 执行: q generate"
        log_info "[DRY RUN]   - 拷贝: .claude/settings.local.json"
    fi
}

# 显示完成信息
show_completion() {
    log_success "新工作区创建完成！"
    echo
    log_info "工作区信息:"
    log_info "  路径: $WORKTREE_PATH"
    log_info "  分支: $BRANCH_NAME"
    echo

    # 直接输出切换命令，用户可以用 eval $(wc create ...) 方式调用
    echo "cd \"$WORKTREE_PATH\" && cc"
}

# 清理函数（错误时调用）
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 && "$DRY_RUN" == false && -n "$WORKTREE_PATH" ]]; then
        log_warning "检测到错误，清理已创建的工作区..."
        if [[ -d "$WORKTREE_PATH" ]]; then
            git worktree remove --force "$WORKTREE_PATH" 2>/dev/null || true
        fi
        if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
            git branch -D "$BRANCH_NAME" 2>/dev/null || true
        fi
    fi
}

# 主函数
main() {
    # 设置错误清理
    trap cleanup EXIT

    parse_args "$@"

    if [[ "$DRY_RUN" == true ]]; then
        log_warning "预览模式 - 不会实际执行操作"
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
        log_info "[DRY RUN] 预览完成，使用 $0 实际执行操作"
    fi
}

# 如果脚本被直接执行（不是被 source）
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi