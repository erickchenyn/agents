---
name: articles-reader
description: Use when user wants to start/open the articles reader, or manage the article index. Triggers on phrases like "启动文章阅读器", "打开阅读器", "start articles reader", etc.
---

Start the articles reader — a local web app for browsing and annotating saved markdown articles.

## Architecture

- **Server**: `~/.claude/articles/server.py` — Python HTTP server on port 8080, serves static files and provides a notes API (`POST /api/notes`) for persisting highlights/annotations
- **Frontend**: `~/.claude/articles/index.html` — SPA with sidebar file tree (grouped by date), markdown rendering, CN/EN bilingual dual-pane view, text highlighting, and note annotations
- **Articles**: stored as `.md` files under `~/.claude/articles/<YYYY-MM-DD>/`, with optional `.notes.json` sidecar files for highlights
- **Article index**: the file list in `index.html` is hardcoded in the `articles` JS object and must be updated when articles are added or removed

## Steps

### Starting the reader

1. Update the article index in `index.html` by scanning all `.md` files under `~/.claude/articles/` (excluding `index.html` and `server.py`), then updating the `const articles = { ... }` object in the `<script>` section. Group files by their date folder, sorted by date descending.
2. Start the server in background:
   ```bash
   cd ~/.claude/articles && python3 server.py
   ```
3. Open the browser:
   ```bash
   open http://localhost:8080
   ```
4. Report to the user that the reader is running at `http://localhost:8080`.

### Stopping the reader

If the user asks to stop/close the reader, find and kill the Python server process on port 8080:
```bash
lsof -ti:8080 | xargs kill
```

## Notes

- The server must be started from the `~/.claude/articles/` directory (it does `os.chdir` to its own directory)
- Default port is 8080, can be overridden via `PORT` env var (e.g. `PORT=8090 python3 server.py`); if 8080 is occupied, check what's using it and use an alternative port
- When updating the article index, preserve the existing structure — only modify the `const articles = { ... }` assignment
