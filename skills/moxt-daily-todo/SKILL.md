---
name: moxt-daily-todo
description: 查询每日待办事项，包括 Jira 任务、GitHub Issues 和 GitHub PRs，统一展示所有需要关注的工作
allowed_tools:
  - "mcp__plugin_atlassian_atlassian__atlassianUserInfo"
  - "mcp__plugin_atlassian_atlassian__searchJiraIssuesUsingJql"
---

综合查询和展示每日待办事项，整合来自 Jira 和 GitHub 的所有任务。

## 执行步骤

### 1. Jira 任务查询

- 检查是否安装了 Atlassian Plugin 插件并能使用 Atlassian MCP 工具
- 获取我的 Atlassian 账户信息
- 用 JQL 查询 Jira Issue，查询条件：
  - Project 为 MOXT
  - Assignee 是我本人
  - 状态为未完成 `not in (Done, Closed, Resolved, Validated)`
  - 类型为 `Story, SubTask, Task, Bug`

### 2. GitHub 内容查询

- 获取当前 GitHub 用户名
- 分别查询以下类型的 Issue 和 PR：
  - Issues assigned to me
  - PRs assigned to me
  - Issues mentioning me
  - PRs mentioning me
  - PRs requesting my review
  - Issues involving me (broader search)
  - PRs involving me (broader search)
- 去重并按类型分组

### 3. 统一展示格式

### 4. Slack 发送（可选）

- 检查是否设置了 SLACK_BOT_TOKEN 环境变量
- 如果设置了，将报告发送到指定的 Slack 频道
- 使用 Slack API 发送格式化的消息

```
# 📋 每日待办事项

## 🎯 Jira 任务

### Story - <数量> 个
1. **<标题>** (<状态名称>) - https://wkong.atlassian.net/browse/MOXT-<编号>

### Bug - <数量> 个
1. **<标题>** (<状态名称>) - https://wkong.atlassian.net/browse/MOXT-<编号>

### Task - <数量> 个
1. **<标题>** (<状态名称>) - https://wkong.atlassian.net/browse/MOXT-<编号>

### Sub-task - <数量> 个
1. **<标题>** (<状态名称>) - https://wkong.atlassian.net/browse/MOXT-<编号>

## 🐙 GitHub Issues

### 🔴 分配给我的 Issues
1. **[#XXXX] Issue 标题** (Open)
   - 标签: label1, label2
   - 更新: 日期
   - 链接: GitHub 链接

### 🔔 提到我的 Issues
1. **[#XXXX] Issue 标题** (Open)
   - 作者: 作者名
   - 更新: 日期
   - 链接: GitHub 链接

### 📊 我创建的活跃 Issues
1. **[#XXXX] Issue 标题** (Open)
   - 标签: 标签列表
   - 分配给: 负责人
   - 更新: 日期
   - 链接: GitHub 链接

## 🔀 GitHub PRs

### 🟡 分配给我的 PRs
1. **[#XXXX] PR 标题** (Open)
   - 状态: MERGEABLE
   - 更新: 日期
   - 链接: GitHub 链接

### 👀 请求我 Review 的 PRs
1. **[#XXXX] PR 标题** (Open)
   - 作者: 作者名
   - 更新: 日期
   - 链接: GitHub 链接

### 🔔 提到我的 PRs
1. **[#XXXX] PR 标题** (Open)
   - 作者: 作者名
   - 更新: 日期
   - 需要: 具体需要做的事情
   - 链接: GitHub 链接

### 📊 我创建的活跃 PRs
1. **[#XXXX] PR 标题** (Open)
   - 状态: MERGEABLE/CONFLICTING
   - 更新: 日期
   - 链接: GitHub 链接

---

## ⚠️ 今日重点关注
- 总结需要立即关注和行动的关键项目
- 按优先级列出具体的行动项
- 突出显示紧急或阻塞的任务
```

## Slack 集成配置

要启用 Slack 发送功能，需要配置以下环境变量：

```bash
# Slack Bot Token (必需)
export SLACK_BOT_TOKEN="xoxb-your-bot-token"

# Slack 频道 ID 或名称（可选，默认发送到 #general）
export SLACK_CHANNEL="#daily-todos"
```

### Slack 消息格式

发送到 Slack 的消息将采用以下格式：

- 使用 Slack 的 Block Kit 格式
- 保持 emoji 和结构化布局
- 链接会自动展开
- 支持折叠长列表以保持可读性

## 注意事项

- **只显示有内容的分组，空的分组不展示**
- 只显示状态为 open 的 GitHub Issue 和 PR
- 只显示未完成状态的 Jira 任务
- 自动去重避免重复显示
- 按优先级排序：Jira 任务 > GitHub 分配 > mention > review request > 自己创建的
- 优先显示需要关注的内容，并在底部总结需要采取行动的项目
- 提供直接链接便于快速访问
- 统一的日期和时间格式展示
- 如果配置了 SLACK_BOT_TOKEN，会自动发送到 Slack
