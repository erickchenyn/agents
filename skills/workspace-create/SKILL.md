---
name: workspace-create
description: 基于当前项目的 origin/main 创建一个新的 git worktree 和分支，用于并行开发
---

## 工作流

1. **检查工作区环境**
   - 检查是否在项目 git 仓库中
   - 检查是否在主工作区：使用 `git worktree list --porcelain` 验证当前目录是否为主工作区，如不是则提示并停止执行

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

