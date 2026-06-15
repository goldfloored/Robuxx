# Building a Wave Survival Game with Claude Code

A tutorial for building a Roblox wave survival game by having a real conversation with Claude — planning first, then building one piece at a time.

![What you'll build — wave survival with HUD](Step14.gif)

**Before you start:** Complete the [Setup tutorial](SETUP.md) first — your project folder, Script Sync, and MCP connection need to be working before you continue here.

---

## How This Tutorial Works

Instead of pasting pre-written code, you'll work the way experienced developers do with AI: **plan first, build in small pieces, test before moving on.**

You'll have one planning conversation to map out the whole game, then build it step by step — testing each piece works before adding the next. If something breaks, you fix it before continuing. This keeps bugs small and traceable.

---

## Phase 1: Make a Plan

Before writing any code, describe the game to Claude and ask it to plan the implementation. This gives you a shared map of what you're building and surfaces any misunderstandings before they become bugs.

> **Prompt:**
> I want to build a wave survival game in Roblox. Here's how it should work:
>
> - Simple humanoid enemies spawn in waves around players and chase the nearest player. When they reach someone they explode and deal damage.
> - Players have a laser gun. Two shots kills an enemy.
> - Each wave has more enemies than the last, with a short pause between waves.
> - When a player dies they enter spectator mode — ghost-like appearance, enemies ignore them.
> - When all players are dead, announce the last survivor as winner, then restart from wave 1.
> - There's a HUD showing the current wave number and a kill counter. A "You Died" message appears when you die.
>
> My setup uses Script Sync for `ServerScriptService/`, `ReplicatedStorage/`, and `StarterPlayerScripts/` — and MCP for anything else like StarterGui and StarterPack.
>
> Don't write any code yet. We're going to build this one phase at a time — I'll test each phase before we move on. Break this into small, testable phases. Something like: enemies that spawn, enemies that chase and explode, the laser gun, wave progression, the HUD, spectator mode and restart. Suggest what goes in each folder, flag anything that needs MCP, and make sure each phase is something I can actually test on its own before we add the next piece.

Claude will produce a plan. Read through it — if anything doesn't match what you want, say so now. It's much easier to adjust the plan than the code. Once you're aligned, move to Phase 2.

> **🔖 Git Checkpoint:**
> ```bash
> git add .
> git commit -m "Start wave survival"
> ```

---

## Phase 2: Build It Phase by Phase

Work through each phase from Claude's plan in order. **Don't move on until a phase is working** — each one builds on the last, and catching problems early keeps them small.

For each phase, the pattern is the same:

**1. Ask Claude to implement it:**

> **Prompt:**
> Let's implement [phase name] from our plan.

**2. Ask Claude to check for errors via MCP:**

> **Prompt:**
> Use MCP to start a play test and check the output console for errors. Tell me what you see.

**3. Test it yourself in Studio.** Some things Claude can verify through MCP (errors, whether objects exist), but you need to hit Play and check that it actually feels right — do enemies move? Does the gun fire? Does the wave end?

**4. If something's wrong, describe it and ask Claude to fix it before moving on:**

> **Prompt:**
> [Describe what's wrong — e.g., "enemies spawn but just stand there", "I can equip the gun but clicking does nothing", "the wave counter isn't updating"]. Can you figure out what's wrong and fix it?

**5. Once the phase is working, commit it:**

> ```bash
> git add .
> git commit -m "Add [phase name]"
> ```

Then move to the next phase.

---

**Example — what this looks like for an "enemy spawning" phase:**

> *Let's implement the enemy spawning phase from our plan.*

Claude writes the scripts. You ask it to check for errors via MCP. You hit Play — enemies appear but just stand there. You tell Claude:

> *Enemies are spawning but they're not moving. Can you figure out what's wrong?*

Claude fixes the AI. You test again — they move. You commit and move on.

---

Keep this loop going for every phase in Claude's plan until the game is complete.

---

## Verification Checklist

Run through this checklist in Studio play test:

- [ ] Player spawns with a laser gun
- [ ] Enemies spawn in a ring around you
- [ ] Enemies walk toward you
- [ ] Clicking fires a visible laser beam
- [ ] Shooting enemies kills them (about 2 shots)
- [ ] Enemies explode and hurt you when they reach you
- [ ] New waves start after you clear all enemies
- [ ] Each wave has more enemies
- [ ] Dying shows a "You Died" message and puts you in spectator mode
- [ ] Enemies ignore players in spectator mode and they appear ghost-like
- [ ] The last player standing is announced as winner to all players
- [ ] The game restarts at wave 1 when all players are dead

---

## When Things Go Wrong

AI-generated code doesn't always work on the first try — that's normal. Here's how to handle it.

### Check the console first

After each step, press **Play** in Studio and check the **Output** window (**View → Output**) for red error lines.

> **Prompt:**
> Use Roblox MCP to check the console output. Are there any errors? If so, fix them.

### Describe what you see

If the problem is something visual or behavioral rather than a red error:

> **Prompt:**
> When I play test, [describe what's wrong — e.g., "enemies spawn but don't move", "I can't see the HUD", "the laser shoots but enemies don't take damage", "dead players aren't going into spectator mode"]. Can you figure out what's wrong and fix it?

### Claude's fix made it worse?

> **Prompt:**
> That change broke things. Undo it and go back to how it was before.

### Stuck in a loop of bad fixes?

> **Prompt:**
> Stop trying to fix this. Read through all the scripts involved and explain step by step what's supposed to happen. Then identify where it's going wrong.

### Tips

- **Save often** — every Git Checkpoint is your undo button
- **Be specific** — "it doesn't work" is hard to fix; "enemies spawn but just stand still" is easy
- **Test one step at a time** — that's the whole point of building in stages

---

## Troubleshooting

| Problem | Fix |
|---|---|
| MCP can't reach Studio | Ensure MCP is enabled in Studio's Assistant settings and Studio is open |
| Script Sync folder not connecting | Right-click the service in Explorer and re-link the folder; only ServerScriptService, ReplicatedStorage, and StarterPlayerScripts are supported |
| Enemies don't move | Ask Claude to check the enemy AI script and make sure the humanoid is set up correctly |
| Laser doesn't hit enemies | Ask Claude to check the raycast setup — it might be hitting the player instead of enemies |
| Enemies hurt you multiple times instantly | Ask Claude to make enemies destroy themselves immediately on contact |
| Gun doesn't appear | The LaserGun Tool needs to exist in StarterPack — ask Claude to check via MCP that the Tool and its LocalScript are there |
| Gun fires but nothing happens | The LocalScript inside the Tool may not be requiring GunModule correctly — ask Claude to check the require path |
| Nothing happens when you press Play | Check that script files end in `.server.luau` or `.client.luau` — the extension matters |
| HUD not showing | The ScreenGui elements are in Studio, not synced files — ask Claude to use MCP to verify they exist in StarterGui |
| Enemies still chase dead players | Ask Claude to check that spectator mode is correctly flagging dead players and that the enemy AI respects it |
| Ghost effect not showing on dead players | Ask Claude to check that the highlight shader is being applied when a player enters spectator mode |
| Winner announcement not appearing | Ask Claude to check that the last surviving player is being detected and the announcement is firing to all players |

---

## What You Built

If everything worked, you just made a complete wave survival game by describing what you wanted and working through it with Claude step by step.

From here you can keep adding features the same way — describe what you want, ask Claude to plan how it fits in, then build and test:
- *"Add a shop between waves where players can buy upgrades"*
- *"Make enemies come in different types — some fast and weak, some slow and tough"*
- *"Add a leaderboard that shows the highest wave reached"*
