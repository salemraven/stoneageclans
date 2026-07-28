# Discord lore bot — simple setup

This bot answers questions in your Discord server using your **devblog** and **bible** docs.

You only need to do **Part A once** (create the bot). After that, run `tools/run_lore_bot.ps1` on your PC.

---

## Part A — Create the bot (one time, ~3 minutes)

### Step 1: New app

1. Open: https://discord.com/developers/applications
2. Click **New Application** → name it `Stone Age Clans` → **Create**

### Step 2: Bot token

1. Left menu → **Bot** → **Add Bot** → **Yes, do it!**
2. Click **Reset Token** → **Copy** (save it somewhere safe — you only see it once)
3. Scroll down → turn **ON**: **Message Content Intent** → **Save Changes**

### Step 3: Invite to your server

1. Left menu → **OAuth2** → **URL Generator**
2. Scopes: check **bot**
3. Bot Permissions: check **View Channels**, **Send Messages**, **Read Message History**
4. Copy the URL at the bottom → open in browser → pick your server → **Authorize**

### Step 4: Save the token

**Cursor Cloud** (so the agent can run it):

> **Important:** Add the token to your **repository environment**, not only "My Secrets".
> The webhook (`DISCORD_DEVBLOG_WEBHOOK_URL`) works because it's on the environment.
> The bot token must go in the **same place**.

1. Open your [stoneageclans cloud environment](https://cursor.com/dashboard/cloud-agents/environments/e/0e8db27c-7167-11f1-8cbf-12b154d6cb29)
2. Go to **Secrets** (same page where `DISCORD_DEVBLOG_WEBHOOK_URL` lives)
3. Click **Add secret** (do not edit the webhook one)
4. **Name:** `DISCORD_LORE_BOT_TOKEN`
5. **Value:** the bot token you copied from Discord → Bot → Reset Token
6. **Save**, then start a **new** cloud agent chat (old chats won't see new secrets)

**Your Windows PC** (so you can run it locally):

```powershell
# Run once in PowerShell (replace with your real token)
[System.Environment]::SetEnvironmentVariable("DISCORD_LORE_BOT_TOKEN", "PASTE_TOKEN_HERE", "User")
```

Or set it each session:

```powershell
$env:DISCORD_LORE_BOT_TOKEN = "PASTE_TOKEN_HERE"
```

---

## Part B — Start the bot

**Windows** (recommended — leave the window open while you want the bot online):

```powershell
powershell -File tools/run_lore_bot.ps1
```

**Mac / Linux:**

```bash
bash tools/run_lore_bot.sh
```

When you see `ready — indexed … lore chunks`, it works.

---

## Part C — Try it in Discord

In any channel the bot can see:

```
?ask how does animation work
?search nomad mode
```

Or @mention the bot with your question.

---

## Optional: limit to one channel

1. In Discord: right-click your Q&A channel → **Copy Channel ID** (enable Developer Mode in Discord settings → Advanced if you don't see it)
2. Set env var: `DISCORD_QA_CHANNEL_ID` = that number

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Bot doesn't reply | Is `run_lore_bot.ps1` still running? Bot goes offline when you close the window. |
| "Missing bot token" | Do Part A step 4 |
| Bot online but ignores messages | Enable **Message Content Intent** (Part A step 2) |
| Wrong answers | Try shorter keywords: `?ask herding`, `?ask animation` |

---

## Devblog announcements (separate)

Posting new devblogs uses a **webhook**, not this bot. That's already set up if `DISCORD_DEVBLOG_WEBHOOK_URL` is in your secrets.
