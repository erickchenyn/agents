---
name: markdown-article-for-x
description: Use when user provides an X (Twitter) Article URL to convert into a local markdown file.
---

Convert an X Article page into a well-formatted markdown file. Inherits all rules from [@markdown-article](../markdown-article/SKILL.md), with the following X-specific additions and overrides.

## Important: Playwright MCP required

X pages are fully JavaScript-rendered. `curl`, `WebFetch`, and other static fetching methods **cannot** retrieve any article content. You **must** use Playwright MCP to load and extract the page.

## X-specific steps

After navigating to the page:

1. If the page has a "Focus mode" link (`/article/` path), navigate to it for a cleaner layout
2. When extracting images, query `img` elements whose `src` contains `pbs.twimg.com/media/`, and replace `name=small` with `name=large` for high resolution
3. Remove X-specific UI noise: follower counts, "Sign up", "Log in", engagement metrics, "Want to publish your own Article?", etc.

## File location override

The filename uses an `x-` prefix followed by the article ID:

- `x-<id>`: the `<id>` is extracted from the URL path (the last segment), e.g. for `https://x.com/HiTw93/status/2032091246588518683` the ID is `2032091246588518683`

```
~/.claude/articles/2026-03-14/x-2032091246588518683.md
```

## Example

Source URL: `https://x.com/HiTw93/status/2032091246588518683`
Output path: `~/.claude/articles/2026-03-14/x-2032091246588518683.md`

The file starts like this:

```markdown
# 你不知道的 Claude Code：架构、治理与工程实践

> https://x.com/HiTw93/status/2032091246588518683

## 0. 太长不读

今天这篇文章源于最近半年深度使用 Claude Code、两个账号每月 40 刀氪金换来的一些踩坑经验，希望能给大伙一些输入。

...
```
