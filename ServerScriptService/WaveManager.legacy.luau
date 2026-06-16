-- WaveManager: Phase 1 + 4 - Enemy Spawning & Wave Progression
-- Spawns enemies in rings around players, waves escalate, short pause between waves.

local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- CONFIG
local WAVE_PAUSE = 5           -- seconds between waves
local BASE_ENEMIES = 5         -- enemies on wave 1
local ENEMIES_PER_WAVE = 3     -- extra enemies added each wave
local SPAWN_RADIUS = 30        -- how far from players enemies spawn
local WAVE_CLEAR_TIMEOUT = 60  -- max seconds to wait for all enemies to die before forcing next wave

-- State
local currentWave = 0
local waveActive = false
local activeEnemies = 0
local waveCleared = Instance.new("BindableEvent") -- fires when all enemies are dead

-- Notify other scripts about wave state
local waveInfoEvent = ReplicatedStorage:FindFirstChild("WaveInfo")
if not waveInfoEvent then
	waveInfoEvent = Instance.new("RemoteEvent")
	waveInfoEvent.Name = "WaveInfo"
	waveInfoEvent.Parent = ReplicatedStorage
end

-- Broadcast wave number to all clients (for HUD in Phase 5)
local function broadcastWave(waveNumber: number)
	waveInfoEvent:FireAllClients("Wave", waveNumber)
end

-- Get a random spawn position around a center point
local function getSpawnPosition(center: Vector3): Vector3
	local angle = math.random() * 2 * math.pi
	local x = center.X + math.cos(angle) * SPAWN_RADIUS
	local z = center.Z + math.sin(angle) * SPAWN_RADIUS
	return Vector3.new(x, center.Y + 5, z)
end

-- Pick a random living player's position (or map center if none)
local function getRandomPlayerPosition(): Vector3
	local positions = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			table.insert(positions, player.Character.HumanoidRootPart.Position)
		end
	end
	if #positions == 0 then
		return Vector3.new(0, 5, 0)
	end
	return positions[math.random(#positions)]
end

-- Spawn a single enemy and track it
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
	else
		for _, part in ipairs(enemy:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Position = spawnPos
				break
			end
		end
	end

	activeEnemies += 1

	-- Track when this enemy dies
	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			activeEnemies -= 1
			if activeEnemies <= 0 and waveActive then
				waveCleared:Fire()
			end
		end)
	end
end

-- Spawn all enemies for a wave
local function spawnWave(waveNumber: number)
	local count = BASE_ENEMIES + (waveNumber - 1) * ENEMIES_PER_WAVE
	print(string.format("[WaveManager] Wave %d starting — spawning %d enemies", waveNumber, count))
	activeEnemies = 0
	for i = 1, count do
		local center = getRandomPlayerPosition()
		local pos = getSpawnPosition(center)
		spawnEnemy(pos)
		task.wait(0.2)
	end
end

-- Clean up any remaining enemies
local function clearEnemies()
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name == "Enemy" then
			obj:Destroy()
		end
	end
	activeEnemies = 0
end

-- Wait for all enemies to die OR timeout
local function waitForWaveClear()
	if activeEnemies <= 0 then return end
	local cleared = false
	local conn = waveCleared.Event:Connect(function()
		cleared = true
	end)
	local elapsed = 0
	while not cleared and elapsed < WAVE_CLEAR_TIMEOUT do
		task.wait(1)
		elapsed += 1
	end
	conn:Disconnect()
	if not cleared then
		warn(string.format("[WaveManager] Wave %d timed out — forcing next wave", currentWave))
	end
end

-- Count living players
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

-- Main wave loop
local function startWaveLoop()
	while true do
		-- Wait for at least one living player
		repeat task.wait(1) until livingPlayerCount() > 0

		currentWave += 1
		waveActive = true

		print(string.format("[WaveManager] === WAVE %d ===", currentWave))
		broadcastWave(currentWave)
		spawnWave(currentWave)

		-- Wait until all enemies are killed (or timeout)
		waitForWaveClear()
		waveActive = false
		clearEnemies() -- clean up any stragglers

		print(string.format("[WaveManager] Wave %d cleared! Next wave in %ds.", currentWave, WAVE_PAUSE))
		broadcastWave(0) -- 0 = between waves signal for HUD

		task.wait(WAVE_PAUSE)
	end
end

-- Kick off
task.delay(3, function()
	startWaveLoop()
end)

print("[WaveManager] Loaded — waiting 3 seconds before first wave.")
