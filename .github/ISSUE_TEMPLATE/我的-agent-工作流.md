---
name: 我的 AGENT 工作流
about: 为 Agent 初始化工作流创建 Issue 的模板
title: ''
labels: ''
assignees: erickchenyn

---

# 我遇到的问题

* 

---

# 我大致思路或方案

* 

---

# 希望你做的事

* 先了解上述问题背景和大致的思路方案
  * 如果包含 jira 链接，可以使用 atlassian 插件获取 jira issue 信息
  * 如果包含 github 链接（issue 或 pr 等），可以使用 gh cli 获取相关信息
  * 如果包含 sentry 链接，可以使用 moxt-cli 的 sentry 获取 issue 或 event 信息
  * 如果包含 langfuse 链接，可以使用 moxt-cli 的 langfuse 获取日志信息
  * 如果包含 gitea 仓库链接，可以使用 moxt-cli 的 project:clone 拉取仓库到本地暂存以做分析
  * 如果包含 paraflow replay 链接，可以使用 moxt-cli 的 project:replay 拉取 url 参数中的回放文件到本地暂存以做分析（使用 replay-data-analysis skill）
* 做调研和分析，和我讨论清楚细节并沟通方案
* 将你详细的分析结果和可执行方案 comment 到 issue 中（**重要**：必须足够详细清晰，尽可能使用列表、表格、流程图等更直观的表达方式）
* 你后续提交的 pr 需要关联到此 issue 上，pr 合并之后要 close 这个 issue（即使不在一个仓库中）
