---
name: paraflow-performance
description: 分析 project/canvas 页面加载及 git synergy 同步性能埋点与监控，提供优化建议
---

分析 metric track 埋点代码：

- 以 `editor-v2/lifecycle/project-page` 为入口，分析 project、canvas 加载流程中的 metric 埋点实现，了解各个 stage 包含了哪些步骤、做了哪些事
- 以 `editor-v2/git-storage/setup-git-storage` 和 `editor-v2/synergy/sync-remote-v2` 为入口，分析 Git、Synergy、有关的 metric 埋点实现，了解各个 stage 包含哪些步骤、做了哪些事
- 使用列表、表格或流程图的方式，列出加载流程（核心成员名称或一句话描述）与 metric 埋点的对应关系
- 为「埋点是否能有效覆盖加载流程所有场景性能监控」打一个分数（0-10）

分析 metric dashboard 配置及数据：

- 使用 datadog 相关的 skill 获取 dashboard 信息（Canvas Open Performance 和 Git Operations Performance）
- 结合代码分析 dashboard/widget 配置是否合理（是否存在 widget 重复或缺失、widget 的展示配置是否需要优化等）、widget 数据是否正常（如没有数据即不正常），是否能直观反映出 project 加载过程的用户体验水平
- 使用表格的方式，列出 dashboard 上各个 widget 的观测行为（如何有效反映加载流程的性能水平），以及 widget 当前反映出的数据情况
- 为「客户端加载流程是否具备良好的用户体验水平」打一个分数（0-10）

根据 metric 数据反向优化代码：

- 对于有优化空间的数据结果，结合相对应的代码实现，给出代码上的优化建议

工具提示：

- datadog dashboard/widget 配置及数据查询，需要有相关 scope 权限的 app key
- datadog dashboard/widget 配置的更新，需要有 api key
