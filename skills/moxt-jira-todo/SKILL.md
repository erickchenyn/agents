---
name: moxt-jira-todo
description: 查询每日待办事项，包括 Jira 任务，统一展示所有需要关注的工作
---

综合查询和展示每日待办事项，整合来自 Jira 的所有任务。

## 执行步骤

### 任务查询

- 使用 moxt-cli 的 jira 功能
- 获取 Atlassian 账户信息
- 使用 JQL 查询 Jira Issue，查询条件：
  - Project 为 MOXT
  - Assignee 是本人
  - 状态为未完成 `not in (Done, Closed, Resolved, Validated)`
  - 类型为 `Story, SubTask, Task, Bug`

### 展示格式

```
## 🎯 Jira 任务

### Story - <数量> 个
1. **<标题>** (<状态名称>) - https://wkong.atlassian.net/browse/MOXT-<编号>

### Bug - <数量> 个
1. **<标题>** (<状态名称>) - https://wkong.atlassian.net/browse/MOXT-<编号>

### Task - <数量> 个
1. **<标题>** (<状态名称>) - https://wkong.atlassian.net/browse/MOXT-<编号>

### Sub-task - <数量> 个
1. **<标题>** (<状态名称>) - https://wkong.atlassian.net/browse/MOXT-<编号>
```

### Slack 发送（可选）

- 检查是否设置了 SLACK_BOT_TOKEN 环境变量
- 如果设置了，将报告发送到指定的 Slack 频道
- 使用 Slack API 发送格式化的消息
