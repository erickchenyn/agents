#!/usr/bin/env python3
"""Audit Moxt MFS save-merge Datadog metrics/logs and export merge examples."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import subprocess
import sys
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any


OUTCOMES = [
    "no_resolution_needed",
    "non_overlapping_auto_resolved",
    "overlap_auto_resolved_by_insert",
    "overlap_resolved_with_conflict",
]


def parse_window(value: str) -> int:
    match = re.fullmatch(r"(\d+)([hd])", value.strip())
    if not match:
        raise SystemExit(f"Invalid window {value!r}; use e.g. 24h or 7d")
    amount = int(match.group(1))
    unit = match.group(2)
    return amount * (3600 if unit == "h" else 86400)


def env_required(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        raise SystemExit(f"Missing required environment variable: {name}")
    return value


def datadog_request(site: str, method: str, path: str, params: dict[str, Any] | None = None, body: dict[str, Any] | None = None) -> Any:
    api_key = env_required("DATADOG_API_KEY")
    app_key = os.environ.get("DATADOG_APP_KEY") or os.environ.get("INTEGRATION_DATADOG_TERRAFORM_APP_KEY")
    if not app_key:
        raise SystemExit("Missing DATADOG_APP_KEY or INTEGRATION_DATADOG_TERRAFORM_APP_KEY")

    url = f"https://api.{site}{path}"
    if params:
        url += "?" + urllib.parse.urlencode(params)
    data = None
    headers = {
        "DD-API-KEY": api_key,
        "DD-APPLICATION-KEY": app_key,
        "Accept": "application/json",
    }
    if body is not None:
        data = json.dumps(body).encode("utf-8")
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", errors="replace")
        raise SystemExit(f"Datadog API error {error.code}: {detail}") from error


def query_metrics(site: str, env: str, window: str, include_noop: bool) -> dict[str, float]:
    now = int(dt.datetime.now(dt.UTC).timestamp())
    start = now - parse_window(window)
    outcome_filter = "" if include_noop else ",!outcome:no_resolution_needed"
    query = f"sum:mfs_file_save_merge_total{{env:{env}{outcome_filter}}} by {{outcome}}.as_count().rollup(sum, 3600)"
    payload = datadog_request(
        site,
        "GET",
        "/api/v1/query",
        params={"from": start, "to": now, "query": query},
    )
    if payload.get("status") != "ok":
        raise SystemExit(f"Datadog query failed: {payload}")
    totals: dict[str, float] = {outcome: 0 for outcome in OUTCOMES}
    for series in payload.get("series", []):
        scope = series.get("scope", "")
        match = re.search(r"outcome:([^,]+)", scope)
        outcome = match.group(1) if match else scope
        total = sum(point[1] or 0 for point in series.get("pointlist", []))
        totals[outcome] = total
    return totals


def markdown_bar(value: float, max_value: float, width: int = 24) -> str:
    if max_value <= 0 or value <= 0:
        return ""
    filled = max(1, round((value / max_value) * width))
    return "#" * filled


def print_metrics(args: argparse.Namespace) -> None:
    windows = [item.strip() for item in args.windows.split(",") if item.strip()]
    for window in windows:
        totals = query_metrics(args.datadog_site, args.env, window, args.include_noop)
        max_value = max(totals.values() or [0])
        print(f"\n## MFS save-merge outcomes ({args.env}, last {window})\n")
        print("| outcome | count | chart |")
        print("| --- | ---: | --- |")
        for outcome in OUTCOMES:
            if not args.include_noop and outcome == "no_resolution_needed":
                continue
            count = totals.get(outcome, 0)
            print(f"| `{outcome}` | {int(count) if float(count).is_integer() else count} | `{markdown_bar(count, max_value)}` |")


def datadog_log_search(site: str, env: str, window: str, limit: int) -> list[dict[str, Any]]:
    now = dt.datetime.now(dt.UTC)
    start = now - dt.timedelta(seconds=parse_window(window))
    body = {
        "filter": {
            "from": start.isoformat().replace("+00:00", "Z"),
            "to": now.isoformat().replace("+00:00", "Z"),
            "query": f'@env:{env} "mfs-file-save: succeeded" @branch:merge_overlap_resolved_with_conflict',
        },
        "sort": "timestamp",
        "page": {"limit": min(limit, 1000)},
    }
    payload = datadog_request(site, "POST", "/api/v2/logs/events/search", body=body)
    return payload.get("data", [])


def run_json(command: list[str]) -> Any:
    result = subprocess.run(command, check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return json.loads(result.stdout)


def psql_scalar(sql: str) -> str | None:
    url = os.environ.get("DRIZZLE_KIT_URL")
    if not url:
        return None
    result = subprocess.run(
        ["psql", url, "-At", "-c", sql],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        return None
    value = result.stdout.strip().splitlines()
    return value[0] if value else None


def resolve_workspace_id(repo_id: str) -> str | None:
    escaped_repo_id = repo_id.replace("'", "''")
    sql = f"select workspace_id from repo_v2 where repo_id = '{escaped_repo_id}' limit 1;"
    return psql_scalar(sql)


def find_ours_sha(file_id: str, merged_version: int) -> str | None:
    file_id_sql = file_id.replace("'", "''")
    for shard in ("mfs_shard_1", "mfs_shard_2"):
        sql = f"""
        select fc.content_hash
        from {shard}.mfs_file_changes fc
        join {shard}.mfs_commits c on c.id = fc.commit_id
        where fc.file_id = '{file_id_sql}'
          and fc.id < {int(merged_version)}
          and c.commit_message like '%PRE_MERGE%'
        order by fc.id desc
        limit 1;
        """
        value = psql_scalar(sql)
        if value:
            return value
    return None


def attr(log: dict[str, Any], key: str) -> Any:
    attrs = log.get("attributes", {})
    dd_attrs = attrs.get("attributes", {})
    return dd_attrs.get(key) or attrs.get(key)


def event_meta(log: dict[str, Any]) -> dict[str, Any]:
    merged_version = attr(log, "mfsVersion")
    return {
        "timestamp": log.get("attributes", {}).get("timestamp"),
        "datadogLogId": log.get("id"),
        "repoId": attr(log, "repoId"),
        "fileId": attr(log, "fileId"),
        "path": attr(log, "path"),
        "baseSha": attr(log, "baseSha"),
        "serverSha": attr(log, "serverSha"),
        "mergedSha": attr(log, "contentHash"),
        "mfsVersion": int(merged_version) if merged_version is not None else None,
        "branch": attr(log, "branch"),
    }


def s3_download(bucket: str, workspace_id: str, sha: str, target: Path) -> bool:
    key = f"s3://{bucket}/private/blobs/{workspace_id}/{sha}.dat"
    result = subprocess.run(["aws", "s3", "cp", key, str(target)], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return result.returncode == 0


def write_diff(left: Path, right: Path, out: Path) -> None:
    result = subprocess.run(["git", "diff", "--no-index", str(left), str(right)], text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    out.write_text(result.stdout, encoding="utf-8")


def export_overlaps(args: argparse.Namespace) -> None:
    logs = datadog_log_search(args.datadog_site, args.env, args.window, args.limit)
    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    rows: list[dict[str, Any]] = []
    bucket = args.bucket or os.environ.get("S3_BUCKET")

    for index, log in enumerate(logs, start=1):
        meta = event_meta(log)
        if args.resolve:
            if meta.get("repoId"):
                meta["workspaceId"] = resolve_workspace_id(str(meta["repoId"]))
            if meta.get("fileId") and meta.get("mfsVersion"):
                meta["oursSha"] = find_ours_sha(str(meta["fileId"]), int(meta["mfsVersion"]))
        rows.append(meta)

        safe_file = re.sub(r"[^A-Za-z0-9_.-]+", "_", str(meta.get("fileId") or f"event_{index}"))
        event_dir = out_dir / f"{index:03d}_{safe_file}_{meta.get('mfsVersion') or 'unknown'}"
        event_dir.mkdir(exist_ok=True)
        (event_dir / "meta.json").write_text(json.dumps(meta, indent=2, ensure_ascii=False), encoding="utf-8")

        if args.download_blobs:
            workspace_id = meta.get("workspaceId")
            if not bucket:
                raise SystemExit("--download-blobs requires --bucket or S3_BUCKET")
            if not workspace_id:
                print(f"Skipping blob download for {event_dir}: workspaceId unavailable", file=sys.stderr)
                continue
            mapping = {
                "base": meta.get("baseSha"),
                "ours": meta.get("oursSha"),
                "theirs": meta.get("serverSha"),
                "merged": meta.get("mergedSha"),
            }
            files: dict[str, Path] = {}
            for name, sha in mapping.items():
                if not sha:
                    continue
                target = event_dir / f"{name}.md"
                if s3_download(bucket, str(workspace_id), str(sha), target):
                    files[name] = target
            pairs = [
                ("base", "ours", "base_vs_ours.diff"),
                ("base", "theirs", "base_vs_theirs.diff"),
                ("ours", "merged", "ours_vs_merged.diff"),
                ("theirs", "merged", "theirs_vs_merged.diff"),
            ]
            for left, right, name in pairs:
                if left in files and right in files:
                    write_diff(files[left], files[right], event_dir / name)

    (out_dir / "events.json").write_text(json.dumps(rows, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Exported {len(rows)} overlap events to {out_dir}")
    print("\n| # | timestamp | repoId | fileId | path | base | ours | theirs | merged |")
    print("| ---: | --- | --- | --- | --- | --- | --- | --- | --- |")
    for idx, row in enumerate(rows, start=1):
        print(
            f"| {idx} | {row.get('timestamp') or ''} | {row.get('repoId') or ''} | {row.get('fileId') or ''} | "
            f"{row.get('path') or ''} | `{row.get('baseSha') or ''}` | `{row.get('oursSha') or ''}` | "
            f"`{row.get('serverSha') or ''}` | `{row.get('mergedSha') or ''}` |"
        )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--datadog-site", default=os.environ.get("DATADOG_SITE", "datadoghq.com"))
    sub = parser.add_subparsers(dest="command", required=True)

    metrics = sub.add_parser("metrics", help="Print 24h/7d outcome tables")
    metrics.add_argument("--env", default="online")
    metrics.add_argument("--windows", default="24h,7d")
    metrics.add_argument("--include-noop", action="store_true", default=True)
    metrics.add_argument("--exclude-noop", dest="include_noop", action="store_false")
    metrics.set_defaults(func=print_metrics)

    export = sub.add_parser("export-overlaps", help="Export overlap_resolved_with_conflict logs and optional blob diffs")
    export.add_argument("--env", default="online")
    export.add_argument("--window", default="24h")
    export.add_argument("--limit", type=int, default=100)
    export.add_argument("--out", required=True)
    export.add_argument("--resolve", action="store_true", default=True, help="Resolve workspaceId and PRE_MERGE oursSha via DB")
    export.add_argument("--no-resolve", dest="resolve", action="store_false")
    export.add_argument("--download-blobs", action="store_true")
    export.add_argument("--bucket")
    export.set_defaults(func=export_overlaps)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
