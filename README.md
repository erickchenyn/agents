# CLAUDE

This repository contains Claude Code global prompts for personal use.

| Skill | Description |
|-------|-------------|
| commit | 提交代码、跟踪 PR 状态、完成代码合并 |
| github-todo | 查询所有与我相关的未完成的 GitHub Issue 和 PR，按类型分组显示 |
| issue | 明确问题和需求，创建 Github Issue 记录有关信息，便于之后查看和跟踪进度 |
| jira-todo | 查找 MOXT 项目中分配给我的未完成 Jira 任务，按类型分组显示 |
| repo-debug | clone paraflow 项目的 git 仓库并进行分析 |
| workspace-checkout | 根据提供的分支名或 GitHub PR ID，查找本地对应的 worktree。如果不存在则创建新的 worktree，如果存在则直接切换 |
| workspace-create | 基于当前项目的 origin/main 创建一个新的 git worktree 和分支，用于并行开发 |
| workspace-remove | 移除指定的 git worktree，并将其 Claude 配置合并回主工作区以保持记忆延续 |

---

*This document was automatically generated based on commit [`2126ae465c2e821612cbb5d451d66b08d536536a`](https://github.com/erickchenyn/claude/commit/2126ae465c2e821612cbb5d451d66b08d536536a).*
