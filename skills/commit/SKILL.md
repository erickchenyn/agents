---
name: commit
description: 提交代码、跟踪 PR 状态、完成代码合并
---

# 工作流

你需要严格按下面的步骤来操作，只有完成或跳过一步才能进行下一步

## 提交代码和 PR

- [ ] 如果当前在 main 分支上，先创建新的 feature 分支，分支名以 `chenyn/` 开头，分支名遵守 kebab-case。任何时候不应该在 main 分支上直接提交代码
- [ ] Commit message 应该符合 Angular Conventional 规范，message 应使用英文且不使用 Scope
- [ ] 在提交最后记录 `Co-Authored-By: Claude <noreply@anthropic.com>`
- [ ] 成功创建 Commit 之后自动推送到远程
- [ ] 如果分支还没有对应的 PR，则创建新的 PR，并设置合并后删除 feature 分支
- [ ] 如果此次修改有相关 Issue，则应该关联 Issue 到 PR

## 跟踪 PR 状态

- [ ] 确保 PR 已经创建
- [ ] 跟踪 PR 上的 check 和 review 状态
  - 如果有任何 check 失败
    - [ ] 先将失败的 job 内容总结给我
    - [ ] 根据错误信息修复相关错误，按上一章「提交代码与 PR」的流程再次提交，然后继续「跟踪 PR」状态
  - 如果发现 review 中有严重问题存在
    - [ ] 先将问题总结给我
    - [ ] 根据这次 PR 的修改内容和背景（可以通过 PR 的描述的关联 Issue 了解）判断下问题是否真实存在且合理，是否需要修复，告诉我你的判断和依据
    - [ ] 用 AskUser 工具来询问我是修复问题还是拒绝修复
      - 选择修复：修改代码修复问题，按「提交代码与 PR」的流程再次提交，然后继续「跟踪 PR」状态
      - 选择拒绝：调用接口 dismiss 这个 review 并给出拒绝的理由
- [ ] 最终确保 PR 上的 check 和 review 都没有问题

## 完成代码合并

- [ ] 用 AskUser 工具来询问是否自动合并
- 如果我回答否：你的工作完成，跳过以下所有步骤
- [ ] 如果我回答是，你需要将 PR 加入合并队列，然后等待直到 PR 被成功合并
- [ ] 确认 feature 分支在远程已被删除，然后在本地切回 main 分支
- [ ] 如 PR 有关联的 Issue，关闭 Issue

# 相关工具说明

- 你可以在 git 仓库下使用 gh cli 来操作 Git
- 你需要确保 git user 信息有效，邮箱必须是 `erick.chen@paraflow.com`
