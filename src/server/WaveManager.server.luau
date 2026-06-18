-- WaveManager: Phases 2/5 + 7 — Enemy spawning, wave progression, round lifecycle.
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WAVE_PAUSE = 5
local BASE_ENEMIES = 5
local ENEMIES_PER_WAVE = 3
local SPAWN_RADIUS = 30
local WAVE_CLEAR_TIMEOUT = 60
local RESTART_DELAY = 6

local currentWave = 0
local waveActive = false
local activeEnemies = 0
local lastDeadPlayer: Player? = nil

-- Round-based: we own spawning so dead players stay spectators until the whole
-- party wipes, then everyone respawns for a fresh round (Phase 7).
Players.CharacterAutoLoads = false

local waveInfoEvent = ReplicatedStorage:FindFirstChild("WaveInfo")
if not waveInfoEvent then
	waveInfoEvent = Instance.new("RemoteEvent")
	waveInfoEvent.Name = "WaveInfo"
	waveInfoEvent.Parent = ReplicatedStorage
end

local function broadcast(kind: string, value: any)
	waveInfoEvent:FireAllClients(kind, value)
end

local function getSpawnPosition(center: Vector3): Vector3
	local angle = math.random() * 2 * math.pi
	return Vector3.new(
		center.X + math.cos(angle) * SPAWN_RADIUS,
		center.Y + 5,
		center.Z + math.sin(angle) * SPAWN_RADIUS
	)
end

local function getRandomPlayerPosition(): Vector3
	local positions = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			table.insert(positions, player.Character.HumanoidRootPart.Position)
		end
	end
	return #positions > 0 and positions[math.random(#positions)] or Vector3.new(0, 5, 0)
end

local function spawnEnemy(spawnPos: Vector3)
	local enemyTemplate = ServerStorage:FindFirstChild("EnemyTemplate")
	if not enemyTemplate then
		warn("[WaveManager] EnemyTemplate missing!")
		return
	end
	local enemy = enemyTemplate:Clone()
	enemy.Name = "Enemy"
	enemy.Parent = workspace
	if enemy.PrimaryPart then
		enemy:SetPrimaryPartCFrame(CFrame.new(spawnPos))
	end
	activeEnemies += 1
	-- Single decrement path: covers laser-kills AND enemies that explode on a
	-- player (both end in Destroy), so the wave can't hang waiting on a corpse.
	enemy.Destroying:Connect(function()
		activeEnemies -= 1
	end)
	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			task.delay(0.3, function()
				if enemy.Parent then enemy:Destroy() end
			end)
		end)
	end
end

local function spawnWave(waveNumber: number)
	local count = BASE_ENEMIES + (waveNumber - 1) * ENEMIES_PER_WAVE
	print(string.format("[WaveManager] Wave %d — spawning %d enemies", waveNumber, count))
	for _ = 1, count do
		spawnEnemy(getSpawnPosition(getRandomPlayerPosition()))
		task.wait(0.2)
	end
end

local function clearEnemies()
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name == "Enemy" then obj:Destroy() end
	end
	activeEnemies = 0
end

local function livingPlayerCount(): number
	local count = 0
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if not char then continue end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and not char:FindFirstChild("Spectator") then
			count += 1
		end
	end
	return count
end

-- Remember the last player to fall — that's the "last survivor" / winner.
local function onCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		lastDeadPlayer = player
	end)
end

local function onPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	-- Required: CharacterAutoLoads is false, so players only spawn when we load them.
	player:LoadCharacter()
end

Players.PlayerAdded:Connect(onPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayer(player)
end

-- Wait until the wave ends: enemies cleared, party wiped, or safety timeout.
local function waitForWaveEnd()
	local elapsed = 0
	while elapsed < WAVE_CLEAR_TIMEOUT do
		if activeEnemies <= 0 then return end
		if livingPlayerCount() == 0 then return end
		task.wait(0.5)
		elapsed += 0.5
	end
	warn(string.format("[WaveManager] Wave %d timed out", currentWave))
end

local function restartRound()
	clearEnemies()
	currentWave = 0
	lastDeadPlayer = nil
	for _, player in ipairs(Players:GetPlayers()) do
		player:LoadCharacter() -- fresh body clears the ghost + Spectator tag
	end
	task.wait(1)
	broadcast("Wave", 0)
end

task.delay(3, function()
	while true do
		repeat task.wait(1) until livingPlayerCount() > 0
		currentWave += 1
		waveActive = true
		print(string.format("[WaveManager] === WAVE %d ===", currentWave))
		broadcast("Wave", currentWave)
		spawnWave(currentWave)
		waitForWaveEnd()
		waveActive = false
		clearEnemies()

		if livingPlayerCount() == 0 then
			local winnerName = (lastDeadPlayer and lastDeadPlayer.Parent) and lastDeadPlayer.Name or "Nobody"
			print(string.format("[WaveManager] Party wiped on wave %d. Winner: %s", currentWave, winnerName))
			broadcast("GameOver", winnerName)
			task.wait(RESTART_DELAY)
			restartRound()
		else
			print(string.format("[WaveManager] Wave %d cleared! Next in %ds.", currentWave, WAVE_PAUSE))
			broadcast("Wave", 0)
			task.wait(WAVE_PAUSE)
		end
	end
end)

print("[WaveManager] Loaded.")
