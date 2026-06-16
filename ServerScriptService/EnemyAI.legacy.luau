-- EnemyAI: Phase 2 - Chase & Explode
-- Enemies chase the nearest living player.
-- When they touch a player they explode, dealing damage.

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")

-- CONFIG
local DAMAGE = 50
local EXPLOSION_RADIUS = 8
local CHASE_INTERVAL = 0.5
local DETECT_RANGE = 200

local function getNearestPlayer(fromPos: Vector3)
	local nearest = nil
	local nearestDist = DETECT_RANGE
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if not char then continue end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then continue end
		if hum.Health <= 0 then continue end
		if char:FindFirstChild("Spectator") then continue end
		local dist = (hrp.Position - fromPos).Magnitude
		if dist < nearestDist then
			nearest = player
			nearestDist = dist
		end
	end
	return nearest
end

local function explode(enemy: Model)
	local root = enemy.PrimaryPart
	if not root then return end
	local pos = root.Position
	local explosion = Instance.new("Explosion")
	explosion.Position = pos
	explosion.BlastRadius = EXPLOSION_RADIUS
	explosion.BlastPressure = 0
	explosion.DestroyJointRadiusPercent = 0
	explosion.Parent = workspace
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if not char then continue end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then continue end
		if char:FindFirstChild("Spectator") then continue end
		if (hrp.Position - pos).Magnitude <= EXPLOSION_RADIUS then
			hum:TakeDamage(DAMAGE)
		end
	end
	enemy:Destroy()
end

local function startChase(enemy: Model)
	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	local root = enemy.PrimaryPart
	if not humanoid or not root then return end
	local exploded = false
	for _, part in ipairs(enemy:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Touched:Connect(function(hit)
				if exploded then return end
				local char = hit.Parent
				local player = Players:GetPlayerFromCharacter(char)
				if not player then return end
				local hum = char:FindFirstChildOfClass("Humanoid")
				if not hum or hum.Health <= 0 then return end
				if char:FindFirstChild("Spectator") then return end
				exploded = true
				explode(enemy)
			end)
		end
	end
	task.spawn(function()
		while enemy and enemy.Parent and not exploded do
			local target = getNearestPlayer(root.Position)
			if target and target.Character then
				local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
				if targetHRP then
					local path = PathfindingService:CreatePath({
						AgentHeight = 5,
						AgentRadius = 2,
						AgentCanJump = true,
					})
					local ok = pcall(function()
						path:ComputeAsync(root.Position, targetHRP.Position)
					end)
					if ok and path.Status == Enum.PathStatus.Success then
						for _, wp in ipairs(path:GetWaypoints()) do
							if exploded or not enemy.Parent then break end
							if wp.Action == Enum.PathWaypointAction.Jump then
								humanoid.Jump = true
							end
							humanoid:MoveTo(wp.Position)
							humanoid.MoveToFinished:Wait()
						end
					else
						humanoid:MoveTo(targetHRP.Position)
					end
				end
			end
			task.wait(CHASE_INTERVAL)
		end
	end)
end

workspace.ChildAdded:Connect(function(child)
	if child.Name == "Enemy" and child:IsA("Model") then
		task.wait(0.1)
		startChase(child)
	end
end)

print("[EnemyAI] Loaded — watching for enemies.")
