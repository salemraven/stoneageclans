# How to read this

This site is a pile of short pages. One word, one page. System pages only point at those words.

## Page shape

Copy this when a new word is added. Leave **Status** as Draft until the answer is in.

```markdown
# Term name

**Status:** Draft

**Whose word:** Yours

## Definition

One sentence.

## What it is not

Only if the docs already mix this up with a neighbor. Otherwise leave this section out.

## Doc fight

Only if two docs disagree. Otherwise leave this section out.

## Related

- [Neighbor](neighbor.md)

## Systems

- [People](../systems/people.md)
```

## Status

- **Draft** — sentence from the dictionary files. Not your final word.
- **Confirmed** — you said it is right, or you gave a new sentence. The new sentence replaces the draft. The doc fight stays on the page only if you still want the old disagreement visible.
- **Retired** — you said drop the word. The page stays so old links do not die. The definition becomes one line: this word is not used.

## Whose word

- **Yours** — a word for the game (caveman, herd, flag).
- **Sim name** — a name the write-ups added (`follow_is_ordered`, food-days buffer). You can later keep it, rename it, or hide it.

## What this site does not do

It does not read the code. It does not edit `bible.md`, the GDD, or `game_dictionary.md` while pages are still drafts.

## Open it

From the game folder:

```bash
bash tools/serve_wiki.sh
```

Then open `http://127.0.0.1:8000`.

If search shows a result but a click does nothing, hard-refresh the page (`Cmd+Shift+R` on Mac). You can also open **Terms → ClanBrain** in the left sidebar.
