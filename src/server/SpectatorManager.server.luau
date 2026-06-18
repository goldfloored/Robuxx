-- SpectatorManager: Phase 7 — turn dead players into ghosts that enemies ignore.
-- Purely cosmetic + the "Spectator" tag. The round lifecycle (no respawn until
-- the party wipes, then restart) is owned by WaveManager.
local Players = game:GetService("Players")

local GHOST_TRANSPARENCY = 0.6

local function makeGhost(player: Player, character: Model)
	-- Tag so EnemyAI / WaveManager ignore this player (Phase 7 hook they already read).
	if not character:FindFirstChild("Spectator") then
		local tag = Instance.new("BoolValue")
		tag.Name = "Spectator"
		tag.Parent = character
	end

	-- Ghost the body (leave HumanoidRootPart solid so the ragdoll doesn't sink).
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Transparency = GHOST_TRANSPARENCY
			part.CanCollide = false
		end
	end

	-- Drop their weapon so a ghost can't shoot.
	for _, tool in ipairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") then tool:Destroy() end
	end
	local equipped = character:FindFirstChildOfClass("Tool")
	if equipped then equipped:Destroy() end

	print(string.format("[SpectatorManager] %s is now spectating.", player.Name))
end

local function onCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		makeGhost(player, character)
	end)
end

local function onPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	if player.Character then
		onCharacter(player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayer(player)
end

print("[SpectatorManager] Loaded.")
