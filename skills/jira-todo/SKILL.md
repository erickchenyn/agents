---
name: jira-todo
description: 查找 MOXT 项目中分配给我的未完成 Jira 任务，按类型分组显示
allowed_tools:
  - "mcp__plugin_atlassian_atlassian__atlassianUserInfo"
  - "mcp__plugin_atlassian_atlassian__searchJiraIssuesUsingJql"
---

- 检查是否安装了 Atlassian Plugin 插件并能使用 Atlassian MCP 工具
- 获取我的 Atlassian 账户信息
- 用 JQL 查询 Jira Issue，查询条件：
  - Project 为 MOXT
  - Assignee 是我本人
  - 状态为未完成 `not in (Done, Closed, Resolved, Validated)`
  - 类型为 `Story, SubTask, Task, Bug`
- 根据不同的 Issue 类型分组，列出每个 Issue 的标题、状态和具体的链接

最终输出参考格式如下：

```
# Story - <数量> 个
1. **<标题>** (<状态名称>)：https://wkong.atlassian.net/browse/MOXT-<编号>

# Bug - <数量> 个
1. **<标题>** (<状态名称>)：https://wkong.atlassian.net/browse/MOXT-<编号>

# Task - <数量> 个
# Sub-task - <数量> 个
```
