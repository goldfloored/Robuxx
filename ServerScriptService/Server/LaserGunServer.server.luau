-- LaserGunServer: Phase 3 - Server Side
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local laserFired = ReplicatedStorage:WaitForChild("LaserFired")
local waveInfo = ReplicatedStorage:WaitForChild("WaveInfo")

local playerKills: { [Player]: number } = {}

Players.PlayerRemoving:Connect(function(player)
	playerKills[player] = nil
end)

local function onLaserFired(player: Player, enemyModel: Model, hitPosition: Vector3)
	if not player or not player.Character then return end
	if not enemyModel or not enemyModel:IsA("Model") then return end
	if enemyModel.Name ~= "Enemy" then return end
	if not enemyModel.Parent then return end
	local humanoid = enemyModel:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	local enemyRoot = enemyModel.PrimaryPart
	if hrp and enemyRoot then
		if (hrp.Position - enemyRoot.Position).Magnitude > 500 then
			warn("[LaserGunServer] Suspicious shot from " .. player.Name)
			return
		end
	end
	humanoid:TakeDamage(50)
	print(string.format("[LaserGunServer] %s hit enemy — HP: %.0f", player.Name, humanoid.Health))
	laserFired:FireAllClients(player, hitPosition)
	if humanoid.Health <= 0 then
		playerKills[player] = (playerKills[player] or 0) + 1
		waveInfo:FireClient(player, "Kill", playerKills[player])
	end
end

laserFired.OnServerEvent:Connect(onLaserFired)
print("[LaserGunServer] Loaded.")
