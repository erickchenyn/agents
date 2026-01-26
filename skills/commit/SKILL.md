---
name: commit
description: 提交代码、跟踪 PR 状态、完成代码合并
---

# 工作流

完全按下面的流程来工作，将这个列表作为一个 checklist，完成或跳过一步才能进行下一步

## 提交代码和 PR

- [ ] 如果当前在 main 分支上，先创建新的 feature 分支，分支名以 `chenyn/` 开头，分支名遵守 kebab-case。任何时候不应该在 main 分支上直接提交代码
- [ ] Commit message 应该符合 Angular Conventional 规范，message 应使用英文且不使用 Scope
- [ ] 你创建的提交，应在最后记录 `Co-Authored-By: Claude <noreply@anthropic.com>`
- [ ] 成功创建 Commit 之后自动推送到远程。
- [ ] 如果分支还没有对应的 PR，则创建 PR
  - 在 PR 上设置合并后删除分支
- [ ] 如果此次修改有想关联的 Issue，则应该关联 Issue

## 跟踪 PR 状态

- [ ] 确保 PR 已经创建
- [ ] 跟踪 PR 上的 check 和 review 状态
  - 如果有任何 check 失败
    - [ ] 将失败的 job 内容总结给我
    - [ ] 根据错误信息修复相关错误，按「提交代码与 PR」的流程再次提交，然后继续「跟踪 PR」状态
  - 如果发现 review 中有严重错误存在
    - [ ] 将问题总结给我
    - [ ] 你根据这次 PR 的修改内容和背景判断下问题是否真实存在且合理，是否需要修复
      - 此次 PR 的背景可以通过 PR 相关联的 Issue 了解
    - [ ] 用 AskUser 工具来询问我是修复问题还是拒绝修复
      - 选择修复：根据问题内容，按「提交代码与 PR」的流程再次提交，然后继续「跟踪 PR」状态
      - 选择拒绝：调用 dismiss 接口并给出拒绝的理由
- [ ] 最终确保 PR 上的 check 和 review 都没有问题

## 完成代码合并

- [ ] 将 PR 加入合并队列，等待合并
- [ ] 等 PR 成功合并
- [ ] 确认 feature 分支已删除
- [ ] 如 PR 有关联的 Issue，查询 Issue 中的执行计划进度
  - [ ] 将相关的工作标记完成
  - [ ] 如果全部完成，则将 Issue 关掉

# 相关工具

- 需要在 git 仓库下使用 gh cli 来操作 Git
