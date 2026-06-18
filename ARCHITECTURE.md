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

## Phase 7 — Spectator mode & restart ❌ (next)
Not yet built. Needs: set a `Spectator` tag on dead players (the AI/spawn code already *reads* this tag), ghost appearance via `Highlight`/transparency, last-survivor winner announcement to all clients, restart from wave 1.

> **Cleanup note (2026-06-18):** An earlier MCP attempt left an orphaned spectator/respawn system baked into `WaveSurvival.rbxlx` (NOT in Rojo): `SpectatorManager` + `RespawnHandler` (ServerScriptService.Server), `SpectatorClient` (nested in StarterPlayerScripts.Client), `RespawnButton` (StarterGui), and `RespawnRequest` + `SpectatorEvent` RemoteEvents. `SpectatorManager` had its source pasted twice (double Died handlers, `RespawnTime=9999` set twice). **Decision: purge all 6 in Studio**, rebuild Phase 7 cleanly inside Rojo `src/`. The `FindFirstChild("Spectator")` checks in `src/server` are intentional Phase 7 hooks — keep them.
</content>
</invoke>
