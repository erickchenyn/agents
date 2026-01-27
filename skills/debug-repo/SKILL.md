---
name: debug-repo
description: clone paraflow 项目的 git 仓库并进行分析
---

- 确认本地环境配置了 GITEA 的 token
- 根据我提供的 paraflow 项目链接或 ID，clone 对应的 GITEA 仓库到本地
  - 测试环境链接如 `https://test.paraflow.biz/projects/<project-id>`，那么仓库地址为 `https://gitea-testing.onrender.com/pfp-2/moxt-project-<project-id>`
  - 生产环境链接如 `https://paraflow.com/projects/<project-id>`，目前没有权限，无法 clone，跳过
- 将仓库 clone 到本地的 `~/` 根目录下
- 然后根据我的指示，基于本地仓库中的 git 和数据进行分析
