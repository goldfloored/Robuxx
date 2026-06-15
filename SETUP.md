# Setting up your Roblox development environment with an AI assistant and text editor

This is a step-by-step guide to getting your tools connected and ready to build Roblox games with AI assistance. No coding experience required.

## Who does what

Some steps are clicks in Roblox Studio or your editor that only you can do. Others are prompts to paste into the AI model of your choosing. Each step below is tagged with `[you]` or `[AI]` to indicate who does what.

## Step 1: Install prerequisites [you]

1. **An AI-enabled text editor** — The most popular options are [Visual Studio Code](https://code.visualstudio.com) or [Cursor](https://cursor.com).

   Cursor has its AI assistant built in, whereas VS Code needs the [Claude Code](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code) extension or similar extension. Both editors work well for this guide. Use whichever you prefer.

2. **Roblox Studio** — Download from [create.roblox.com](https://create.roblox.com/docs/studio/setup).
3. **Git** — Install from [git-scm.com](https://git-scm.com/install).

   - Windows users might prefer [WinGet](https://learn.microsoft.com/en-us/windows/package-manager/winget/) (`winget install --id Git.Git -e --source winget`).
   - macOS users can use [Homebrew](https://brew.sh/) (`brew install git`).

## Step 2: Sign in to everything [you]

1. **Your text editor:**

   - **VS Code** — Signing in varies by extension. For Claude Code, click the Claude icon in the activity bar, sign in with your Anthropic account, and verify the chat panel opens. The process is similar for other providers.
   - **Cursor** — Open Cursor, sign in with your Cursor account, and verify that the chat panel opens (any model is fine).

2. **Roblox Studio** — Open Roblox Studio, sign in with your Roblox account, and verify that you can create a new place.

## Step 3: Download the starter repository [you]

The starter repository has the basic folder layout and a `.gitignore` file so that Git only commits the important parts of your project. Most of the manual setup is done for you.

1. Download the [starter repository](<STARTER_REPO_URL>) and unzip it to a folder named `WaveSurvival`.

1. In your text editor, go to **File → Open Folder** and select the `WaveSurvival` folder. You should see three folders inside:

   - `ServerScriptService/` — holds server scripts (game logic, enemy AI, wave management)
   - `ReplicatedStorage/` — holds shared modules accessible by both server and client
   - `StarterPlayerScripts/` — holds client scripts that run for each player

The `.gitkeep` files inside each folder are placeholders so that Git tracks the otherwise-empty folders.

## Step 4: Create a blank project in Roblox Studio [you]

1. Open Roblox Studio.
2. Click **New Experience**.
3. **File → Save to File**, navigate to your `WaveSurvival` folder from Step 3, and save the place file as `WaveSurvival.rbxlx`. (The repository's `.gitignore` file already excludes `.rbxlx` files from Git.)
4. Keep Roblox Studio open. You'll need it for Script Sync and MCP.

## Step 5: Enable Script Sync beta [you]

Script Sync is a beta feature and must be enabled before use.

1. In Roblox Studio, select **File → Beta Features**.
2. Find **Script Sync** in the list, enable it, and click **Save**.
3. Restart Roblox Studio when prompted.

## Step 6: Connect Script Sync in Roblox Studio [you]

Script Sync must be connected once per folder. You link each Studio service to its matching folder
on disk.

1. In Roblox Studio, right-click **ServerScriptService** in the Explorer panel
2. Select **Script Sync → Sync to**, then browse to your `WaveSurvival` folder.

   **Don't** choose the precreated directories. Instead, choose the `WaveSurvival` folder. Since they already have the correct names, Script Sync will automatically use the directories inside `WaveSurvival`.

3. Repeat for **ReplicatedStorage** and **StarterPlayerScripts**.

Now any `.luau` files you create in those folders will appear as scripts in Studio automatically.

## Step 7: Verify that Script Sync works [AI]

It's time! It's finally time. In your text editor chat panel, prompt your AI agent:

> Create a test script at `ServerScriptService/Test.server.luau` that prints 'Hello from Script
> Sync!' to the output.

In Roblox Studio, check the Explorer. You should see `Test` appear under **ServerScriptService**.

We'll do a deeper, agent-driven verification later after MCP is online. The AI agent will check the bindings via the Studio API, run a play test, and clean up the test scripts.

## Step 8: Enable the MCP connection [you]

The MCP (Model Context Protocol) server in Roblox Studio lets AI agents interact with Studio directly—reading the game tree, creating objects, running scripts, checking output, etc. It's great for anything Script Sync can't reach, like **StarterGui** and **StarterPack**.

1. In Roblox Studio, click the AI Assistant button in the upper-right if the Assistant window isn't already open.
1. In the Assistant window, click **⋯ → Manage MCP Servers**.
1. Make sure MCP is enabled.
1. Under **Quick connect**, enable Cursor or Visual Studio Code.

If you installed Cursor while Roblox Studio was open, it's possible you'll need to restart Studio, Cursor, or both to establish the connection. To learn more, see the [Roblox MCP documentation](https://create.roblox.com/docs/studio/mcp).

## Step 9: Verify the MCP connection [AI]

Prompt the AI agent:

> Use the Roblox MCP to read the current game tree in Roblox Studio. List what's in Workspace.

You might have to approve the command or add the MCP tool to an allowlist. The response will be something like this:

> Here's what's currently in Workspace for the open place (root DataModel name is `Place`):
>
> Path | ClassName | Notes
> --- | --- | ---
> `Workspace.Camera` | `Camera` | —
> `Workspace.Terrain` | `Terrain` | —
> `Workspace.Baseplate` | `Part` | 1 child (a `Texture`)
> `Workspace.SpawnLocation` | `SpawnLocation` | 1 child (a `Decal`)
> 
> So this looks like a fresh Baseplate template — no models, folders, scripts, or other content under `Workspace` yet.

## Step 10: Run some code [AI]

Prompt the AI agent to verify the complete setup:

> Use the Roblox MCP connection to verify Script Sync is working properly. Make some changes to Test.server.luau, add new scripts in the other two folders, and verify the output of each. Run `game:GetService("InstanceFileSyncService"):GetStatus(instance)` in each script to verify the sync status. When you're done, delete all three scripts.

If you watch in Roblox Studio, you can see the agent start a playtest in order to verify the output.

## Step 11: Commit to Git [you]

At this point, you should have a clean, working configuration, so it's a great time to commit to Git. From the terminal:

```bash
git add .
git commit -m "Script sync connected and MCP verified"
```

## Next steps

At this point, you're ready to start developing. Your project is synced to Roblox Studio, your AI of choice can talk to it directly, and you have a Git commit so that it's easy to revert to a known-good state. Check out the [Wave Survival tutorial](WAVE_SURVIVAL.md) to start building a game.
