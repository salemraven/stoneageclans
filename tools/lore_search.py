#!/usr/bin/env python3
"""Search devblog + bible markdown for lore / design answers."""
from __future__ import annotations

import math
import os
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

PLAY_URL = os.environ.get("DISCORD_LORE_PLAY_URL", "").strip()
PLAY_LINK_UNAVAILABLE = (
    "Stone Age Clans isn't publicly downloadable yet — we're still in development. "
    "Follow devblog updates in Discord for when a build is available."
)

_PLAY_LINK_PATTERNS = (
    re.compile(r"\b(where|how)\s+(can|do)\s+i\s+(play|download|get|try)\b", re.I),
    re.compile(r"\b(can|may)\s+i\s+(play|download|get|try)\b", re.I),
    re.compile(r"\b(play|download|get|try)\s+(the\s+)?game\b", re.I),
    re.compile(r"\blink\s+to\s+play\b", re.I),
    re.compile(r"\bsend\s+(me\s+)?(a\s+)?link\b", re.I),
    re.compile(r"\bplayable\s+(build|demo|version|link)\b", re.I),
    re.compile(r"\b(itch\.io|steam)\b", re.I),
)


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


def is_play_link_question(query: str) -> bool:
    q = query.strip()
    if not q:
        return False
    if any(pattern.search(q) for pattern in _PLAY_LINK_PATTERNS):
        return True
    q_l = q.lower()
    mentions_game = any(
        phrase in q_l
        for phrase in ("stone age clans", "stoneageclans", "this game", "the game")
    )
    return mentions_game and any(word in q_l for word in ("play", "download", "link", "try", "demo"))


def play_link_answer() -> str:
    if PLAY_URL:
        return f"You can play Stone Age Clans here: {PLAY_URL}"
    return PLAY_LINK_UNAVAILABLE


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


_TECH_LINE_PATTERNS = (
    re.compile(r"^-\s*\[[ xX]\]"),
    re.compile(r"^\|"),
    re.compile(r"res://"),
    re.compile(r"scripts/"),
    re.compile(r"\.gd\b"),
    re.compile(r"^#{1,6}\s"),
    re.compile(r"^Part [A-Z]\b", re.I),
    re.compile(r"^Phase \d", re.I),
    re.compile(r"Implement after", re.I),
    re.compile(r"Follow .+ implementation", re.I),
    re.compile(r"^Location:\s*", re.I),
    re.compile(r"^Status:\s*", re.I),
    re.compile(r"^Last Updated:\s*", re.I),
    re.compile(r"^Hub:\s*", re.I),
    re.compile(r"^Related:\s*", re.I),
)


def _is_technical_line(line: str) -> bool:
    stripped = line.strip()
    if not stripped:
        return True
    if any(pattern.search(stripped) for pattern in _TECH_LINE_PATTERNS):
        return True
    if stripped.count("|") >= 2:
        return True
    if stripped.count("`") >= 2:
        return True
    if re.search(r"\b(refactor|checklist|audit report|test findings|not implemented)\b", stripped, re.I):
        return True
    return False


def _technical_density(text: str) -> float:
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    if not lines:
        return 1.0
    bad = sum(1 for line in lines if _is_technical_line(line))
    return bad / len(lines)


def _section_kind_bonus(section: str, rel_path: str, query: str = "") -> float:
    section_l = section.lower()
    path_l = rel_path.replace("\\", "/").lower()
    query_l = query.lower()
    bonus = 1.0
    if any(word in section_l for word in ("overview", "summary", "introduction", "about", "what is", "principle")):
        bonus *= 1.45
    if any(word in section_l for word in ("phase", "part a", "part b", "part c", "checklist", "audit", "report", "test", "conflict", "integration")):
        bonus *= 0.55
    if "flow" in section_l and any(q in query_l for q in ("what is", "what's", "who is", "tell me about")):
        bonus *= 0.45
    if any(word in path_l for word in ("/phase", "audit", "report", "checklist", "ultimate_", "_test")):
        bonus *= 0.45
    if path_l.endswith("qna.md") or path_l.endswith("game_dictionary.md"):
        bonus *= 1.2
    return bonus


