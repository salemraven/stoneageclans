#!/usr/bin/env python3
"""Search devblog + bible markdown for lore / design answers."""
from __future__ import annotations

import math
import re
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEVBLOG_DIR = ROOT / "devblog"
BIBLE_DIR = ROOT / "bible"

STOPWORDS = {
    "a", "an", "and", "are", "as", "at", "be", "by", "can", "do", "does", "for",
    "from", "how", "i", "in", "is", "it", "of", "on", "or", "that", "the", "their",
    "this", "to", "was", "what", "when", "where", "which", "who", "why", "with",
    "you", "your",
}
WEAK_TERMS = {"work", "like", "use", "get", "make", "need", "game", "play"}


@dataclass(frozen=True)
class LoreChunk:
    source: str  # devblog | bible
    rel_path: str
    section: str
    text: str
    weight: float

    @property
    def display_name(self) -> str:
        return Path(self.rel_path).name


@dataclass(frozen=True)
class LoreHit:
    chunk: LoreChunk
    score: float

    @property
    def excerpt(self) -> str:
        return _clean_excerpt(self.chunk.text)


def _tokenize(text: str) -> list[str]:
    words = re.findall(r"[a-z0-9]+", text.lower())
    return [w for w in words if len(w) > 1 and w not in STOPWORDS]


