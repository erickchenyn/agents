---
name: repo-debug
description: clone paraflow 项目的 git 仓库并进行分析
---

- 确认你的本地环境配置了 GITEA 的 token
- 根据我提供的 paraflow 项目链接或 ID，clone 对应的 GITEA 仓库到本地
  - 测试环境链接如 `https://test.paraflow.biz/projects/<project-id>`，那么仓库地址为 `https://gitea-testing.onrender.com/pfp-2/moxt-project-<project-id>`
  - 生产环境链接如 `https://paraflow.com/projects/<project-id>`，那么仓库地址为 `https://gitea-1-24-6.onrender.com/pfp-online/moxt-project-<project-id>`（只读权限，可以 clone）
- 将仓库 clone 到本地的 `~/` 根目录下
- 根据我的指示，基于本地仓库中的 git 和数据进行分析
