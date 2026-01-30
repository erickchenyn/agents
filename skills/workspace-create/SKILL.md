---
name: workspace-create
description: 基于当前项目的 origin/main 创建一个新的 git worktree 和分支，用于并行开发
---

## 工作流

1. **获取项目信息**
   - 检查是否在项目 git 仓库中
   - 根据 `git remote origin url` 提取项目名
   - 获得项目所在的上级绝对路径作为根目录（项目目录应为 `<根目录>/<项目名>`）
   - 生成当前时间戳，格式: `YYYYMMDD-HHMMSS`

2. **构建名称**
   - worktree 名称: `<项目名>-<时间戳>`
   - 分支名称: `chenyn/<时间戳>`
   - worktree 路径: `<根目录>/<项目名>-<时间戳>`（所有 worktree 应该在同一级目录下）

3. **创建工作区**
   - 检查并拉取最新的 origin/main
   - 创建基于 origin/main 的新分支和 worktree
   - 自动切换到新的工作区目录

4. **后续操作**
   - 显示新工作区路径和分支信息
   - 设置项目本地的 git user 信息为：名称 `erick.chen` 邮箱 `erick.chen@paraflow.com`
   - 执行 `q generate` 初始化代码

## 示例

假设当前项目名为 `moxt`，根目录为 `home/wukong`，执行时间为 2024 年 1 月 30 日 14:30:22，则：

- 创建 worktree: `home/wukong/moxt-20240130-143022`
- 创建分支: `chenyn/20240130-143022`
- 执行预配置的初始化命令
- 切换到新工作区继续开发
