-- LaserGunServer: Phase 3 - Laser Gun (Server Side)
-- Receives LaserFired events from clients, validates hits, deals damage.
-- 2 hits kill an enemy (each hit deals 50 damage, enemies have 100 HP).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local laserFired = ReplicatedStorage:WaitForChild("LaserFired")

-- Track hit counts per enemy so we can confirm 2-hit kills
local hitCounts = {}

local function onLaserFired(player: Player, enemyModel: Model, hitPosition: Vector3)
	-- Sanity checks
	if not player or not player.Character then return end
	if not enemyModel or not enemyModel:IsA("Model") then return end
	if enemyModel.Name ~= "Enemy" then return end
	if not enemyModel.Parent then return end -- already destroyed

	local humanoid = enemyModel:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	-- Distance sanity check (anti-cheat: must be within 500 studs)
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	local enemyRoot = enemyModel.PrimaryPart
	if hrp and enemyRoot then
		local dist = (hrp.Position - enemyRoot.Position).Magnitude
		if dist > 500 then
			warn(string.format("[LaserGunServer] Suspicious shot from %s — distance %.1f", player.Name, dist))
			return
		end
	end

	-- Deal damage
	humanoid:TakeDamage(50)
	print(string.format("[LaserGunServer] %s hit enemy — HP now %.0f", player.Name, humanoid.Health))

	-- Fire back to all clients to show the laser beam visual
	laserFired:FireAllClients(player, hitPosition)
end

laserFired.OnServerEvent:Connect(onLaserFired)

print("[LaserGunServer] Loaded — listening for laser shots.")
