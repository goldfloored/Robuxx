# How to Write a CLAUDE.md for Roblox

CLAUDE.md is a file Claude reads at the start of every conversation. It tells Claude how your project is set up and how you want it to work — so you don't have to explain it every time, and Claude doesn't have to guess.

For Roblox projects this matters more than most. Claude needs to know which folders sync to Studio, which areas require MCP, and how your files are named. Without it, scripts end up in the wrong place and things don't run.

---

## What to put in it

A good CLAUDE.md for Roblox covers four things:

**1. Your project layout**

Tell Claude which folders are synced via Script Sync and which areas need MCP. Be explicit — this is the most common source of mistakes.

Example:
```
Script Sync folders (disk ↔ Studio): ServerScriptService/, ReplicatedStorage/, StarterPlayerScripts/
MCP-only (not synced): StarterGui/, StarterPack/, Workspace
MCP server name: roblox-studio
```

**2. File naming**

Roblox uses file extensions to decide what type of script to create. Get this wrong and scripts run in the wrong context or don't run at all.

```
*.server.lua  →  Script (server)
*.client.lua  →  LocalScript (client)
*.lua         →  ModuleScript (ReplicatedStorage only)
```

**3. How you want Claude to work**

Tell Claude your working style so it doesn't default to cautious, survey-heavy behaviour.

```
- Bias to action — go with your first instinct, don't deliberate.
- Make the change, run a Play test, read the console, move on.
- Never ask the user to press Play — drive it yourself via MCP.
- No warmup steps. Don't query Studio to "see what's there" before acting.
```

**4. Code rules**

Set your standards once here so you don't have to repeat them.

```
- Strict typing — always annotate function parameters and return types.
- Use RemoteEvents/RemoteFunctions for client↔server communication. No _G globals.
- Minimal comments — only when the reason behind something isn't obvious.
- No unused variables or parameters.
```

---

## ARCHITECTURE.md — keep a map of what exists

As your project grows, Claude will start querying Studio to check what exists before making changes. You can stop this by keeping an `ARCHITECTURE.md` — a plain text map of every script on disk and every instance in Studio.

Tell Claude to maintain it in your CLAUDE.md:

```
ARCHITECTURE.md is the source of truth for what exists.
Read it instead of querying Studio. Update it in the same turn whenever anything is added, moved, or deleted.
```

Then ask Claude to create the initial file:

> Look at my project files and create an ARCHITECTURE.md that lists everything currently in my Script Sync folders and MCP-managed areas.

Claude will keep it up to date from there.

---

## Getting Claude to write it for you

You don't have to write CLAUDE.md by hand. Ask Claude to interview you:

> I want to create a CLAUDE.md for my Roblox project. Ask me what you need to know — my folder setup, file naming, MCP areas, working style, and code rules — then write the file.

Answer its questions, then review the result. Check that the Script Sync folders are right and the MCP areas are listed — those are the parts that matter most.

---

## Once it's written — start a new chat

**Claude only reads CLAUDE.md at the start of a conversation.** After you've created the file, start a new chat. Every conversation from that point will open with Claude already knowing your setup.

To verify it's working:

> Read CLAUDE.md and tell me what you know about this project — without querying Studio or reading any other files.

If Claude can describe your layout and rules accurately, you're set. If it hesitates or queries Studio first, something is missing from the file.

---

## Keep improving it as you go

Your first CLAUDE.md won't be perfect — that's fine. The important thing is to update it as you work. Every time Claude does something you didn't want, or you find yourself correcting it for the second time, that's a sign something belongs in the file.

> Update CLAUDE.md — [describe what kept going wrong and what the correct behaviour should be].

Over time these small additions add up. Your setup gets tighter, Claude needs less correction, and you spend less time re-explaining things. The file is never really finished — it just keeps getting better.
