# WaveSurvival — Architecture

> Phase-by-phase map of the game. **Every function we build is documented here, in the phase it belongs to.** Update this file whenever a phase changes.

## Sync setup

| Location | Mechanism | Editable from files? |
|---|---|---|
| `ServerScriptService/Server/` | Script Sync | ✅ yes |
| `ReplicatedStorage/Shared/` | Script Sync | ✅ yes |
| `StarterPlayerScripts/StarterPlayerScripts/` | Script Sync | ✅ yes |
| `StarterPack` (LaserGun tool) | MCP | ⚠️ Studio-only |
| `StarterGui` | MCP | ⚠️ Studio-only |

**Lesson learned (the HUD regression):** Anything that lives *only* in Studio (StarterGui/StarterPack via MCP) is not in Git, so a place revert wipes it with no way to restore. **Prefer building UI in the synced client script (in code) so it's version-controlled.** The HUD is now built this way.

## Player onboarding (welcome + user tracking)
- **`src/server/PlayerRegistry.server.luau`** — a **single** `Players.PlayerAdded` hook that records every joining user (`UserId → {name, displayName, joinedAt}`) into one table, prints each join, and exposes the whole list via `_G.GetRegisteredUsers()`. This is the one place to read the server's entire player base. (If you ever see `[PlayerRegistry] Loaded.` print twice, a duplicate snuck in — delete the extra.)
- **Welcome banner** (in `src/client/init.client.luau`) — on join, greets the player with `Welcome, <DisplayName>! · ID <UserId>` (read locally from `LocalPlayer`), then fades out after 6 s.

## Replicated objects (the contract between server & client)

| Name | Type | Created by | Direction | Payload |
|---|---|---|---|---|
| `WaveInfo` | RemoteEvent | `WaveManager` | Server → Client | `("Wave", n)` current wave (`0` = intermission); `("Kill", total)` your kill count |
| `LaserFired` | RemoteEvent | LaserGun tool (client) | Client → Server, then Server → All | client: `(enemyModel, hitPos)`; server echo: `(shooter, hitPos)` for beam VFX |

---

## Phase 2 — Enemy spawning ✅
**File:** `ServerScriptService/Server/WaveManager.server.luau`
- `getSpawnPosition(center)` — random point on a ring of `SPAWN_RADIUS` around a center.
- `getRandomPlayerPosition()` — picks a living player's position to spawn around.
- `spawnEnemy(spawnPos)` — clones `ServerStorage.EnemyTemplate`, names it `Enemy`, tracks `activeEnemies`, hooks `Humanoid.Died`.

## Phase 3 — Chase & explode ✅
**File:** `ServerScriptService/Server/EnemyAI.server.luau`
- `getNearestPlayer(fromPos)` — nearest non-spectator living player within `DETECT_RANGE`.
- `explode(enemy)` — spawns Explosion, damages players inside `EXPLOSION_RADIUS`, destroys the enemy.
- `startChase(enemy)` — pathfinds toward target; `Touched` triggers `explode` (once, via `exploded` flag).
- `workspace.ChildAdded` — starts chase on any new `Enemy` model.

## Phase 4 — Laser gun (server) ✅
**File:** `ServerScriptService/Server/LaserGunServer.server.luau`
- `onLaserFired(player, enemyModel, hitPos)` — validates the hit, range-checks (anti-cheat), `TakeDamage(50)`, **broadcasts kills via `WaveInfo` (Phase 6)**, echoes `LaserFired` to all clients for the beam.
- `playerKills` table + `PlayerRemoving` cleanup.

## Phase 5 — Wave progression ✅
**File:** `ServerScriptService/Server/WaveManager.server.luau`
- `spawnWave(n)` — count = `BASE_ENEMIES + (n-1) * ENEMIES_PER_WAVE`.
- `waitForWaveClear()` — waits on the `waveCleared` BindableEvent, with `WAVE_CLEAR_TIMEOUT` safety.
- `livingPlayerCount()` — non-spectator players with health > 0.
- `broadcastWave(n)` — fires `WaveInfo` `("Wave", n)`; `n = 0` signals intermission.
- Main loop: wait for a living player → increment wave → broadcast → spawn → wait clear → pause `WAVE_PAUSE`.

## Phase 6 — HUD 🔄 (current)
**File:** `StarterPlayerScripts/StarterPlayerScripts/Client.local.luau` *(built in code — no StarterGui dependency)*
- `makeLabel(...)` — helper to create styled TextLabels.
- Builds a `ScreenGui` named `HUD` in `PlayerGui` (destroys any stale copy first).
- Listens to `WaveInfo`: `"Wave"` → updates wave label (`0` → "Get Ready…"); `"Kill"` → updates kill label.
- `onCharacter(char)` — hides the "You Died" overlay on spawn, shows it on `Humanoid.Died`.

