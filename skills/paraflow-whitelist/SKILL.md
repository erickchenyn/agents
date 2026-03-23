---
name: paraflow-whitelist
description: 给外部用户开 moxt 新版本白名单，将邮箱追加到功能开关配置中
---

# 外部用户白名单管理

用户会提供一批邮箱地址，你需要将它们追加到以下 4 个功能开关配置文件的 `SpecificUserList` 策略的 `userList` 数组末尾：

1. `feature-switch/src/features-explicit/server-ts/user-scoped/cloud-api.ts`
2. `feature-switch/src/features-explicit/web/user-scoped/cloud.ts`
3. `feature-switch/src/features-explicit/web/user-scoped/code-viewer.ts`
4. `feature-switch/src/features-explicit/web/user-scoped/yjs.ts`

## 工作流

- [ ] 读取上述 4 个文件，确认当前已有的白名单内容
- [ ] 去除已存在的邮箱，将新邮箱追加到每个文件的 `userList` 数组中
- [ ] 告诉用户本次新增了哪些邮箱，跳过了哪些已存在的邮箱
- [ ] 完成修改后，调用 `/commit` skill 提交代码并跟踪 PR
