# Stone Age Clans — Devblog

Player- and community-facing posts about systems, art, and design.

| Post | Topic |
|------|--------|
| [animation-system.md](animation-system.md) | Modular card + procedural arm animation, Character Animation Tuner, scaling body styles |

Technical design docs live in [`bible/`](../bible/README.md).

---

## Post to Discord

Yes — the agent can announce new posts to your Discord server via a **webhook** (one-time setup).

### 1. Create the webhook (you, ~2 minutes)

1. Open your Discord server → **Server Settings** → **Integrations** → **Webhooks**
2. **New Webhook** → pick your devblog channel (e.g. `#dev-updates`)
3. Copy the webhook URL (looks like `https://discord.com/api/webhooks/123.../abc...`)

### 2. Store the URL as a secret (do not commit it)

**Cursor Cloud agent:** add `DISCORD_DEVBLOG_WEBHOOK_URL` to your [cloud environment secrets](https://cursor.com/dashboard/cloud-agents/environments) for this repo.

**Local / Mac terminal:**

```bash
export DISCORD_DEVBLOG_WEBHOOK_URL="https://discord.com/api/webhooks/..."
```

### 3. Post a devblog

```bash
# Preview what Discord will receive (no post)
python3 tools/post_devblog_to_discord.py devblog/animation-system.md --dry-run

# Post to Discord
python3 tools/post_devblog_to_discord.py devblog/animation-system.md
```

The script builds a **short summary** (~700–1000 chars): a hook paragraph, a few key bullets, and a closing line. No GitHub links, no wall of text.

```bash
# Preview what Discord will receive (no post)
python3 tools/post_devblog_to_discord.py devblog/animation-system.md --dry-run

# Post to Discord
python3 tools/post_devblog_to_discord.py devblog/animation-system.md
```

The script skips dev-only sections and internal file paths. Discord gets the digest; the full post stays in `devblog/*.md`.

### Agent workflow

After writing a new `devblog/*.md` file, ask: **"post this devblog to Discord"** — the agent runs the script above if the webhook secret is set.

Optional env vars:

| Variable | Purpose |
|----------|---------|
| `DISCORD_DEVBLOG_WEBHOOK_URL` | *(required)* Webhook URL |
