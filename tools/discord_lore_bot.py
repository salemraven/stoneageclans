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
  ?pitch
  ?ask how does animation work
  @Zedu tell me about Stone Age Clans
  (reply to Zedu) What does that mean?
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / "tools"
if str(TOOLS) not in sys.path:
    sys.path.insert(0, str(TOOLS))

from lore_responses import (  # noqa: E402
    ChannelContext,
    GAME_PITCH,
    answer_query,
)
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
channel_memory: dict[int, ChannelContext] = {}


def _allowed_channel(message: discord.Message) -> bool:
    if not CHANNEL_ID:
        return True
    return str(message.channel.id) == CHANNEL_ID


def _channel_denied_message() -> str:
    return "This bot is limited to the configured Q&A channel."


def _clean_query(message: discord.Message) -> str:
    query = message.content
    if bot.user:
        for mention in message.mentions:
            query = query.replace(f"<@{mention.id}>", " ")
            query = query.replace(f"<@!{mention.id}>", " ")
    return " ".join(query.split()).strip()


def _should_respond(message: discord.Message) -> bool:
    if bot.user and bot.user in message.mentions:
        return True
    if not message.reference:
        return False
    ref = message.reference.resolved
    if isinstance(ref, discord.Message) and ref.author == bot.user:
        return True
    return False


async def _reply_with_lore(message: discord.Message, query: str) -> None:
    ctx = channel_memory.get(message.channel.id)
    async with message.channel.typing():
        result = answer_query(query, index, context=ctx)
    channel_memory[message.channel.id] = ChannelContext(
        kind=result.kind,
        last_query=query,
    )
    await message.reply(result.text[:2000], mention_author=False)


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
    await _reply_with_lore(ctx.message, query)


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
        f"Or @mention me — or **reply** to one of my messages.\n\n"
        "Try:\n"
        f"`{PREFIX}pitch`\n"
        f"`@Zedu tell me about Stone Age Clans`\n"
        f"Then reply: `What does that mean?`"
    )
    await ctx.reply(text, mention_author=False)


@bot.command(name="pitch", help="What is Stone Age Clans?")
async def pitch_cmd(ctx: commands.Context) -> None:
    if not _allowed_channel(ctx.message):
        await ctx.reply(_channel_denied_message(), mention_author=False)
        return
    channel_memory[ctx.channel.id] = ChannelContext(kind="pitch", last_query="pitch")
    await ctx.reply(GAME_PITCH[:2000], mention_author=False)


@bot.command(name="reload", help="Reload devblog + bible index (admin)")
@commands.has_permissions(administrator=True)
async def reload_cmd(ctx: commands.Context) -> None:
    count = index.load()
    await ctx.reply(f"Reloaded **{count}** lore chunks.", mention_author=False)


@bot.event
async def on_message(message: discord.Message) -> None:
    if message.author.bot:
        return

    if _should_respond(message):
        if not _allowed_channel(message):
            await message.reply(_channel_denied_message(), mention_author=False)
            return
        query = _clean_query(message)
        if query:
            await _reply_with_lore(message, query)
        else:
            await message.reply(
                f"Ask me something — e.g. `{PREFIX}pitch` or *tell me about Stone Age Clans*",
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