def _sentence_score(sentence: str, terms: list[str], hit: LoreHit) -> float:
    sentence_l = sentence.lower()
    score = 0.0
    for term in terms:
        if term in sentence_l:
            score += 2.5 if term not in WEAK_TERMS else 0.75
    if 40 <= len(sentence) <= 220:
        score += 1.5
    elif len(sentence) < 22:
        score -= 2.0
    if len(sentence) > 260:
        score -= 1.5
    if _technical_density(sentence) > 0.2:
        score -= 4.0
    if re.search(r"\b(is|are|means|lets you|runs|handles|controls|decides|think of)\b", sentence_l):
        score += 1.5
    if re.search(r"\b(implementation|refactor|quota|ratio|meta\(|fsm|self-assign|drag clansmen|option a|pros:|cons:)\b", sentence_l):
        score -= 3.0
    if re.search(r"^(question|setup|expected|stimulus|goal|notes?)\s*:", sentence_l):
        score -= 5.0
    if re.search(r"\b(devblog|last updated|status:|july \d{4})\b", sentence_l):
        score -= 2.0
    if re.search(r"\b\d+\s+(stone|wood|food)\b", sentence_l):
        score -= 2.5
    if re.search(r"\bn/\d+\b", sentence_l):
        score -= 2.5
    section_l = hit.chunk.section.lower()
    if any(word in section_l for word in ("overview", "summary", "introduction")):
        score += 2.5
    if hit.chunk.source == "devblog":
        score += 1.0
    score += hit.score * 0.05
    return score


def _extract_section_intro(hit: LoreHit) -> str | None:
    parts: list[str] = []
    for line in hit.chunk.text.splitlines():
        stripped = line.strip()
        if not stripped:
            if parts:
                break
            continue
        if stripped.startswith("- ") or stripped.startswith("|") or stripped[0].isdigit():
            break
        if _is_technical_line(stripped):
            continue
        cleaned = _strip_md(stripped)
        if cleaned.endswith(":"):
            cleaned = cleaned[:-1].strip()
        if cleaned:
            parts.append(cleaned)
    if not parts:
        return None
    intro = " ".join(parts)
    first = re.split(r"(?<=[.!?])\s+", intro)[0].strip()
    if len(first) >= 20 and not _is_technical_line(first):
        return first
    return None


def _extract_readable_sentences(hit: LoreHit, terms: list[str]) -> list[tuple[float, str]]:
    prose_parts: list[str] = []
    for line in hit.chunk.text.splitlines():
        stripped = line.strip()
        if not stripped or _is_technical_line(stripped):
            continue
        if stripped.startswith("- "):
            stripped = stripped[2:].strip()
        elif re.match(r"^\d+\.\s+", stripped):
            stripped = re.sub(r"^\d+\.\s+", "", stripped)
        cleaned = _strip_md(stripped)
        if len(cleaned) >= 20:
            prose_parts.append(cleaned)

    prose = " ".join(prose_parts)
    if not prose:
        return []

    sentences = re.split(r"(?<=[.!?])\s+", prose)
    scored: list[tuple[float, str]] = []
    for sentence in sentences:
        sentence = sentence.strip(" -*•")
        if len(sentence) < 25:
            continue
        if _is_technical_line(sentence):
            continue
        score = _sentence_score(sentence, terms, hit)
        if score > 0:
            scored.append((score, sentence))
    return scored


def _topic_label(query: str, hits: list[LoreHit]) -> str:
    cleaned = _strip_md(query)
    cleaned = re.sub(r"^(what(?:'s| is)|who(?:'s| is)|tell me about)\s+", "", cleaned, flags=re.I)
    cleaned = re.sub(r"^how does\s+", "", cleaned, flags=re.I)
    cleaned = re.sub(r"\s+work$", "", cleaned, flags=re.I)
    cleaned = re.sub(r"\?$", "", cleaned).strip()
    if cleaned:
        return cleaned
    if hits:
        return hits[0].chunk.section
    return "that"


