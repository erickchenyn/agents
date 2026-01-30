# CLAUDE

This repository contains Claude Code global prompts for personal use.

| Skill | Description |
|-------|-------------|
| [github-commit](skills/github-commit/SKILL.md) | 提交代码、跟踪 PR 状态、完成代码合并 |
| [github-issue](skills/github-issue/SKILL.md) | 明确问题和需求，创建 Github Issue 记录有关信息，便于之后查看和跟踪进度 |
| [moxt-daily-todo](skills/moxt-daily-todo/SKILL.md) | 查询每日待办事项，包括 Jira 任务、GitHub Issues 和 GitHub PRs，统一展示所有需要关注的工作 |
| [moxt-project-repo-debug](skills/moxt-project-repo-debug/SKILL.md) | clone paraflow 项目的 git 仓库并进行分析 |
| [workspace-checkout](skills/workspace-checkout/SKILL.md) | 根据提供的分支名或 GitHub PR ID，查找本地对应的 worktree。如果不存在则创建新的 worktree，如果存在则直接切换 |
| [workspace-create](skills/workspace-create/SKILL.md) | 基于当前项目的 origin/main 创建一个新的 git worktree 和分支，用于并行开发 |
| [workspace-remove](skills/workspace-remove/SKILL.md) | 移除指定的 git worktree，并将其 Claude 配置合并回主工作区以保持记忆延续 |

---

*This document was automatically generated based on commit [`791524cc041c31472f5aa69cdabe80a45a9fcd56`](https://github.com/erickchenyn/claude/commit/791524cc041c31472f5aa69cdabe80a45a9fcd56).*
