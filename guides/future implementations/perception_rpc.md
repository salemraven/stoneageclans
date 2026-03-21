# Perception RPC — When to Add

**Current:** Server-authoritative. PerceptionArea runs only on server. No RPC sync for perception. Clients receive outcomes (position, combat state, agro) via normal replication.

**Add RPC for perception when you implement:**

1. **Client-side NPC prediction** — Client predicts NPC behavior before server confirms.
2. **Client-side perception debug UI** — e.g. "show detection radius" or "show detected targets" on client.
3. **Shared authority** — Multiple peers run AI and need to share perception results.
4. **Client-only gameplay using perception** — Any mechanic that needs "what does this NPC see?" on the client.

**Until then:** No RPC needed. Document here so we don't forget.

---

*See: guides/multiplayer.md Phase 6, bible.md AOP/PerceptionArea*
