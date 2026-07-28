#!/usr/bin/env python3
"""Turn user questions into friendly Discord answers (pitch, glossary, search)."""
from __future__ import annotations

import re

from lore_search import LoreHit, LoreIndex, _strip_md, format_answer

# Player-facing pitch — Zedu promotes the game, not internal dev notes.
GAME_PITCH = """**Stone Age Clans: The Dawn of Aggro-Culture**

*RimWorld colony drama meets stone-age survival* — top-down, gritty pixel art, brutal wilderness.

You lead a clan through **generations**: hunt prey, **herd** wild women and livestock home, craft bread and weapons, defend your **land claim**, and raid rivals. One bad winter, one raid gone wrong, and your bloodline can end. **Permadeath** is real.

**What makes it tick:**
• Systems that collide — drought, predators, rival clans, starvation — so stories emerge
• **War Horn** rallies — lead war parties in RTS-style PEACE / AGRO / HUNT modes
• Production chains: farms, bakeries, armories — drag-and-drop everything
• Clan AI that sets *intent* (defend, hunt, raid) and lets NPCs choose jobs — not puppet strings

Pure sandbox. No fake victory screen. Dominate the map or die trying.

Ask me about **hunting**, **herding**, **nomad mode**, **raiding**, or our new **animation system** — I've read the scrolls."""


# Plain-English glosses for jargon players hit in docs.
GLOSSARY: dict[str, str] = {
    "pull based": (
        "**Pull-based** means NPCs *choose* work instead of the clan AI shoving orders at everyone every frame. "
        "ClanBrain posts intent — \"we need defenders,\" \"raid that camp,\" \"hunt deer\" — and fighters "
        "*volunteer* for those jobs. Feels more natural, scales better, and herds/raids break under stress instead of "
        "looking scripted."
    ),
    "pull-based": (
        "**Pull-based** means NPCs *choose* work instead of the clan AI shoving orders at everyone every frame. "
        "ClanBrain posts intent — \"we need defenders,\" \"raid that camp,\" \"hunt deer\" — and fighters "
        "*volunteer* for those jobs. Feels more natural, scales better, and herds/raids break under stress instead of "
        "looking scripted."
    ),
    "push based": (
        "**Push-based** (the old way) is the opposite: the AI assigns every NPC directly. "
        "We moved to **pull-based** so clans feel alive and performance stays sane."
    ),
    "clanbrain": (
        "**ClanBrain** is the strategic mind behind each clan's territory. It watches food stores, threats, and prey, "
        "then sets **intent** — how many defenders, searchers, hunters, raiders — and NPCs pull jobs from that. "
        "It's why raids and hunts feel intentional, not random."
    ),
    "herd": (
        "**Herding** is how you recruit wild **women**, **sheep**, and **goats**: right-click to herd, lead them to your "
        "**land claim**, and they join the clan. Different from **party follow** — that's your war band marching with you."
    ),
    "herding": (
        "**Herding** is how you recruit wild **women**, **sheep**, and **goats**: right-click to herd, lead them to your "
        "**land claim**, and they join the clan. Different from **party follow** — that's your war band marching with you."
    ),
    "nomad mode": (
        "**Nomad Mode** lets you **move camp** without disbanding. Abandon your campfire, march the whole clan, "
        "and settle a new land claim — pregnancies pause, herded animals may scatter, old huts decay. "
        "For clans that follow the herds, not the other way around."
    ),
    "aoe": (
        "In this project **AoH** usually means **Area of Hunt** — the ring around your claim where the clan counts prey "
        "like deer and mammoth for hunting parties. (Not to be confused with spell \"area of effect.\")"
    ),
    "aoh": (
        "**Area of Hunt (AoH)** — the ring outside your land claim where prey is counted. When there's food worth chasing, "
        "ClanBrain raises **hunt intent** and hunters go out."
    ),
}

FILLER_RE = re.compile(
    r"^(?:"
    r"hey[, ]*|"
    r"hi[, ]*|"
    r"please[, ]*|"
    r"can you[, ]*|"
    r"tell me about[, ]*|"
    r"tell me[, ]*|"
    r"what is[, ]*|"
    r"what's[, ]*|"
    r"what are[, ]*|"
    r"explain[, ]*|"
    r"describe[, ]*|"
    r"give me (?:a )?pitch[, ]*|"
    r"pitch[, ]*|"
    r"about[, ]*"
    r")+",
    re.IGNORECASE,
)

