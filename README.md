# CLAUDE

This repository contains Claude Code global prompts for personal use.

| Skill | Description |
|-------|-------------|
| [github-commit](skills/github-commit/SKILL.md) | 提交代码、跟踪 PR 状态、完成代码合并 |
| [github-issue](skills/github-issue/SKILL.md) | 明确问题和需求，创建 Github Issue 记录有关信息，便于之后查看和跟踪进度 |
| [moxt-daily-todo](skills/moxt-daily-todo/SKILL.md) | 查询每日待办事项，包括 Jira 任务、GitHub Issues 和 GitHub PRs，统一展示所有需要关注的工作 |
| [moxt-project-repo](skills/moxt-project-repo/SKILL.md) | clone paraflow 项目的 git 仓库并进行分析 |
| [workspace-check](skills/workspace-check/SKILL.md) | 检查所有 workspace 工作区的详细状态，显示综合信息表格包括安全性、PR 状态等 |
| [workspace-clean](skills/workspace-clean/SKILL.md) | 安全清理 git worktrees，仅删除无未提交改动、无未推送提交、无打开 PR 的工作区 |
| [workspace-create](skills/workspace-create/SKILL.md) | 基于 origin/main 创建新的 git worktree 和分支，自动配置并切换到新工作区用于并行开发 |
| [workspace-switch](skills/workspace-switch/SKILL.md) | 智能切换到指定分支或 PR 的 worktree，不存在时自动创建，支持 PR ID 数字识别 |

---

*This document was automatically generated based on commit [`3081c5b033adeec1eedddb4950b9ad391b493775`](https://github.com/erickchenyn/claude/commit/3081c5b033adeec1eedddb4950b9ad391b493775).*
