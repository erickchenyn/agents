---
name: workspace-checkout
description: 根据提供的分支名或 GitHub PR ID，查找本地对应的 worktree。如果不存在则创建新的 worktree，如果存在则直接切换
---

## 执行逻辑

1. **解析输入**
   - 检查是否在项目 git 仓库中
   - 如果输入为 Github PR ID，通过 GitHub CLI 获取对应分支名
   - 如果输入为分支名，通过 Github CLI 检查对应的分支名是否存在
   - 解析结果为一个有效的分支名

2. **查找现有 worktree**
   - 使用 `git worktree list --porcelain` 查找是否已存在对应分支的工作区

3. **如果 worktree 不存在**
   - 通过 git remote origin url 获取项目名
   - 获得项目所在的上级绝对路径作为根目录（项目目录应为 `<根目录>/<项目名>`）
   - 将分支名中的 `/` 替换为 `-`（避免创建多级目录）
   - 创建工作区：`<根目录>/<项目名>-<有效分支名>`
   - 基于 `origin/<有效分支名>` 创建本地工作区
   - 切换到新创建的本地工作区
   - 显示新工作区路径和分支信息
   - 设置项目本地的 git user 信息为：名称 `erick.chen` 邮箱 `erick.chen@paraflow.com`
   - 执行 `q generate` 初始化代码
   - 将主工作区下的 `.claude/settings.local.json` 拷贝一份到新工作区下

4. **如果 worktree 已存在**
   - 直接切换到对应的工作区目录
   - 显示新工作区路径和分支信息
   - 确保项目本地的 git user 信息为：名称 `erick.chen` 邮箱 `erick.chen@paraflow.com`
   - 执行 `git pull` 更新代码
   - 执行 `q generate` 初始化代码

5. **提示用户手动切换工作区**
   - 提示用户切换工作区操作，如 `cd <根目录>/<新工作区目录> && cc`
