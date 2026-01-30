---
name: workspace-create
description: 基于当前项目的 origin/main 创建一个新的 git worktree 和分支，用于并行开发
---

## 工作流

1. **检查工作区环境**
   - 检查是否在项目 git 仓库中
   - **检查是否在主工作区**：
     - 使用 `git worktree list --porcelain` 获取所有工作区信息
     - 第一个工作区即为主工作区，检查其路径是否与当前工作目录 `pwd` 一致
     - 如果不在主工作区，显示详细的错误提示：
     - "❌ 此 skill 必须在项目主工作区中执行"
     - "当前目录：[当前路径]"
     - "主工作区：[主工作区路径]"
     - "请使用 `cd [主工作区路径] && cc` 切换到主工作区后重试"
     - 主工作区路径示例：如果主工作区在 `/home/wukong/.claude`，则必须在此目录下执行
   - 只有在主工作区中才能继续后续操作

2. **获取项目信息**
   - 根据 `git remote origin url` 提取项目名
   - 获得项目所在的上级绝对路径作为根目录（项目目录应为 `<根目录>/<项目名>`）
   - 生成当前时间戳，格式: `YYYYMMDD-HHMMSS`

3. **构建名称**
   - worktree 名称: `<项目名>-<时间戳>`
   - 分支名称: `chenyn/<时间戳>`
   - worktree 路径: `<根目录>/<项目名>-<时间戳>`（所有 worktree 应该在同一级目录下）

4. **创建工作区**
   - 检查并拉取最新的 origin/main
   - 创建基于 origin/main 的新分支和 worktree
   - 显示新工作区路径和分支信息

5. **初始化新的工作区**
   - 切换到新工作区目录
   - 设置新工作区的 git user 信息为：名称 `erick.chen` 邮箱 `erick.chen@paraflow.com`
   - 在新工作区中执行 `q generate` 初始化代码
   - 将主工作区下的 `.claude/settings.local.json` 拷贝一份到新工作区下

6. **提示用户手动切换工作区**
   - 提示用户切换工作区操作，如 `cd <根目录>/<新工作区目录> && cc`

## 使用要求

**⚠️ 重要提醒**：此 skill 必须在项目的主工作区中执行，否则会导致 worktree 创建失败或路径错误。

### 正确的使用方式
```bash
# 1. 确保在主工作区中
cd /path/to/main/workspace
cc  # 启动 Claude Code

# 2. 然后使用 workspace-create skill
/workspace-create [分支名]
```

### 错误处理
如果在非主工作区中执行，skill 会自动检测并提示正确的切换命令。

## 示例

假设当前项目名为 `moxt`，根目录为 `home/wukong`，执行时间为 2024 年 1 月 30 日 14:30:22，则：

- **前提条件**: 必须在 `home/wukong/moxt`（主工作区）中执行
- 创建 worktree: `home/wukong/moxt-20240130-143022`
- 创建分支: `chenyn/20240130-143022`
- 在新工作区目录 `home/wukong/moxt-20240130-143022` 下检查 git user 信息及执行 `q generate` 初始化代码
- 提示用户 `cd home/wukong/moxt-20240130-143022 && cc`