GAME_PITCH_TRIGGERS = (
    "pitch",
    "sell me",
    "what is this",
    "about the game",
    "about stone age",
    "stone age clans",
    "tell me about",
    "what is stone",
    "whats stone",
    "introduce",
    "overview",
    "describe the game",
)


def normalize_query(raw: str) -> str:
    text = _strip_md(raw)
    text = re.sub(r"<@!?\d+>", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    text = FILLER_RE.sub("", text).strip()
    text = re.sub(r"^(?:the )?game\s*", "", text, flags=re.IGNORECASE).strip()
    return text or raw.strip()


def _extract_define_term(query: str) -> str | None:
    q = query.lower().strip().rstrip("?!. ")
    match = re.search(r"what does (.+?) mean$", q)
    if match:
        return match.group(1).strip()
    match = re.search(r"what is (?:a |an |the )?(.+)$", q)
    if match and len(match.group(1).split()) <= 5:
        return match.group(1).strip()
    if q.startswith("define "):
        return q[7:].strip()
    return None


def wants_pitch(raw: str, normalized: str) -> bool:
    blob = f"{raw} {normalized}".lower()
    if any(t in blob for t in GAME_PITCH_TRIGGERS):
        return True
    if normalized.lower() in ("", "game", "it", "this"):
        return "pitch" in raw.lower() or "game" in raw.lower()
    return False


def glossary_answer(term: str) -> str | None:
    key = term.lower().strip()
    if key in GLOSSARY:
        return GLOSSARY[key]
    # Try without hyphens / extra spaces
    compact = re.sub(r"[\s-]+", " ", key)
    for k, v in GLOSSARY.items():
        if k.replace("-", " ") == compact:
            return v
    return None


def _format_search_answer(query: str, hits: list[LoreHit], max_chars: int = 1900) -> str:
    if not hits:
        return (
            "Hmm — nothing in the scrolls about that. Try keywords like "
            "`hunting`, `herding`, `raiding`, `nomad`, or `animation`.\n\n"
            "Or ask: *what is Stone Age Clans?* for the full pitch."
        )

    topic = normalize_query(query)
    if len(topic) < 4 or topic.lower() == query.lower():
        topic = "that"

    lines = [f"From the lore scrolls on **{topic}**:\n"]
    used = len(lines[0])

    for hit in hits[:3]:
        label = "Devblog" if hit.chunk.source == "devblog" else "Design notes"
        block = f"**{hit.chunk.section}** — _{label}_\n{hit.excerpt}"
        if used + len(block) + 2 > max_chars:
            break
        lines.append(block)
        used += len(block) + 2

    return "\n\n".join(lines)


def answer_query(raw: str, index: LoreIndex, *, max_chars: int = 1900) -> str:
    normalized = normalize_query(raw)

    if wants_pitch(raw, normalized):
        return GAME_PITCH[:max_chars]

    term = _extract_define_term(raw) or _extract_define_term(normalized)
    if term:
        gloss = glossary_answer(term)
        if gloss:
            return gloss[:max_chars]
        # Fall through to dictionary-weighted search
        hits = index.search(f"{term} definition", limit=2)
        dict_hits = [h for h in hits if "dictionary" in h.chunk.rel_path.lower()]
        if dict_hits:
            return f"{glossary_answer(term) or ''}\n\n{dict_hits[0].excerpt}"[:max_chars].strip()
        if hits:
            return f"**{term.title()}** — in our design docs:\n\n{hits[0].excerpt}"[:max_chars]

    search_q = normalized if len(normalize_query(raw)) >= 3 else raw
    hits = index.search(search_q, limit=3)
    # Prefer player-facing docs over phase/audit notes for open questions
    hits = _rerank_for_readability(hits)
    return _format_search_answer(raw, hits, max_chars=max_chars)[:max_chars]


def _rerank_for_readability(hits: list[LoreHit]) -> list[LoreHit]:
    boring = ("phase3.md", "audit", "test.md", "report", "checklist", "integration_plan")
    def sort_key(h: LoreHit) -> tuple[int, float]:
        path = h.chunk.rel_path.lower()
        penalty = 1 if any(b in path for b in boring) else 0
        return (penalty, -h.score)
    return sorted(hits, key=sort_key)


def cli_answer(query: str) -> str:
    index = LoreIndex()
    index.load()
    return answer_query(query, index)


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: python3 tools/lore_responses.py <question>")
        raise SystemExit(1)
    print(cli_answer(" ".join(sys.argv[1:])))