## Phase 7 — Spectator mode & restart 🔄 (current)
Built cleanly in Rojo. Round-based: `WaveManager` sets `Players.CharacterAutoLoads = false` and owns all (re)spawning.
**File:** `src/server/SpectatorManager.server.luau`
- `makeGhost(player, char)` — on `Humanoid.Died`: adds the `Spectator` tag, sets body parts to `GHOST_TRANSPARENCY` + `CanCollide=false`, strips their Tool. Enemies already ignore tagged/dead players (EnemyAI), so no AI change needed.

**File:** `src/server/WaveManager.server.luau` (round lifecycle)
- `onPlayer/onCharacter` — `LoadCharacter()` on join; records `lastDeadPlayer` (last to fall = winner) via `Humanoid.Died`.
- `waitForWaveEnd()` — returns when enemies cleared, **party wiped** (`livingPlayerCount()==0`), or timeout.
- `restartRound()` — clears enemies, resets `currentWave=0`, `LoadCharacter()`s everyone (fresh body drops ghost/tag), broadcasts `Wave 0`.
- Main loop: on wipe → `broadcast("GameOver", winnerName)` → wait `RESTART_DELAY` → `restartRound()`.
- **Bug fixed:** enemy count now decremented on `enemy.Destroying` (covers both laser-kills and enemies that explode), instead of only `Humanoid.Died` — previously exploded enemies could hang a wave until the 60s timeout.

**File:** `src/client/init.client.luau` — adds a gold "🏆 \<name\> survived the longest! Restarting…" banner on `WaveInfo` `"GameOver"`; cleared on the next `"Wave"` message or respawn.

> **Cleanup done (2026-06-18):** Purged the orphaned MCP spectator/respawn system from `WaveSurvival.rbxlx` (`SpectatorManager`+`RespawnHandler`, nested `SpectatorClient`, `RespawnButton`, `RespawnRequest`+`SpectatorEvent` RemoteEvents — the old `SpectatorManager` had its source pasted twice and set `RespawnTime=9999`). Replaced with the clean Rojo version above.

> **Performance fix (2026-06-18) — duplicate scripts were running every system 2–3×:** The place held a *stale legacy* `ServerScriptService.Server` **Folder** (old pre-Rojo monolithic scripts: `WaveManager "Phase 1+4"`, `EnemyAI`, `LaserGunServer`, `SpectatorManager "Phase 6"`, + orphan `RespawnHandler`) sitting **alongside** the real Rojo `Server` **Script** (`init.server.luau`, which holds the current scripts as children). Both ran at once → multiple concurrent wave loops, doubled `LoadCharacter()` (slow/janky spawns), doubled `PathfindingService:ComputeAsync` per enemy (lag). Also a broken duplicate `StarterPack.LaserGun` **Folder** (Rojo's incomplete `init.tool.json` repr — `Handle` was a Folder, not equippable) next to the working `LaserGun` **Tool**, and the dead `RespawnRequest`/`SpectatorEvent` RemoteEvents. **Fix:** deleted the stale Folder, the broken LaserGun Folder, and the dead RemoteEvents from the place; removed the `StarterPack`/`StarterGui` mappings from `default.project.json` (both are Studio-only per the table above — the mappings made Rojo recreate the broken LaserGun and pointed at a non-existent `src/startergui`); deleted the orphaned `src/starterpack/` files. Verified: a fresh play test now logs exactly one `Loaded.` per system and a single `=== WAVE 1 ===`.
>
> **How to detect a recurrence:** in Studio, `ServerScriptService` should contain exactly **one** child named `Server` (a *Script*, not a Folder). If you see two, or any `Loaded.` line printing more than once at startup, a stale duplicate is back.

---

## Environment tooling — `BeachEnvironment` (not part of the wave gameplay)
**File:** `src/shared/BeachEnvironment.luau` → `ReplicatedStorage.Shared.BeachEnvironment` (ModuleScript)

Procedurally builds **low-poly tropical beach assets** in the project's stylized cartoon look: curving segmented cylinder palm trunks, starburst flat-blade fronds (two-tone green), cream `SmoothPlastic` sand plates, vibrant grass turf panels. All parts `Anchored`, `CanCollide = true`, flat materials.

- **Memory optimization — "build once, clone many":** geometry is built from primitive parts a single time, baked into **one `Union`** (`UsePartColor=false` keeps colors, `RenderFidelity=Performance`), wrapped in a Model template, then `:Clone()` + `:ScaleTo()` per placed copy. A 40-palm forest is ~40 instances, not 40×~100 parts.
- `createPalm(opts)` — palm as a raw part Model. `bakePalm(opts)` — returns the baked single-Union template.
- `plantPalms{count,minRadius,maxRadius,minHeight,maxHeight,...}` — bakes one template and scatters random-sized clones on a ring, leaving the centre open/walkable. `placeFlush()` grounds each by its true bounding box (base flush, no tilt).
- `createSand(opts)`, `createGrassPatch(opts)`, `generateTestScene(opts)`.
- **Run it (manual, not auto):** `require(game.ReplicatedStorage.Shared.BeachEnvironment).generateTestScene()` then `workspace.BeachEnv:Destroy()` to clear. Nothing auto-runs this.
</content>
</invoke>
