-- EnemyAI: Phase 2 - Chase & Explode
-- Enemies chase the nearest living player.
-- When they touch a player they explode, dealing damage.

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")

-- CONFIG
local DAMAGE = 50           -- damage dealt on explosion (2 hits = dead)
local EXPLOSION_RADIUS = 8  -- stud radius of explosion effect
local CHASE_INTERVAL = 0.5  -- how often the enemy recalculates its path
local DETECT_RANGE = 200    -- studs; enemies ignore players beyond this

-- Get the nearest living (non-spectator) player to a position
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
		-- Ignore spectators (tagged in Phase 6)
		if char:FindFirstChild("Spectator") then continue end
		local dist = (hrp.Position - fromPos).Magnitude
		if dist < nearestDist then
			nearest = player
			nearestDist = dist
		end
	end
	return nearest
end

-- Make the enemy explode and deal damage to nearby players
local function explode(enemy: Model)
	local root = enemy.PrimaryPart
	if not root then return end
	local pos = root.Position

	-- Visual explosion
	local explosion = Instance.new("Explosion")
	explosion.Position = pos
	explosion.BlastRadius = EXPLOSION_RADIUS
	explosion.BlastPressure = 0  -- no physics knockback, we handle damage manually
	explosion.DestroyJointRadiusPercent = 0  -- don't destroy the map
	explosion.Parent = workspace

	-- Deal damage to players in radius
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

	-- Remove the enemy
	enemy:Destroy()
end

-- Chase logic for a single enemy
local function startChase(enemy: Model)
	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	local root = enemy.PrimaryPart
	if not humanoid or not root then return end

	-- Touch detection: explode when touching a player
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

	-- Pathfinding loop
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
					local ok, err = pcall(function()
						path:ComputeAsync(root.Position, targetHRP.Position)
					end)
					if ok and path.Status == Enum.PathStatus.Success then
						local waypoints = path:GetWaypoints()
						for _, wp in ipairs(waypoints) do
							if exploded or not enemy.Parent then break end
							if wp.Action == Enum.PathWaypointAction.Jump then
								humanoid.Jump = true
							end
							humanoid:MoveTo(wp.Position)
							humanoid.MoveToFinished:Wait()
						end
					else
						-- Fallback: direct move if pathfinding fails
						humanoid:MoveTo(targetHRP.Position)
					end
				end
			end
			task.wait(CHASE_INTERVAL)
		end
	end)
end

-- Watch for new enemies added to workspace and start their AI
workspace.ChildAdded:Connect(function(child)
	if child.Name == "Enemy" and child:IsA("Model") then
		-- Small delay to let the model fully initialize
		task.wait(0.1)
		startChase(child)
	end
end)

print("[EnemyAI] Loaded — watching for enemies.")
