# Stone Age Clans — Devblog

Player- and community-facing posts about systems, art, and design.

| Post | Topic |
|------|--------|
| [animation-system.md](animation-system.md) | Modular card + procedural arm animation, Character Animation Tuner, scaling body styles |

Technical design docs live in [`bible/`](../bible/README.md).

---

## Post announcements to Discord (webhook)

One-way announcements when a new devblog goes out.

### 1. Create the webhook (~2 minutes)

1. Discord server → **Server Settings** → **Integrations** → **Webhooks**
2. **New Webhook** → pick your devblog channel (e.g. `#dev-updates`)
3. Copy the webhook URL

### 2. Store the secret

**Cursor Cloud:** `DISCORD_DEVBLOG_WEBHOOK_URL` in [cloud environment secrets](https://cursor.com/dashboard/cloud-agents/environments).

**Local:**

```bash
export DISCORD_DEVBLOG_WEBHOOK_URL="https://discord.com/api/webhooks/..."
```

### 3. Post

```bash
python3 tools/post_devblog_to_discord.py devblog/animation-system.md --dry-run
python3 tools/post_devblog_to_discord.py devblog/animation-system.md
```

Sends a **short digest** (~700–1000 chars): hook, key bullets, closing line. No GitHub links.

---

## Discord Q&A bot (devblog + bible search)

Answers questions in Discord by searching your docs (`?ask`, `?search`, or @mention).

**Setup:** follow **[tools/DISCORD_BOT_SETUP.md](../tools/DISCORD_BOT_SETUP.md)** — then run `tools/run_lore_bot.ps1` on your PC.

**Quick test (no Discord):** `python3 tools/lore_search.py "animation"`
