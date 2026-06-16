-- WaveManager: Phase 1 - Enemy Spawning
-- Enemies spawn in a ring around players each wave.
-- No chasing yet — just spawning. Test: hit Play and see enemies appear.

local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- CONFIG
local WAVE_PAUSE = 5          -- seconds between waves
local BASE_ENEMIES = 5        -- enemies on wave 1
local ENEMIES_PER_WAVE = 3    -- extra enemies added each wave
local SPAWN_RADIUS = 30       -- how far from players enemies spawn

-- State
local currentWave = 0
local _waveActive = false

-- Wait for the EnemyTemplate to exist in ServerStorage
local enemyTemplate = ServerStorage:WaitForChild("EnemyTemplate", 10)
if not enemyTemplate then
	warn("[WaveManager] EnemyTemplate not found in ServerStorage!")
	return
end

-- Get a random spawn position around a target position
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

-- Spawn a single enemy
local function spawnEnemy(spawnPos: Vector3)
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
end

-- Spawn all enemies for a wave
local function spawnWave(waveNumber: number)
	local count = BASE_ENEMIES + (waveNumber - 1) * ENEMIES_PER_WAVE
	print(string.format("[WaveManager] Wave %d starting — spawning %d enemies", waveNumber, count))
	for i = 1, count do
		local center = getRandomPlayerPosition()
		local pos = getSpawnPosition(center)
		spawnEnemy(pos)
		task.wait(0.2)
	end
end

-- Clean up all enemies from a previous wave
local function clearEnemies()
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name == "Enemy" then
			obj:Destroy()
		end
	end
end

-- Main wave loop
local function startWaveLoop()
	while true do
		repeat task.wait(1) until #Players:GetPlayers() > 0

		currentWave += 1
		_waveActive = true
		spawnWave(currentWave)

		task.wait(20)
		clearEnemies()
		_waveActive = false

		print(string.format("[WaveManager] Wave %d over. Next wave in %d seconds.", currentWave, WAVE_PAUSE))
		task.wait(WAVE_PAUSE)
	end
end

task.delay(3, function()
	startWaveLoop()
end)

print("[WaveManager] Loaded — waiting 3 seconds before first wave.")
