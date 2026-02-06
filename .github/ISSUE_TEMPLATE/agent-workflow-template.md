---
name: AGENT 工作流 Issue 模板
about: 为 Agent 初始化工作流创建 Issue 的模板
title: ''
labels: ''
assignees: erickchenyn
---

* 

---

# 你的工作方式

* 了解问题，获取有关的信息
  * 如果包含 github 链接（issue 或 pr 等），可以使用 gh cli 获取相关信息（没有安装或不在仓库下则提醒我）
  * 如果包含 jira 链接，可以使用 moxt-cli 的 jira 命令获取 jira issue 信息（没有安装或不可用则提醒我集成）
  * 如果包含 sentry 链接，可以使用 moxt-cli 的 sentry 命令获取 issue 或 event 信息（这个能力在 moxt 项目中，需要配置 sentry token，不在仓库下或没有配置则提醒我）
  * 如果包含 langfuse 链接，可以使用 moxt-cli 的 langfuse 命令获取日志信息（这个能力在 moxt 项目中，需要配置 langfuse token，不在仓库下或没有配置则提醒我）
  * 如果包含 gitea 仓库链接，可以使用 moxt-cli 的 project:clone 命令拉取仓库到本地暂存以做分析（这个能力在 moxt 项目中，需要配置 gitea token，不在仓库下或没有配置则提醒我）
  * 如果包含 paraflow replay 链接，可以使用 moxt-cli 的 project:replay 命令拉取 url 参数中的回放文件到本地暂存以做分析（这个能力在 moxt 项目中，后续可以使用 moxt 项目中的 replay-data-analysis skill 帮助分析）
* 分析问题，和我讨论清楚细节并沟通可执行方案，先不要修改任何代码
  * 如果和客户端项目/编辑器/画布区加载、git 或数据同步性能有关，可以使用我个人的 moxt-performance skill 帮助分析
- **重要**：每一轮会话结束后，都要总结一下并 comment 到 issue 中，不用我确认。关键信息如分析结果、实现方案等，必须足够详细清晰，尽可能使用列表、表格、流程图等更直观的表达方式
- **重要**：每次修改代码后，都要用我个人的 moxt-commit skill 来提交代码创建 pr 并把 pr 关联到这个 issue 上。不用我确认，但注意先不要合并 pr
