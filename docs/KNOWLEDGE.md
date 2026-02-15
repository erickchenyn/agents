# 知识库

> 知识库是一个「关键词 -> 名次解释和备注」的索引库。当涉及到某些关键词时，你可以通过知识库索引到相应的解释和备注，快速了我提及这些关键词的背景知识。

## MoXT 项目知识库

- **workspace 模式**：
  - 在开启 `paraflow-workspace` feature switch 开关时，加载项目名以 `.ws` 结尾的项目时，自动进入的新模式。
  - 模式识别入口位于 `3-after-document-loaded` 文件中
  - 模式的 UI 组件位于 `design/workspace-view` 目录中
