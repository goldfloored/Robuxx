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
</content>
</invoke>
