#!/bin/bash

# workspace-common.sh - 通用的 workspace 环境检查和工具函数
# 供所有 workspace 脚本共同使用

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

# 中文版打印函数（兼容 workspace-create）
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

# 检查基础环境
check_workspace_environment() {
    local script_name="${1:-workspace script}"

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
        print_error "Not in main worktree. Please switch to main worktree first:"
        print_error "  Main worktree: $main_worktree"
        print_error "  Current dir:   $current_dir"
        print_info "Run: cd \"$main_worktree\""
        exit 1
    fi

    print_success "Environment check passed"
}

# 中文版环境检查（兼容 workspace-create）
check_workspace_environment_zh() {
    local script_name="${1:-workspace script}"

    log_info "检查工作区环境..."

    # 检查是否在 git 仓库中
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "当前目录不是 git 仓库"
        exit 1
    fi

    # 检查是否在主工作区
    local current_dir=$(pwd)
    local main_worktree=$(git worktree list --porcelain | grep "^worktree " | head -1 | cut -d' ' -f2-)

    if [[ "$current_dir" != "$main_worktree" ]]; then
        log_error "当前不在主工作区中"
        log_error "主工作区: $main_worktree"
        log_error "当前目录: $current_dir"
        log_error "请切换到主工作区后重新运行"
        exit 1
    fi

    log_success "环境检查通过"
}

# 获取项目信息
get_project_info() {
    # 获取远程仓库 URL
    if ! ORIGIN_URL=$(git remote get-url origin 2>/dev/null); then
        print_error "Cannot get origin remote URL"
        exit 1
    fi

    # 从 URL 提取项目名
    if [[ "$ORIGIN_URL" =~ github\.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
        PROJECT_NAME="${BASH_REMATCH[2]%.git}"
    else
        print_error "Cannot parse project name from origin URL: $ORIGIN_URL"
        exit 1
    fi

    # 获取项目根目录
    PROJECT_DIR=$(pwd)
    ROOT_DIR=$(dirname "$PROJECT_DIR")

    print_info "Project: $PROJECT_NAME"
    print_info "Project dir: $PROJECT_DIR"
    print_info "Root dir: $ROOT_DIR"
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

# 检查必要命令是否可用
check_gh_available() {
    if command -v gh >/dev/null 2>&1; then
        export GH_AVAILABLE=true
        print_info "GitHub CLI available"
    else
        export GH_AVAILABLE=false
        print_warning "GitHub CLI not available, some features will be limited"
    fi
}

# 安全的分支名转换（/ 替换为 -）
safe_branch_name() {
    local branch_name="$1"
    echo "$branch_name" | sed 's/\//-/g'
}

# 检查工作区是否干净
is_worktree_clean() {
    local worktree_path="$1"

    if [[ ! -d "$worktree_path" ]]; then
        return 1
    fi

    # 切换到工作区并检查状态
    (cd "$worktree_path" && git diff --quiet && git diff --cached --quiet)
}

# 检查是否有未推送的提交
has_unpushed_commits() {
    local worktree_path="$1"

    if [[ ! -d "$worktree_path" ]]; then
        return 1
    fi

    # 切换到工作区并检查未推送提交
    local unpushed_count
    unpushed_count=$(cd "$worktree_path" && git rev-list --count "@{u}".. 2>/dev/null || echo "0")
    [[ "$unpushed_count" -gt 0 ]]
}

# 输出工作区切换命令
show_worktree_switch_info() {
    local worktree_path="$1"

    # 直接输出切换命令，用户可以用 eval $(wc ...) 方式调用
    echo "cd \"$worktree_path\" && cc"
}