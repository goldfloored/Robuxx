-- Client HUD: Phase 6 — wave number, kill counter, "You Died" message.
-- Built entirely in code so it lives in Rojo (version-controlled) and
-- never disappears with a place revert.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remove any stale HUD (e.g. an old MCP/StarterGui copy) to avoid duplicates.
local stale = playerGui:FindFirstChild("HUD")
if stale then stale:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function makeLabel(name: string, anchor: Vector2, pos: UDim2, size: UDim2, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.AnchorPoint = anchor
	label.Position = pos
	label.Size = size
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = textSize
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.4
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Parent = gui
	return label
end

-- Wave label, top-center.
local waveLabel = makeLabel("Wave", Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0.02), UDim2.fromScale(0.4, 0.07), 32)
waveLabel.Text = "Get Ready..."

-- Kill counter, top-right.
local killLabel = makeLabel("Kills", Vector2.new(1, 0), UDim2.new(1, -16, 0.02, 0), UDim2.fromScale(0.25, 0.06), 24)
killLabel.TextXAlignment = Enum.TextXAlignment.Right
killLabel.Text = "Kills: 0"

-- "You Died" overlay, center, hidden until death.
local diedLabel = makeLabel("YouDied", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.8, 0.2), 56)
diedLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
diedLabel.Text = "YOU DIED"
diedLabel.Visible = false

-- Wave / kill updates from the server.
local waveInfo = ReplicatedStorage:WaitForChild("WaveInfo")
waveInfo.OnClientEvent:Connect(function(kind, value)
	if kind == "Wave" then
		if value and value > 0 then
			waveLabel.Text = "Wave " .. value
		else
			waveLabel.Text = "Get Ready..."
		end
	elseif kind == "Kill" then
		killLabel.Text = "Kills: " .. tostring(value or 0)
	end
end)

-- Show "You Died" on death, hide it on respawn.
local function onCharacter(char: Model)
	diedLabel.Visible = false
	local humanoid = char:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		diedLabel.Visible = true
	end)
end

player.CharacterAdded:Connect(onCharacter)
if player.Character then
	onCharacter(player.Character)
end
