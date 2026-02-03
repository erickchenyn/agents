---
name: workspace-clean
description: 安全清理 git worktrees，仅删除无未提交改动、无未推送提交、无打开 PR 的工作区
---

## 执行流程

1. **调用脚本执行清理操作**
   - 使用 Bash 工具调用 `workspace-clean.sh` 脚本（位于 `~/.claude/skills/workspace/` 目录）
   - 传递用户提供的参数（如 `-d` 预览模式）
   - 捕获脚本的完整输出，包括安全检查结果和清理状态

2. **解析脚本输出**
   - 从脚本输出中提取安全检查报告
   - 识别哪些 worktree 被标记为安全清理
   - 识别哪些 worktree 被跳过及其原因
   - 提取清理操作的统计信息（成功清理数量、跳过数量）

3. **验证清理结果**
   - 使用 `git worktree list` 获取清理后的 worktree 列表
   - 对比清理前后的 worktree 状态，确认预期的 worktree 已被清理
   - 检查主工作区的 `.claude/settings.local.json` 是否已更新（如有配置合并）
   - 验证被清理的工作区目录是否已不存在

4. **分析跳过的 worktree**
   - 检查被跳过的不安全 worktree 的具体状态：
     - 使用 `git status` 检查未提交的更改
     - 使用 `git log --oneline @{u}..` 检查未推送的提交
     - 使用 GitHub CLI 检查相关 PR 的状态
     - 确认脚本的安全判断是否准确

5. **报告清理结果**
   - 成功情况下，向用户报告：
     - 清理统计：成功清理的 worktree 数量
     - 跳过统计：因安全检查失败而跳过的数量
     - 列出所有被清理的 worktree 路径和分支名
     - 配置合并情况（如有发生）
   - 如有跳过的 worktree，详细说明：
     - 每个跳过的 worktree 及其不安全的原因
     - 解决建议（提交更改、推送代码、关闭 PR 等）
   - 如果清理过程出错，报告具体错误和建议

6. **提供后续操作建议**
   - 对于跳过的不安全 worktree，提供具体的解决步骤
   - 建议用户验证主工作区状态是否正常
   - 如有必要，指导如何手动清理剩余的 worktree
   - 提醒用户检查合并的 Claude 配置是否符合预期