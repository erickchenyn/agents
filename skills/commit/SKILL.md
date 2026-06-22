---
name: commit
description: 提交代码、跟踪 PR 状态、完成代码合并
---

你需要严格按下面的步骤来操作，只有完成或跳过一步才能进行下一步

## 提交代码和 PR

- [ ] 如果当前在 main 分支上，先创建新的 feature 分支，分支名以 `chenyn-` 开头，分支名遵守 kebab-case
  - 不应该在 main 分支上直接提交代码
  - 不应该使用 amend 修改已经提交的 commit 而是创建新的 commit
- [ ] Commit message 应该符合 Angular Conventional 规范，message 应使用英文且不使用 Scope
- [ ] 在提交最后记录当前 agent 对应的 co-author：
  - Claude 使用 `Co-Authored-By: Claude <noreply@anthropic.com>`
  - Codex 使用 `Co-Authored-By: Codex <noreply@openai.com>`
- [ ] 成功创建 Commit 之后自动推送到远程
- [ ] 如果分支还没有对应的 PR，则创建新的 PR，并设置合并后删除 feature 分支
- [ ] 如果此次修改有相关 Issue，则应该关联 Issue 到 PR

## 跟踪 PR 状态

- [ ] 确保 PR 已经创建，告诉我 PR 的链接
- [ ] 跟踪 PR 上的 check 和 review 状态
  - 如果有任何 check 失败
    - [ ] 先将失败的 job 内容总结给我
    - [ ] 根据错误信息修复相关错误，按上一章「提交代码与 PR」的流程再次提交，然后继续「跟踪 PR」状态
  - 如果发现 review 中有严重问题存在
    - [ ] 先将问题总结给我
    - [ ] 根据这次 PR 的修改内容和背景（可以通过 PR 的描述的关联 Issue 了解）判断下问题是否真实存在且合理，是否需要修复，告诉我你的判断和依据
    - [ ] 使用 AskUser 工具来询问我是修复问题还是拒绝修复
      - 修复：修改代码修复问题，按「提交代码与 PR」的流程再次提交，然后继续「跟踪 PR」状态
      - 拒绝：调用接口 dismiss 这个 review 并给出拒绝的理由
- [ ] 最终确保 PR 上的 check 和 review 都没有问题
  - [ ] 如果 PR 上 review 报告了严重问题，你也确认了最新的提交已经修复了该问题，但 PR 上存在如「跳过了本次 Review」的评论时，你可以追加一条当前 reviewer 对应的评论来强行触发重新 review，如 `@claude` 或 `@codex review`。如果 PR 的 review 没有任何问题，就忽略这一步
  - [ ] 在最新一次部署完之后，告诉我预览环境的链接

## 询问我是否跟踪并完成代码合并

- [ ] 使用 AskUser 工具来询问是否要自动合并 PR
  - 否：则你的工作完成，跳过以下所有步骤
  - 是：你要继续完成以下工作
    - [ ] 将 PR 加入合并队列或者确保使用 squash merge 或 rebase merge 来合并 PR
    - [ ] 等待 PR 被成功合并，确认 feature 分支在远程已被删除
    - [ ] 如 PR 有关联的 Issue，关闭 Issue

## 相关说明

- 在 git 仓库下使用 gh cli 来操作 Git
- 确保 git user 信息有效
  - **特殊规则**：如果在 moxt/paraflow 仓库下，git user 邮箱必须是 `erick.chen@paraflow.com`
