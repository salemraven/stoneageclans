#!/usr/bin/env python3
"""Discord bot: search devblog + bible and answer questions.

Requires:
  DISCORD_LORE_BOT_TOKEN  — bot token from Discord Developer Portal

Optional:
  DISCORD_QA_CHANNEL_ID   — only respond in this channel
  DISCORD_QA_PREFIX       — command prefix (default: ?)

Setup:
  1. https://discord.com/developers/applications → New Application → Bot
  2. Enable **Message Content Intent** under Bot settings
  3. Invite bot with permissions: View Channels, Send Messages, Read Message History
  4. pip install -r tools/requirements-discord-bot.txt
  5. export DISCORD_LORE_BOT_TOKEN="..."
  6. python3 tools/discord_lore_bot.py

Usage in Discord:
  ?ask how does animation work
  ?search herding
  @Stone Age Clans what is multiplayer like?
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / "tools"
if str(TOOLS) not in sys.path:
    sys.path.insert(0, str(TOOLS))

from lore_responses import answer_query  # noqa: E402
from lore_search import LoreIndex  # noqa: E402

try:
    import discord
    from discord.ext import commands
except ImportError:
    print(
        "Missing discord.py. Install with:\n"
        "  pip install -r tools/requirements-discord-bot.txt",
        file=sys.stderr,
    )
    raise SystemExit(1)

PREFIX = os.environ.get("DISCORD_QA_PREFIX", "?")
CHANNEL_ID = os.environ.get("DISCORD_QA_CHANNEL_ID", "").strip()
TOKEN = os.environ.get("DISCORD_LORE_BOT_TOKEN", "").strip() or os.environ.get(
    "DISCORD_BOT_TOKEN", ""
).strip()

intents = discord.Intents.default()
intents.message_content = True
intents.guilds = True

bot = commands.Bot(command_prefix=PREFIX, intents=intents, help_command=None)
index = LoreIndex()


def _allowed_channel(message: discord.Message) -> bool:
    if not CHANNEL_ID:
        return True
    return str(message.channel.id) == CHANNEL_ID


def _channel_denied_message() -> str:
    return "This bot is limited to the configured Q&A channel."


@bot.event
async def on_ready() -> None:
    count = index.load()
    user = bot.user.name if bot.user else "bot"
    print(f"{user} ready — indexed {count} lore chunks from devblog + bible")


@bot.command(name="ask", help="Search devblog + bible for an answer")
async def ask_cmd(ctx: commands.Context, *, query: str) -> None:
    if not _allowed_channel(ctx.message):
        await ctx.reply(_channel_denied_message(), mention_author=False)
        return
    async with ctx.typing():
        answer = answer_query(query, index)
    await ctx.reply(answer[:2000], mention_author=False)


@bot.command(name="search", help="Same as ask — keyword search")
async def search_cmd(ctx: commands.Context, *, query: str) -> None:
    await ask_cmd(ctx, query=query)


@bot.command(name="help", help="Show how to use this bot")
async def help_cmd(ctx: commands.Context) -> None:
    if not _allowed_channel(ctx.message):
        await ctx.reply(_channel_denied_message(), mention_author=False)
        return
    text = (
        "**Zedu the Wise** — lore keeper for Stone Age Clans\n"
        f"`{PREFIX}pitch` — what is the game? (elevator pitch)\n"
        f"`{PREFIX}ask <question>` — hunting, herding, nomad mode, etc.\n"
        f"Or @mention me with your question.\n\n"
        "Try:\n"
        f"`{PREFIX}pitch`\n"
        f"`{PREFIX}ask how does animation work`\n"
        f"`@Zedu what does pull based mean?`"
    )
    await ctx.reply(text, mention_author=False)


@bot.command(name="pitch", help="What is Stone Age Clans?")
async def pitch_cmd(ctx: commands.Context) -> None:
    if not _allowed_channel(ctx.message):
        await ctx.reply(_channel_denied_message(), mention_author=False)
        return
    from lore_responses import GAME_PITCH

    await ctx.reply(GAME_PITCH[:2000], mention_author=False)
@commands.has_permissions(administrator=True)
async def reload_cmd(ctx: commands.Context) -> None:
    count = index.load()
    await ctx.reply(f"Reloaded **{count}** lore chunks.", mention_author=False)


@bot.event
async def on_message(message: discord.Message) -> None:
    if message.author.bot:
        return

    if bot.user and bot.user in message.mentions:
        if not _allowed_channel(message):
            await message.reply(_channel_denied_message(), mention_author=False)
            return
        query = message.content
        for mention in message.mentions:
            query = query.replace(f"<@{mention.id}>", " ")
            query = query.replace(f"<@!{mention.id}>", " ")
        query = " ".join(query.split()).strip()
        if query:
            async with message.channel.typing():
                answer = answer_query(query, index)
            await message.reply(answer[:2000], mention_author=False)
        else:
            await message.reply(
                f"Ask me something about the game — e.g. `{PREFIX}ask hunting`",
                mention_author=False,
            )
        return

    await bot.process_commands(message)


def main() -> int:
    if not TOKEN:
        print(
            "Missing DISCORD_LORE_BOT_TOKEN.\n"
            "Create a bot at https://discord.com/developers/applications,\n"
            "enable Message Content Intent, then add the token to Cursor Cloud secrets\n"
            "or export it in your shell.",
            file=sys.stderr,
        )
        return 1
    bot.run(TOKEN)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
