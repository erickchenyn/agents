---
name: moxt-workspace
description: 使用 worktree 能力切换不同 workspace 并行工作
---

> **重要**：此 skill 已废弃，改为使用 `claude --worktree` 创建工作区。可以在 `settings.json` 中通过配置 hook 自定义创建行为（如分支命名等）。

确保下列脚本代码存在于我的 zsh 或 bash 配置中，提示用户使用 `wl wc wa wr` 切换工作区。

## 查看已有工作区

```bash
# worktree
alias wl="git worktree list"
```

## 切换已有工作区

```bash
# worktree checkout
wc() {
  if [ -z "$1" ]; then
    echo "Usage: wc <worktree-path>"
    echo "Example: wc /home/wukong/moxt-chenyn-1770116665"
    return 1
  fi

  local worktree_path="$1"

  if [ -d "$worktree_path" ]; then
    cd "$worktree_path"
    echo "Switched to worktree: $worktree_path"
  else
    echo "Worktree not found: $worktree_path"
    return 1
  fi
}
```

## 新建并切换到工作区

```bash
# worktree add
wa() {
  local timestamp=$(date +%s)
  local branch_name="chenyn/$timestamp"
  local main_worktree=$(git worktree list --porcelain | grep "^worktree " | head -1 | cut -d' ' -f2-)
  local main_basename=$(basename "$main_worktree")
  local worktree_path="$(dirname "$main_worktree")/$main_basename-chenyn-$timestamp"

  echo "Creating worktree: $worktree_path"
  echo "Branch: $branch_name"

  if git worktree add -b "$branch_name" "$worktree_path" origin/main; then
    cd "$worktree_path"
    echo "Switched to new worktree: $worktree_path"
    q generate --cache=false
    cc
  else
    echo "Failed to create worktree"
    return 1
  fi
}
```

## 删除工作区并回到主工作区

```bash
# worktree remove
wr() {
  local current_dir=$(pwd)
  local current_worktree=$(basename "$current_dir")
  local main_worktree=$(git worktree list --porcelain | grep "^worktree " | head -1 | cut -d' ' -f2-)

  if [[ "$current_dir" == "$main_worktree" ]]; then
    echo "Error: Cannot remove main worktree. Please run from other worktree."
    echo "Main worktree: $main_worktree"
    return 1
  fi


  echo "Current worktree: $current_worktree"

  if ! git diff --quiet || ! git diff --cached --quiet || [[ -n $(git ls-files --others --exclude-standard) ]]; then
    echo "Warning: Git working directory is not clean"
    git status --short
    echo ""
    echo -n "Are you sure you want to remove this worktree? (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[yY]$ ]]; then
      echo "Aborted"
      return 1
    fi
  fi

  echo "Removing worktree: $current_worktree"
  cd "$main_worktree"

  if git worktree remove "$current_dir"; then
    echo "Successfully removed worktree: $current_worktree"
  else
    echo "Failed to remove worktree: $current_worktree"
    return 1
  fi
}
```
