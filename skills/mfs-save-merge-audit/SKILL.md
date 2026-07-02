---
name: mfs-save-merge-audit
description: Audit Moxt MFS save-merge behavior and observability. Use when asked about MfsFileService.updateFile three-way merge semantics, base/ours/theirs meanings, save-merge outcome interpretation, Datadog metric/log queries for mfs_file_save_merge_total, recent 24h/7d trend tables or charts, or exporting overlap_resolved_with_conflict examples with base/ours/theirs/merged content for manual review.
---

# MFS Save Merge Audit

## Core Model

`MfsFileService.updateFile()` is the single-file MFS update path with base-aware three-way merge support. It only enters merge logic when a caller passes a stale `baseSha`:

```ts
if (baseSha && baseSha !== existingFile.contentHash) {
  const base = downloadBlob(workspaceId, baseSha)
  const theirs = downloadBlob(workspaceId, existingFile.contentHash)
  const ours = params.content
  const mergeResult = threeWayMerge(base, ours, theirs, isSaveMergeEnabled)
}
```

Interpret the three versions as:

- `base`: the blob hash/version the caller started from (`baseSha`).
- `ours`: the content the caller is trying to save now.
- `theirs`: the current server active content (`existingFile.contentHash`) when save is processed.
- `merged`: the final content written after merge resolution.

If `baseSha` is absent, `updateFile()` skips merge completely and writes `ours` as the new current content. That is last-writer-wins.

## Outcomes

Explain outcomes using this table:

| outcome | Scenario | Current result |
| --- | --- | --- |
| `no_resolution_needed` | No real merge is needed: `ours === base`, `theirs === base`, or `ours === theirs`. | Use the existing unchanged side or identical content. |
| `non_overlapping_auto_resolved` | `ours` and `theirs` both changed relative to `base`, but edited different line ranges. | Auto-merge and keep both sides. |
| `overlap_auto_resolved_by_insert` | Both sides overlap, but overlap is insert-like, such as both inserting near the same base position. | Preserve both inserts where possible. |
| `overlap_resolved_with_conflict` | Both sides update/delete overlapping regions. | Current V2 resolves automatically with pushed content (`ours`) winning and records the conflict-like outcome; it does not fail the request by itself. |

Be precise: `overlap_resolved_with_conflict` means conflict-shaped overlap was detected and auto-resolved. It is not necessarily an error or thrown `FileConflict`.

## Observability

Metric:

```text
mfs_file_save_merge_total
```

Useful Datadog metric queries:

```text
sum:mfs_file_save_merge_total{env:online} by {outcome}.as_count()
sum:mfs_file_save_merge_total{env:online,!outcome:no_resolution_needed} by {outcome}.as_count()
sum:mfs_file_save_merge_total{env:online,!outcome:no_resolution_needed} by {outcome}.as_count().rollup(sum, 86400)
```

Use `Past 24h` or `Past 7d` in Datadog for windowed views. The repository dashboard also has `System Overview` -> `File Save Merge`.

Logs:

```text
@env:online "mfs-file-save: succeeded" @branch:merge_overlap_resolved_with_conflict
```

Ordinary success logs can identify:

- `repoId`
- `fileId`
- `path`
- `baseSha`
- `serverSha` (`theirs`)
- `mfsVersion`
- `contentHash` (`merged`)
- `branch: merge_<outcome>`

Detailed PRE_MERGE logs are narrower and may only appear for internal users:

```text
"mfs-file-save: save encountered conflict and recorded baseSha, pre-merge snapshot, and merged snapshot"
```

When detailed logs are unavailable, find `ours` from MFS history: the `PRE_MERGE` commit immediately before the merged `mfsVersion` for the same `fileId`.

## Workflow

1. Confirm project env if running inside `moxt`:

```bash
direnv status
direnv exec . env | rg 'DATADOG|DD_|DRIZZLE_KIT_URL|S3_BUCKET'
```

2. Use the bundled script for metrics and Markdown tables:

```bash
python3 ~/.agents/skills/mfs-save-merge-audit/scripts/mfs_save_merge_audit.py metrics --env online --windows 24h,7d
```

3. Use the script to export overlap logs and optional per-event content comparisons:

```bash
python3 ~/.agents/skills/mfs-save-merge-audit/scripts/mfs_save_merge_audit.py export-overlaps \
  --env online \
  --window 24h \
  --out /tmp/mfs-save-merge-overlaps \
  --limit 50
```

To download blob contents, add `--download-blobs --bucket <bucket>`. If `--bucket` is omitted, the script uses `S3_BUCKET`.

4. Summarize results with:

- Outcome counts for 24h and 7d.
- A compact bar chart in Markdown when useful.
- A short list of representative `overlap_resolved_with_conflict` events.
- For manual verification exports, include file paths to each event directory and the generated diffs.

## Manual Reconstruction

For one `overlap_resolved_with_conflict` log:

1. Read `baseSha`, `serverSha`, `contentHash`, `repoId`, `fileId`, `path`, `mfsVersion`.
2. Resolve `workspaceId` from `repo_v2`:

```sql
select workspace_id from repo_v2 where repo_id = '<repoId>';
```

3. Find `ours` if not present in detailed Datadog log:

```sql
select fc.id, fc.content_hash, c.commit_message, c.created_at
from mfs_shard_N.mfs_file_changes fc
join mfs_shard_N.mfs_commits c on c.id = fc.commit_id
where fc.file_id = '<fileId>'
  and fc.id < <mergedMfsVersion>
  and c.commit_message like '%PRE_MERGE%'
order by fc.id desc
limit 1;
```

4. Download:

```text
private/blobs/{workspaceId}/{baseSha}.dat
private/blobs/{workspaceId}/{oursSha}.dat
private/blobs/{workspaceId}/{serverSha}.dat
private/blobs/{workspaceId}/{mergedSha}.dat
```

5. Generate diffs:

```bash
git diff --no-index base.md ours.md > base_vs_ours.diff || true
git diff --no-index base.md theirs.md > base_vs_theirs.diff || true
git diff --no-index ours.md merged.md > ours_vs_merged.diff || true
git diff --no-index theirs.md merged.md > theirs_vs_merged.diff || true
```

## Caveats

- Agent writes without `baseSha/baseContentHash` do not enter this outcome accounting.
- The ordinary merge success log currently lacks `workspaceId` and `oursSha`; fetch them from DB/PRE_MERGE history when needed.
- The script assumes Datadog US site (`api.datadoghq.com`) by default; override with `--datadog-site` when needed.
