#!/usr/bin/env python3
"""Turn user questions into friendly Discord answers (pitch, glossary, search)."""
from __future__ import annotations

import re

from dataclasses import dataclass

from lore_search import LoreHit, LoreIndex, _strip_md

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

FOLLOW_UP_RE = re.compile(
    r"^(?:"
    r"what does (?:that|it|this) mean\??|"
    r"what do you mean\??|"
    r"(?:can you )?explain(?: (?:that|more|further))?\??|"
    r"what\??|"
    r"huh\??|"
    r"elaborate\??|"
    r"say more\??"
    r")$",
    re.IGNORECASE,
)

FOLLOW_UP_AFTER_PITCH = """Ah — let me unpack that a little.

**ClanBrain** is your clan's strategist. It watches food, threats, and prey, then sets *intent*: "we need defenders," "go hunt," "raid them." Your NPCs aren't puppets on strings.

**Pull-based** means fighters *volunteer* for those jobs instead of the AI assigning every clansman every second. Raids feel intentional. Herds break under stress. Less lag, more emergent stories.

Want specifics? Ask about **hunting**, **herding**, **raiding**, or **nomad mode**."""

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


PRONOUN_TERMS = {"that", "it", "this", "those"}


@dataclass
class ChannelContext:
    kind: str = ""
    last_query: str = ""


@dataclass
class LoreAnswer:
    text: str
    kind: str = "search"


def is_follow_up(query: str) -> bool:
    return bool(FOLLOW_UP_RE.match(query.strip().rstrip("?!. ")))


def answer_follow_up(context: ChannelContext | None, max_chars: int = 1900) -> LoreAnswer | None:
    if not context or not context.kind:
        return None
    if context.kind == "pitch":
        return LoreAnswer(FOLLOW_UP_AFTER_PITCH[:max_chars], "follow_up")
    if context.kind.startswith("glossary:"):
        term = context.kind.split(":", 1)[1]
        gloss = glossary_answer(term)
        if gloss:
            return LoreAnswer(gloss[:max_chars], context.kind)
    if "pull" in context.last_query.lower() or context.kind == "search":
        gloss = glossary_answer("pull based")
        if gloss:
            combined = (
                f"{glossary_answer('clanbrain')}\n\n{gloss}"
            )[:max_chars]
            return LoreAnswer(combined, "glossary:pull-based")
    return LoreAnswer(FOLLOW_UP_AFTER_PITCH[:max_chars], "follow_up")


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
        term = match.group(1).strip()
        if term not in PRONOUN_TERMS:
            return term
        return None
    match = re.search(r"what is (?:a |an |the )?(.+)$", q)
    if match and len(match.group(1).split()) <= 5:
        return match.group(1).strip()
    if q.startswith("define "):
        return q[7:].strip()
    return None


def wants_pitch(raw: str, normalized: str) -> bool:
    blob = f"{raw} {normalized}".lower()
    if "stone age" in blob:
        return True
    if any(t in blob for t in GAME_PITCH_TRIGGERS):
        return True
    if re.search(r"\bstone\s*age\s*clans?\b", blob):
        return True
    if normalized.lower() in ("", "game", "it", "this", "stone age clans"):
        return True
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


def answer_query(
    raw: str,
    index: LoreIndex,
    *,
    context: ChannelContext | None = None,
    max_chars: int = 1900,
) -> LoreAnswer:
    if is_follow_up(raw):
        follow = answer_follow_up(context, max_chars=max_chars)
        if follow:
            return follow

    normalized = normalize_query(raw)

    if wants_pitch(raw, normalized):
        return LoreAnswer(GAME_PITCH[:max_chars], "pitch")

    term = _extract_define_term(raw) or _extract_define_term(normalized)
    if term and term.lower() not in PRONOUN_TERMS:
        gloss = glossary_answer(term)
        if gloss:
            return LoreAnswer(gloss[:max_chars], f"glossary:{term.lower()}")
        hits = index.search(f"{term} definition", limit=2)
        dict_hits = [h for h in hits if "dictionary" in h.chunk.rel_path.lower()]
        if dict_hits:
            text = f"{dict_hits[0].excerpt}"[:max_chars].strip()
            return LoreAnswer(text, f"glossary:{term.lower()}")
        if hits:
            text = f"**{term.title()}** — in our design docs:\n\n{hits[0].excerpt}"[:max_chars]
            return LoreAnswer(text, "search")

    search_q = normalized if len(normalized) >= 3 else raw
    hits = index.search(search_q, limit=3)
    hits = _rerank_for_readability(hits)
    text = _format_search_answer(raw, hits, max_chars=max_chars)[:max_chars]
    return LoreAnswer(text, "search")


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
    return answer_query(query, index).text


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: python3 tools/lore_responses.py <question>")
        raise SystemExit(1)
    print(cli_answer(" ".join(sys.argv[1:])))
