#!/usr/bin/env python3
"""Post a devblog markdown file to Discord via webhook.

Builds a short, readable summary (not the full post). No GitHub links.

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
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SUMMARY_MAX = 1100
HOOK_MAX = 240
BULLET_MAX = 150
MAX_BULLETS = 5
CONTENT_MAX = 1900
SKIP_SECTIONS = {
    "try it yourself",
    "further reading",
    "further reading (repo)",
    "the character animation tuner",
}


def _strip_inline_md(text: str) -> str:
    text = re.sub(r"\*\*([^*]+)\*\*", r"\1", text)
    text = re.sub(r"\*([^*]+)\*", r"\1", text)
    text = re.sub(r"`([^`]+)`", r"\1", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    text = re.sub(r"\b(?:res://|assets/|scenes/|tools/|bible/)[\w./_*-]+\b", "", text)
    text = re.sub(r"\b[\w.-]+\.(?:md|tres|tscn|png|gd)\b", "", text)
    text = re.sub(r"  +", " ", text)
    return text.strip()


def _truncate_at_sentence(text: str, max_len: int) -> str:
    text = text.strip()
    if len(text) <= max_len:
        return text
    chunk = text[:max_len]
    last_period = max(chunk.rfind(". "), chunk.rfind("! "), chunk.rfind("? "))
    if last_period > max_len // 3:
        return chunk[: last_period + 1].strip()
    return chunk.rstrip() + "…"


def _first_sentence(text: str) -> str:
    text = _strip_inline_md(text)
    match = re.search(r"^(.+?[.!?])(?:\s|$)", text)
    return match.group(1).strip() if match else text


def _parse_title(lines: list[str]) -> str:
    for line in lines:
        if line.startswith("# "):
            return line[2:].strip()
    return "Stone Age Clans Devblog"


def _is_subtitle(line: str) -> bool:
    stripped = line.strip()
    return stripped.startswith("**") and "—" in stripped and "devblog" in stripped.lower()


def _parse_markdown(raw: str) -> tuple[list[str], dict[str, list[str]]]:
    lines = raw.splitlines()
    intro: list[str] = []
    sections: dict[str, list[str]] = {}
    current_heading: str | None = None
    in_code = False
    past_title = False

    for line in lines:
        if line.strip().startswith("```"):
            in_code = not in_code
            continue
        if in_code:
            continue

        if line.startswith("# "):
            past_title = True
            continue
        if not past_title:
            continue

        stripped = line.strip()
        if _is_further_reading(stripped):
            current_heading = None
            continue

        if line.startswith("## "):
            current_heading = _strip_inline_md(line[3:].strip())
            sections.setdefault(current_heading, [])
            continue

        if stripped in ("", "---") or _is_subtitle(line):
            continue
        if current_heading is None:
            if stripped and not stripped.startswith("#"):
                intro.append(stripped)
        elif not stripped.startswith("#"):
            sections[current_heading].append(stripped)

    return intro, sections


def _is_further_reading(line: str) -> bool:
    lowered = _strip_inline_md(line).lower().rstrip(":")
    return lowered in SKIP_SECTIONS or lowered.startswith("further reading")


def _prose_sentences(lines: list[str]) -> list[str]:
    chunks: list[str] = []
    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("|") or stripped.startswith("- "):
            continue
        if re.match(r"^\d+\.\s+", stripped):
            continue
        chunks.append(_strip_inline_md(stripped))
    text = " ".join(chunks)
    return [s.strip() for s in re.split(r"(?<=[.!?])\s+", text) if s.strip()]


def _match_section(heading: str, keywords: tuple[str, ...]) -> bool:
    lowered = heading.lower()
    return any(word in lowered for word in keywords)


def _section_bullet(heading: str, lines: list[str]) -> str:
    canned = {
        "old problem": "Sprite sheets don't scale — every weapon, direction, and body type multiplies the art burden.",
        "new approach": "Card body + weapon overlay + procedural IK arms — one image, poses driven by data.",
        "see in-game": "Procedural walk bounce, arm sway, and combat — Shift to ready, click to strike.",
        "scales": "New body types need preset tuning, not new walk-cycle art.",
        "multiplayer": "Arm poses sync from game state, not frame-by-frame animation — less bandwidth, fewer desyncs.",
        "where this": "Next up: textured limbs, more body cards, and richer ritual animation on the same preset pipeline.",
        "bottom line": "",
    }

    for key, text in canned.items():
        if _match_section(heading, (key,)):
            if text:
                return text
            sentences = _prose_sentences(lines)
            return _truncate_at_sentence(sentences[0] if sentences else heading, BULLET_MAX)

    sentences = _prose_sentences(lines)
    if sentences:
        return _truncate_at_sentence(sentences[0], BULLET_MAX)
    return _truncate_at_sentence(heading, BULLET_MAX)


SECTION_PRIORITY = (
    ("old problem",),
    ("new approach",),
    ("see in-game", "in-game"),
    ("scales", "body styles"),
    ("multiplayer",),
)


def build_short_summary(raw: str) -> str:
    intro, sections = _parse_markdown(raw)

    hook_parts: list[str] = []
    for para in intro:
        clean = _strip_inline_md(para)
        if clean and "this post explains" not in clean.lower():
            hook_parts.append(clean)
        if len(" ".join(hook_parts)) >= HOOK_MAX or len(hook_parts) >= 2:
            break

    hook = _truncate_at_sentence(" ".join(hook_parts), HOOK_MAX)

    bullets: list[str] = []
    bottom_line: str | None = None

    for heading, lines in sections.items():
        if heading.lower() in SKIP_SECTIONS:
            continue
        if _match_section(heading, ("bottom line",)):
            bottom_line = _section_bullet(heading, lines)
            continue

    for keywords in SECTION_PRIORITY:
        for heading, lines in sections.items():
            if heading.lower() in SKIP_SECTIONS or _match_section(heading, ("bottom line",)):
                continue
            if _match_section(heading, keywords):
                bullet = _section_bullet(heading, lines)
                if bullet and bullet not in bullets:
                    bullets.append(bullet)
                break

    parts = [hook, ""]
    parts.extend(f"• {b}" for b in bullets if b)
    if bottom_line and bottom_line not in bullets:
        parts.extend(["", f"_{bottom_line}_"])

    summary = "\n".join(parts).strip()
    if len(summary) > SUMMARY_MAX:
        summary = _truncate_at_sentence(summary, SUMMARY_MAX)

    return summary


def parse_devblog(path: Path) -> dict[str, str]:
    raw = path.read_text(encoding="utf-8")
    title = _parse_title(raw.splitlines())
    summary = build_short_summary(raw)
    return {"title": title, "summary": summary, "filename": path.name}


def build_payload(meta: dict[str, str]) -> dict:
    content = f"📜 **New devblog:** {meta['title']}"
    if len(content) > CONTENT_MAX:
        content = content[:CONTENT_MAX]

    return {
        "username": "Stone Age Clans",
        "content": content,
        "embeds": [
            {
                "title": meta["title"][:256],
                "description": meta["summary"],
                "color": 0x8B5A2B,
                "footer": {"text": "Stone Age Clans · Devblog"},
            }
        ],
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
    parser = argparse.ArgumentParser(description="Post a short devblog summary to Discord.")
    parser.add_argument("markdown", type=Path, help="Path to devblog .md file")
    parser.add_argument("--dry-run", action="store_true", help="Print payload, do not post")
    args = parser.parse_args()

    path = args.markdown if args.markdown.is_absolute() else ROOT / args.markdown
    if not path.is_file():
        print(f"File not found: {path}", file=sys.stderr)
        return 1

    meta = parse_devblog(path)
    payload = build_payload(meta)

    if args.dry_run:
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        print(f"\nSummary length: {len(meta['summary'])} chars")
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

    print(f"Posted devblog summary: {meta['title']} ({len(meta['summary'])} chars)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
