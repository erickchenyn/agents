# CLAUDE

This repository contains Claude Code global prompts for personal use.

| Skill | Description |
|-------|-------------|
| [github-commit](skills/github-commit/SKILL.md) | 提交代码、跟踪 PR 状态、完成代码合并 |
| [github-issue](skills/github-issue/SKILL.md) | 明确问题和需求，创建 Github Issue 记录有关信息，便于之后查看和跟踪进度 |
| [moxt-daily-todo](skills/moxt-daily-todo/SKILL.md) | 查询每日待办事项，包括 Jira 任务、GitHub Issues 和 GitHub PRs，统一展示所有需要关注的工作 |
| [moxt-project-repo-debug](skills/moxt-project-repo-debug/SKILL.md) | clone paraflow 项目的 git 仓库并进行分析 |
| [workspace-check](skills/workspace-check/SKILL.md) | 检查所有 workspace 工作区的状态，显示哪些可以安全清理 |
| [workspace-clean](skills/workspace-clean/SKILL.md) | 清理安全的 git worktree，并将其 Claude 配置合并回主工作区以保持记忆延续 |
| [workspace-create](skills/workspace-create/SKILL.md) | 基于当前项目的 origin/main 创建一个新的 git worktree 和分支，用于并行开发 |
| [workspace-switch](skills/workspace-switch/SKILL.md) | 根据提供的分支名或 GitHub PR ID，查找本地对应的 worktree。如果不存在则创建新的 worktree，如果存在则直接切换 |

---

*This document was automatically generated based on commit [`ebeb32160417dfbcee8c26d59262dba1ef9f9f44`](https://github.com/erickchenyn/claude/commit/ebeb32160417dfbcee8c26d59262dba1ef9f9f44).*
Enhanced wcheck functionality test
