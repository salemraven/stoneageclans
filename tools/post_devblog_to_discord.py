#!/usr/bin/env python3
"""Post a devblog markdown file to Discord via webhook.

Requires env var DISCORD_DEVBLOG_WEBHOOK_URL (create in Discord:
Server Settings → Integrations → Webhooks → New Webhook).

Usage:
  python3 tools/post_devblog_to_discord.py devblog/animation-system.md
  python3 tools/post_devblog_to_discord.py devblog/animation-system.md --dry-run
  python3 tools/post_devblog_to_discord.py devblog/animation-system.md --repo-url https://github.com/salemraven/stoneageclans
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_REPO_URL = "https://github.com/salemraven/stoneageclans"
EMBED_DESC_MAX = 1800  # stay under 4096 with headroom for markdown
CONTENT_MAX = 1900


def _strip_md(text: str) -> str:
    text = re.sub(r"^#+\s*", "", text, flags=re.MULTILINE)
    text = re.sub(r"\*\*([^*]+)\*\*", r"\1", text)
    text = re.sub(r"\*([^*]+)\*", r"\1", text)
    text = re.sub(r"`([^`]+)`", r"\1", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    text = re.sub(r"^---\s*$", "", text, flags=re.MULTILINE)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def parse_devblog(path: Path) -> dict[str, str]:
    raw = path.read_text(encoding="utf-8")
    lines = raw.splitlines()
    title = "Stone Age Clans Devblog"
    for line in lines:
        if line.startswith("# "):
            title = line[2:].strip()
            break

    # First real paragraph: skip subtitle lines and horizontal rules.
    body_lines: list[str] = []
    started = False
    for line in lines:
        if line.startswith("# "):
            started = True
            continue
        if not started:
            continue
        stripped = line.strip()
        if stripped in ("", "---"):
            if body_lines:
                break
            continue
        if stripped.startswith("**") and "—" in stripped:
            continue  # e.g. **Title** — devblog, July 2026
        if line.startswith("#"):
            break
        body_lines.append(line)

    summary = _strip_md("\n".join(body_lines))
    if len(summary) > EMBED_DESC_MAX:
        summary = summary[: EMBED_DESC_MAX - 1].rstrip() + "…"

    slug = path.stem.replace("_", "-")
    return {"title": title, "summary": summary, "slug": slug, "filename": path.name}


def build_payload(
    meta: dict[str, str],
    repo_url: str,
    branch: str,
    rel_path: str,
) -> dict:
    file_url = f"{repo_url.rstrip('/')}/blob/{branch}/{rel_path}"
    raw_url = f"{repo_url.rstrip('/')}/raw/{branch}/{rel_path}"

    embed = {
        "title": meta["title"][:256],
        "description": meta["summary"],
        "url": file_url,
        "color": 0x8B5A2B,  # earthy brown — stone age vibe
        "footer": {"text": "Stone Age Clans · Devblog"},
        "fields": [
            {"name": "Read full post", "value": f"[GitHub]({file_url}) · [Raw markdown]({raw_url})", "inline": False},
        ],
    }

    content = f"📜 **New devblog:** {meta['title']}"
    if len(content) > CONTENT_MAX:
        content = content[: CONTENT_MAX]

    return {
        "username": "Stone Age Clans",
        "content": content,
        "embeds": [embed],
        "allowed_mentions": {"parse": []},
    }


def post_webhook(url: str, payload: dict) -> None:
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json", "User-Agent": "stoneageclans-devblog/1.0"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        if resp.status not in (200, 204):
            raise RuntimeError(f"Discord returned HTTP {resp.status}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Post a devblog to Discord.")
    parser.add_argument("markdown", type=Path, help="Path to devblog .md file")
    parser.add_argument("--repo-url", default=os.environ.get("DEVBLOG_REPO_URL", DEFAULT_REPO_URL))
    parser.add_argument("--branch", default=os.environ.get("DEVBLOG_BRANCH", "main"))
    parser.add_argument("--dry-run", action="store_true", help="Print payload, do not post")
    args = parser.parse_args()

    path = args.markdown if args.markdown.is_absolute() else ROOT / args.markdown
    if not path.is_file():
        print(f"File not found: {path}", file=sys.stderr)
        return 1

    rel_path = path.relative_to(ROOT).as_posix()
    meta = parse_devblog(path)
    payload = build_payload(meta, args.repo_url, args.branch, rel_path)

    if args.dry_run:
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        return 0

    webhook = os.environ.get("DISCORD_DEVBLOG_WEBHOOK_URL", "").strip()
    if not webhook:
        print(
            "Missing DISCORD_DEVBLOG_WEBHOOK_URL.\n"
            "Create a webhook in Discord (Server Settings → Integrations → Webhooks),\n"
            "then set the URL as a secret in your Cursor Cloud environment or shell.",
            file=sys.stderr,
        )
        return 1

    try:
        post_webhook(webhook, payload)
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        print(f"Discord error HTTP {e.code}: {body}", file=sys.stderr)
        return 1
    except urllib.error.URLError as e:
        print(f"Network error: {e}", file=sys.stderr)
        return 1

    print(f"Posted devblog: {meta['title']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