def _polish_definition(
    topic: str,
    lead: str,
    support: str | None = None,
    *,
    define: bool = False,
) -> str:
    lead_clean = lead.rstrip(". ").strip()
    lead_l = lead_clean.lower()
    topic_l = topic.lower()

    if "clan brain" in topic_l:
        return (
            "Clan brain is the AI that runs NPC clans. "
            "It watches food and danger, assigns defenders and workers, "
            "and can send raiders or hunters when the clan is ready — without you micromanaging everyone."
        )
    if "nomad mode" in topic_l:
        return (
            "Nomad mode is when your clan packs up the campfire and moves to a new spot without disbanding. "
            "Everyone marches together, you place a new fire, and the clan keeps its name and people."
        )
    if "herding" in topic_l or topic_l in {"herd", "herd wild npcs", "herd wild npc"}:
        return (
            "Herding is how you bring wild people and animals into your clan. "
            "You walk near them, build influence, and they start following you back to camp."
        )

    if " is " in lead_l or lead_l.startswith(topic_l):
        answer = lead_clean + "."
    elif define:
        answer = f"{topic.capitalize()} is {lead_clean[0].lower()}{lead_clean[1:]}."
    else:
        answer = lead_clean + "."

    if support:
        support_clean = support.rstrip(". ").strip()
        if (
            support_clean.lower() not in answer.lower()
            and not _is_technical_line(support_clean)
            and len(support_clean) <= 220
            and _technical_density(support_clean) < 0.2
        ):
            answer = f"{answer} {support_clean}."
    return answer


def _opening_line(query: str) -> str | None:
    q = query.lower().strip(" ?!.")
    if re.match(r"what(?:'s| is)\b", q):
        return None
    if q.startswith("how"):
        return "Good question — here's the simple version:"
    if q.startswith("why"):
        return "Short answer:"
    if q.startswith("who"):
        return None
    if q.startswith("tell me about"):
        return None
    return None


def _synthesize_answer(query: str, hits: list[LoreHit], max_chars: int = 900) -> str:
    terms = _tokenize(query)
    primary_hits = [hits[0]] + [hit for hit in hits[1:] if hit.chunk.rel_path == hits[0].chunk.rel_path]
    ranked: list[tuple[float, str]] = []
    seen: set[str] = set()

    for hit in primary_hits:
        intro = _extract_section_intro(hit)
        if intro:
            key = re.sub(r"\W+", " ", intro.lower()).strip()[:100]
            if key not in seen:
                seen.add(key)
                ranked.append((_sentence_score(intro, terms, hit) + 4.0, intro))
        for score, sentence in _extract_readable_sentences(hit, terms):
            key = re.sub(r"\W+", " ", sentence.lower()).strip()[:100]
            if key in seen:
                continue
            seen.add(key)
            ranked.append((score, sentence))

    ranked.sort(key=lambda item: item[0], reverse=True)
    lead = ranked[0][1] if ranked else ""
    support = ranked[1][1] if len(ranked) > 1 else None

    if not lead and hits:
        lead = _clean_excerpt(hits[0].chunk.text, max_len=280)
        lead = re.sub(r"\s+", " ", lead).strip()

    if not lead:
        return (
            "Hmm, I know the topic is in our notes somewhere, but I can't explain it plainly from "
            "what I have. Try asking with simpler words — like `hunting`, `herding`, or `nomad mode`."
        )

    topic = _topic_label(query, hits)
    opener = _opening_line(query)
    q = query.lower().strip(" ?!.")
    define = bool(
        re.match(r"what(?:'s| is)\b", q)
        or q.startswith("tell me about")
        or q.startswith("who")
    )
    body = _polish_definition(topic, lead, support, define=define)
    if opener:
        answer = f"{opener} {body}"
    else:
        answer = body

    answer = re.sub(r"\s+", " ", answer).strip()
    answer = re.sub(r"\.{2,}", ".", answer)
    if len(answer) > max_chars:
        answer = answer[: max_chars - 1].rstrip(" ,;") + "…"
    return answer


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
            score *= _section_kind_bonus(chunk.section, chunk.rel_path, query)
            density = _technical_density(chunk.text)
            if density > 0.45:
                score *= max(0.35, 1.0 - density)
            stem = Path(chunk.rel_path).stem.lower().replace("-", " ").replace("_", " ")
            if strong_terms and all(term in stem for term in strong_terms[:2]):
                score *= 1.8
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


def format_answer(query: str, hits: list[LoreHit], max_chars: int = 900) -> str:
    if is_play_link_question(query):
        return play_link_answer()

    if not hits:
        return (
            "I don't have a good plain-language answer for that in the devblog or design bible. "
            "Try shorter keywords — like `hunting`, `herding`, `nomad mode`, or `multiplayer`."
        )

    return _synthesize_answer(query, hits, max_chars=max_chars)


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