def _strip_md(text: str) -> str:
    text = re.sub(r"```[\s\S]*?```", " ", text)
    text = re.sub(r"`([^`]+)`", r"\1", text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"\1", text)
    text = re.sub(r"\*([^*]+)\*", r"\1", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    text = re.sub(r"^#+\s*", "", text, flags=re.MULTILINE)
    text = re.sub(r"^---\s*$", "", text, flags=re.MULTILINE)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def _clean_excerpt(text: str, max_len: int = 420) -> str:
    clean = _strip_md(text)
    if len(clean) <= max_len:
        return clean
    cut = clean[:max_len]
    last = max(cut.rfind(". "), cut.rfind("! "), cut.rfind("? "))
    if last > max_len // 3:
        return cut[: last + 1].strip()
    return cut.rstrip() + "…"


SKIP_PATH_SUFFIXES = {
    "readme.md",
    "console.md",
    "console2.md",
    "changelog.md",
    "charactermenu.md",
}
SKIP_PATH_PARTS = (
    "/archives/",
    "future implementations/",
)


def _should_skip_file(rel_path: str) -> bool:
    path = rel_path.replace("\\", "/").lower()
    name = Path(path).name
    if name in SKIP_PATH_SUFFIXES:
        return True
    return any(part in path for part in SKIP_PATH_PARTS)


def _is_log_dump(text: str) -> bool:
    if "Godot Engine v" in text and ("UnifiedLogger" in text or "Metal 3.2" in text):
        return True
    if text.count("[INFO]") >= 4 or text.count("✓ ") >= 6:
        return True
    return False


def _source_weight(rel_path: str, source: str) -> float:
    path = rel_path.replace("\\", "/").lower()
    if source == "devblog":
        return 1.4
    if path.endswith("bible.md") or path.endswith("main.md") or path.endswith("gdd.md"):
        return 1.3
    if path.endswith("game_dictionary.md") or path.endswith("qna.md"):
        return 1.2
    if "future implementations" in path:
        return 0.55
    if "/archives/" in path or path.startswith("archives/"):
        return 0.65
    if "/phase2/" in path and ("audit" in path or "report" in path):
        return 0.75
    return 1.0


def _iter_markdown_files() -> list[tuple[str, Path]]:
    files: list[tuple[str, Path]] = []
    if DEVBLOG_DIR.is_dir():
        for path in sorted(DEVBLOG_DIR.glob("*.md")):
            rel = path.relative_to(ROOT).as_posix()
            if _should_skip_file(rel):
                continue
            files.append(("devblog", path))
    if BIBLE_DIR.is_dir():
        for path in sorted(BIBLE_DIR.rglob("*.md")):
            rel = path.relative_to(ROOT).as_posix()
            if _should_skip_file(rel):
                continue
            files.append(("bible", path))
    return files


def _chunk_markdown(source: str, path: Path) -> list[LoreChunk]:
    rel = path.relative_to(ROOT).as_posix()
    weight = _source_weight(rel, source)
    raw = path.read_text(encoding="utf-8", errors="replace")
    lines = raw.splitlines()

    chunks: list[LoreChunk] = []
    section = Path(path).stem.replace("-", " ").replace("_", " ").title()
    body: list[str] = []

    def flush() -> None:
        nonlocal body, section
        text = "\n".join(body).strip()
        if len(_strip_md(text)) < 40 or _is_log_dump(text):
            body = []
            return
        chunks.append(LoreChunk(source, rel, section, text, weight))
        body = []

    for line in lines:
        if line.startswith("# "):
            section = _strip_md(line[2:].strip())
            flush()
            continue
        if line.startswith("## ") or line.startswith("### "):
            flush()
            section = _strip_md(re.sub(r"^#+\s+", "", line))
            continue
        if line.strip() == "---":
            continue
        body.append(line)

    flush()

    if not chunks and raw.strip() and not _is_log_dump(raw):
        chunks.append(
            LoreChunk(
                source,
                rel,
                section,
                raw,
                weight,
            )
        )
    return chunks


class LoreIndex:
    def __init__(self) -> None:
        self._chunks: list[LoreChunk] = []
        self._df: dict[str, int] = {}
        self._loaded = False

    def load(self) -> int:
        self._chunks = []
        self._df = {}
        for source, path in _iter_markdown_files():
            for chunk in _chunk_markdown(source, path):
                self._chunks.append(chunk)
                seen: set[str] = set()
                for token in set(_tokenize(chunk.text)) | set(_tokenize(chunk.section)):
                    if token in seen:
                        continue
                    seen.add(token)
                    self._df[token] = self._df.get(token, 0) + 1
        self._loaded = True
        return len(self._chunks)

    def search(self, query: str, limit: int = 3) -> list[LoreHit]:
        if not self._loaded:
            self.load()

        terms = _tokenize(query)
        if not terms:
            return []

        strong_terms = [t for t in terms if t not in WEAK_TERMS]
        total_docs = max(len(self._chunks), 1)
        hits: list[LoreHit] = []

        for chunk in self._chunks:
            text_tokens = _tokenize(chunk.text)
            title_tokens = _tokenize(chunk.section)
            if not text_tokens and not title_tokens:
                continue

            if strong_terms:
                has_strong = any(
                    t in text_tokens or t in title_tokens or t in Path(chunk.rel_path).stem.lower()
                    for t in strong_terms
                )
                if not has_strong:
                    continue

            score = 0.0
            for term in terms:
                in_text = text_tokens.count(term)
                in_title = title_tokens.count(term)
                if in_text == 0 and in_title == 0:
                    continue
                weight = 0.35 if term in WEAK_TERMS else 1.0
                df = self._df.get(term, 0)
                idf = math.log(1 + total_docs / max(df, 1))
                score += (in_text + in_title * 3) * idf * weight
                stem = Path(chunk.rel_path).stem.lower()
                if term in stem or term in chunk.section.lower():
                    score += 3.0

            if score <= 0:
                continue
            if chunk.source == "devblog":
                score *= 1.15
            hits.append(LoreHit(chunk, score * chunk.weight))

        hits.sort(key=lambda h: h.score, reverse=True)
        return _dedupe_hits(hits, limit)


def _dedupe_hits(hits: list[LoreHit], limit: int) -> list[LoreHit]:
    seen: set[tuple[str, str]] = set()
    out: list[LoreHit] = []
    for hit in hits:
        key = (hit.chunk.rel_path, hit.chunk.section.lower())
        if key in seen:
            continue
        seen.add(key)
        out.append(hit)
        if len(out) >= limit:
            break
    return out


def format_answer(query: str, hits: list[LoreHit], max_chars: int = 1900) -> str:
    if not hits:
        return (
            "I couldn't find anything about that in the devblog or design bible. "
            "Try shorter keywords — e.g. `animation`, `hunting`, `herding`, `multiplayer`."
        )

    lines = [f"Here's what I found for **{_strip_md(query)}**:\n"]
    used = len(lines[0])

    for i, hit in enumerate(hits, start=1):
        label = "Devblog" if hit.chunk.source == "devblog" else "Bible"
        block = (
            f"**{i}. {hit.chunk.section}**\n"
            f"_{label} · {hit.chunk.display_name}_\n"
            f"{hit.excerpt}"
        )
        if used + len(block) + 2 > max_chars:
            break
        lines.append(block)
        used += len(block) + 2

    return "\n\n".join(lines)


def cli_search(query: str, limit: int = 3) -> str:
    index = LoreIndex()
    index.load()
    hits = index.search(query, limit=limit)
    return format_answer(query, hits)


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: python3 tools/lore_search.py <query>")
        raise SystemExit(1)
    print(cli_search(" ".join(sys.argv[1:])))
