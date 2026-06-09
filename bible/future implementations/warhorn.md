# War Horn — future vision (leader trophy)

> **Shipped today:** **H** key **rally** + formations + hunt abort behavior — **`bible/rts.md`**, **`bible/rtsguide.md`**. This doc is **extra fantasy** only (`bible.md` §XXII).

---

## Design idea (not fully implemented)

The war horn should be the item the **leader** carries — symbolic like a crown. Each leader receives a war horn visible on the character sprite. Only the leader rallies clansmen. When a leader is killed, the horn drops as a trophy: **"Warhorn of XXXX"**. Possibly granted at the **name your clan** popup with copy such as: *"You claim some land as yours, name it, start a lineage. These are the first steps toward a story that ends with one dominant species."*

**Code today:** Rally uses territory proximity + `RTS_CONFIG` — not a physical horn item or leader-only gate yet.