#!/usr/bin/env python3
"""Post a devblog markdown file to Discord via webhook.

Converts the markdown into a readable summary and posts it on Discord.
No GitHub links — the Discord post *is* the devblog.

Requires env var DISCORD_DEVBLOG_WEBHOOK_URL (create in Discord:
Server Settings → Integrations → Webhooks → New Webhook).

Usage:
  python3 tools/post_devblog_to_discord.py devblog/animation-system.md
  python3 tools/post_devblog_to_discord.py devblog/animation-system.md --dry-run
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EMBED_DESC_MAX = 3900  # Discord hard limit is 4096
EMBED_TOTAL_MAX = 5800  # Discord total across all embeds in one message
CONTENT_MAX = 1900
SKIP_SECTIONS = {
    "try it yourself",
    "further reading",
    "further reading (repo)",
}


def _strip_inline_md(text: str) -> str:
    text = re.sub(r"\*\*([^*]+)\*\*", r"\1", text)
    text = re.sub(r"\*([^*]+)\*", r"\1", text)
    text = re.sub(r"`([^`]+)`", r"\1", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    text = re.sub(r"\([^)]*[/\\][^)]*\)", "", text)
    text = re.sub(r"\b(?:res://|assets/|scenes/|tools/|bible/)[\w./_*-]+\b", "", text)
    text = re.sub(r"\b[\w.-]+\.(?:md|tres|tscn|png|gd)\b", "", text)
    text = re.sub(r"\(\s*\)", "", text)
    text = re.sub(r":\s*,", ",", text)
    text = re.sub(r":\s*$", "", text)
    text = re.sub(r"  +", " ", text)
    return text.strip()


def _parse_title(lines: list[str]) -> str:
    for line in lines:
        if line.startswith("# "):
            return line[2:].strip()
    return "Stone Age Clans Devblog"


def _heading_level(line: str) -> int | None:
    match = re.match(r"^(#{1,6})\s+(.+)$", line)
    if not match:
        return None
    return len(match.group(1))


def _heading_text(line: str) -> str:
    match = re.match(r"^#{1,6}\s+(.+)$", line)
    return _strip_inline_md(match.group(1).strip()) if match else line


def _should_skip_section(heading: str) -> bool:
    return heading.strip().lower() in SKIP_SECTIONS


def _is_subtitle(line: str) -> bool:
    stripped = line.strip()
    return stripped.startswith("**") and "—" in stripped and "devblog" in stripped.lower()


def _is_further_reading(line: str) -> bool:
    lowered = _strip_inline_md(line).lower().rstrip(":")
    return lowered in SKIP_SECTIONS or lowered.startswith("further reading")


def markdown_to_discord_summary(raw: str) -> str:
    """Turn devblog markdown into plain Discord-friendly text."""
    lines = raw.splitlines()
    out: list[str] = []
    in_code = False
    in_table = False
    skip_section = False
    title_seen = False
    past_intro = False

    for line in lines:
        if line.strip().startswith("```"):
            in_code = not in_code
            continue

        if in_code:
            continue

        level = _heading_level(line)
        if level == 1:
            title_seen = True
            continue

        if not title_seen:
            continue

        if not past_intro:
            if _is_subtitle(line) or line.strip() in ("", "---"):
                continue
            if level == 2:
                past_intro = True
            elif line.strip():
                # Intro paragraphs before the first ## section.
                out.append(_strip_inline_md(line.strip()))
                continue
            else:
                continue

        if line.strip() == "---":
            if out and out[-1] != "":
                out.append("")
            continue

        if level is not None:
            heading = _heading_text(line)
            skip_section = _should_skip_section(heading)
            if skip_section:
                in_table = False
                continue
            if out and out[-1] != "":
                out.append("")
            if level == 2:
                out.append(f"**{heading}**")
            else:
                out.append(f"__{heading}__")
            in_table = False
            continue

        if skip_section:
            continue

        stripped = line.strip()
        if not stripped:
            if out and out[-1] != "":
                out.append("")
            in_table = False
            continue

        if _is_further_reading(stripped):
            skip_section = True
            continue

        if stripped.startswith("|") and stripped.endswith("|"):
            cells = [c.strip() for c in stripped.strip("|").split("|")]
            if all(set(c) <= {"-", ":", " "} for c in cells):
                in_table = True
                continue
            if len(cells) >= 2 and cells[0].lower() not in ("layer", "mode", "post", "topic"):
                left = _strip_inline_md(cells[0])
                right = _strip_inline_md(cells[-1])
                if left and right and left != right:
                    out.append(f"  • {left} — {right}")
                elif left:
                    out.append(f"  • {left}")
            in_table = True
            continue

        in_table = False
        if stripped.startswith("- "):
            out.append(f"  • {_strip_inline_md(stripped[2:])}")
            continue

        numbered = re.match(r"^(\d+)\.\s+(.+)$", stripped)
        if numbered:
            out.append(f"  {numbered.group(1)}. {_strip_inline_md(numbered.group(2))}")
            continue

        out.append(_strip_inline_md(stripped))

    text = "\n".join(out)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return _polish_summary(text.strip())


def _polish_summary(text: str) -> str:
    fixes = [
        (r"Godot:\s*\(([^)]+)\)", r"Godot \1"),
        (r"Web preview:\s*/\s*—", "We also built a web preview tuner —"),
        (r"  • \+ stacked at a neck socket", "  • Body + head layers stacked at a neck socket"),
        (r"loads the new \.tres automatically", "loads the new preset automatically"),
        (r"read the same files\.", "read the same preset data."),
        (r":\s*—", " —"),
    ]
    for pattern, repl in fixes:
        text = re.sub(pattern, repl, text)
    return text


def chunk_text(text: str, max_len: int = EMBED_DESC_MAX) -> list[str]:
    if len(text) <= max_len:
        return [text]

    chunks: list[str] = []
    paragraphs = text.split("\n\n")
    current = ""

    for para in paragraphs:
        candidate = f"{current}\n\n{para}".strip() if current else para
        if len(candidate) <= max_len:
            current = candidate
            continue

        if current:
            chunks.append(current)
            current = ""

        if len(para) <= max_len:
            current = para
            continue

        for i in range(0, len(para), max_len):
            chunks.append(para[i : i + max_len])

    if current:
        chunks.append(current)

    return chunks


def parse_devblog(path: Path) -> dict[str, str]:
    raw = path.read_text(encoding="utf-8")
    title = _parse_title(raw.splitlines())
    summary = markdown_to_discord_summary(raw)
    return {"title": title, "summary": summary, "filename": path.name}


def build_message_payloads(meta: dict[str, str]) -> list[dict]:
    chunks = chunk_text(meta["summary"])
    payloads: list[dict] = []
    total_parts = len(chunks)

    offset = 0
    while offset < total_parts:
        embeds: list[dict] = []
        used = 0
        part_start = offset

        while offset < total_parts and len(embeds) < 10:
            chunk = chunks[offset]
            chunk_len = len(chunk)
            if embeds and used + chunk_len > EMBED_TOTAL_MAX:
                break

            embed: dict = {
                "description": chunk,
                "color": 0x8B5A2B,
            }
            if offset == 0:
                embed["title"] = meta["title"][:256]
                embed["footer"] = {"text": "Stone Age Clans · Devblog"}
            elif total_parts > 1:
                embed["footer"] = {"text": f"Stone Age Clans · Devblog ({offset + 1}/{total_parts})"}

            embeds.append(embed)
            used += chunk_len
            offset += 1

        content = ""
        if part_start == 0:
            content = f"📜 **New devblog:** {meta['title']}"
            if total_parts > 1:
                content += f" _(part 1/{total_parts})_"
        else:
            content = f"📜 **Devblog continued** _(part {part_start + 1}/{total_parts})_"

        if len(content) > CONTENT_MAX:
            content = content[:CONTENT_MAX]

        payloads.append(
            {
                "username": "Stone Age Clans",
                "content": content,
                "embeds": embeds,
                "allowed_mentions": {"parse": []},
            }
        )

    return payloads


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
    parser = argparse.ArgumentParser(description="Post a devblog summary to Discord.")
    parser.add_argument("markdown", type=Path, help="Path to devblog .md file")
    parser.add_argument("--dry-run", action="store_true", help="Print payload, do not post")
    args = parser.parse_args()

    path = args.markdown if args.markdown.is_absolute() else ROOT / args.markdown
    if not path.is_file():
        print(f"File not found: {path}", file=sys.stderr)
        return 1

    meta = parse_devblog(path)
    payloads = build_message_payloads(meta)

    if args.dry_run:
        print(json.dumps(payloads, indent=2, ensure_ascii=False))
        print(f"\nSummary length: {len(meta['summary'])} chars in {len(payloads)} message(s)")
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
        for i, payload in enumerate(payloads):
            if i > 0:
                time.sleep(0.5)
            post_webhook(webhook, payload)
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        print(f"Discord error HTTP {e.code}: {body}", file=sys.stderr)
        return 1
    except urllib.error.URLError as e:
        print(f"Network error: {e}", file=sys.stderr)
        return 1

    parts = f" ({len(payloads)} messages)" if len(payloads) > 1 else ""
    print(f"Posted devblog: {meta['title']}{parts}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
