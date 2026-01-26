---
name: issue
description: 明确需求，创建 Issue 跟踪需求进度
---

# 工作流程

- [ ] 开启工作流时，我会提供一段需求或问题描述给你，如果没给，你要先询问我需求或问题是什么
- [ ] 如果我给你的信息中带有 Jira 链接，尝试获取 Jira Issue 中的内容，能帮助你了解更多信息，如果没有相关获取工具则跳过
- [ ] 根据我的需求和相关资料的内容，理解一下我们要做什么、解决什么问题
- [ ] 总结一下然后创建一个 Github Issue
- [ ] 把 Issue assign 给我
- [ ] 根据你认为这个需求的性质，为 Issue 打上标签，如 `bug`、`enhancement`、`performance`、`documentation` 等，需要确保 Github 中设置了该标签
- [ ] 如果和 Jira Issue 有关系，则在 Issue 中关联 Jira 链接，同时也在 Jira 中关联 Github Issue

# 相关工具

- 必须在 git 仓库下才能使用 gh cli 来操作 Git
- 涉及到 Jira Issue 时，使用 Atlassian Plugin 的 Jira MCP 工具来访问 Jira Issue 的内容

# 做与不做

- ✅ 可以阅读仓库内所有代码和文档
- ❌ 不要修改仓库内任何代码和文档，也不要提交任何内容
- ✅ 可以创建、修改相关 Github Issue 信息
- ❌ 不要操作其它无关的 Github Issue 信息
