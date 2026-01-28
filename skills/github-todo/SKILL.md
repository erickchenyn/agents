---
name: github-todo
description: 查询所有与我相关的 GitHub Issue 和 PR (assigned, authored, mentioned, review-requested)，按类型分组显示
allowed_tools:
  - "Bash"
---

查询所有与当前用户相关的 GitHub Issue 和 PR，包括：
- 分配给我的 (assigned)
- 我创建的 (authored)
- 提到我的 (mentioned)
- 请求我 review 的 (review-requested)

执行步骤：
1. 获取当前 GitHub 用户名
2. 分别查询以下类型的 Issue 和 PR：
   - Issues assigned to me
   - PRs assigned to me
   - Issues mentioning me
   - PRs mentioning me
   - PRs requesting my review
   - Issues involving me (broader search)
   - PRs involving me (broader search)
3. 去重并按类型分组展示

输出格式：
```
# 📋 GitHub Todo List

## 🔴 分配给我的 Issues
1. **[#XXXX] Issue 标题** (Open)
   - 标签: label1, label2
   - 更新: 日期
   - 链接: GitHub 链接

## 🟡 分配给我的 PRs
1. **[#XXXX] PR 标题** (Open)
   - 状态: MERGEABLE
   - 更新: 日期
   - 链接: GitHub 链接

## 🔔 提到我的 Issues
1. **[#XXXX] Issue 标题** (Open)
   - 作者: 作者名
   - 更新: 日期
   - 链接: GitHub 链接

## 🔔 提到我的 PRs
1. **[#XXXX] PR 标题** (Open)
   - 作者: 作者名
   - 更新: 日期
   - 需要: 具体需要做的事情
   - 链接: GitHub 链接

## 👀 请求我 Review 的 PRs
1. **[#XXXX] PR 标题** (Open)
   - 作者: 作者名
   - 更新: 日期
   - 链接: GitHub 链接

## 📊 我创建的活跃内容
### Issues (X 个)
1. **[#XXXX] Issue 标题** (Open)
   - 标签: 标签列表
   - 分配给: 负责人
   - 更新: 日期
   - 链接: GitHub 链接

### PRs (X 个)
1. **[#XXXX] PR 标题** (Open)
   - 状态: MERGEABLE/CONFLICTING
   - 更新: 日期
   - 链接: GitHub 链接

---

## ⚠️ 需要关注的项目
- 总结需要立即关注和行动的关键项目
- 按优先级列出具体的行动项
```

注意事项：
- 只显示状态为 open 的 Issue 和 PR
- 自动去重避免重复显示
- **只显示有内容的分组，空的分组不展示**
- 按优先级排序：分配 > mention > review request > 自己创建的
- 优先显示需要关注的内容，并在底部总结需要采取行动的项目
- 提供直接的 GitHub 链接便于快速访问