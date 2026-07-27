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

A real **bot** (not the webhook) that answers questions by searching `devblog/*.md` and `bible/**/*.md`.

### What it does

- `?ask how does animation work` — top matching excerpts from devblog + bible
- `?search herding` — same thing
- `@Stone Age Clans what is nomad mode?` — mention the bot

No GitHub links. Answers are pulled from your docs on disk.

### 1. Create the bot (~5 minutes)

1. [Discord Developer Portal](https://discord.com/developers/applications) → **New Application**
2. **Bot** → **Add Bot** → copy the **token**
3. Under Bot, enable **Message Content Intent** (required)
4. **OAuth2 → URL Generator** → scopes: `bot` → permissions: `Send Messages`, `Read Message History`, `View Channels`
5. Open the invite URL and add the bot to your server

### 2. Install + run

```bash
pip install -r tools/requirements-discord-bot.txt
export DISCORD_LORE_BOT_TOKEN="your-bot-token"
python3 tools/discord_lore_bot.py
```

The bot must stay running (your PC, a small VPS, etc.). The webhook poster does **not** need this.

**Optional env vars:**

| Variable | Purpose |
|----------|---------|
| `DISCORD_LORE_BOT_TOKEN` | Bot token *(required)* |
| `DISCORD_QA_CHANNEL_ID` | Only respond in this channel |
| `DISCORD_QA_PREFIX` | Command prefix (default `?`) |

### 3. Test search locally (no Discord)

```bash
python3 tools/lore_search.py "how does animation work"
python3 tools/lore_search.py "nomad mode"
```

### Agent workflow

- **Announce devblog:** "post this devblog to Discord" → runs `post_devblog_to_discord.py`
- **Q&A bot:** runs on your machine/server with `DISCORD_LORE_BOT_TOKEN` — not started by the cloud agent unless you ask to deploy it somewhere
