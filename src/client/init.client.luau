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
local diedLabel = makeLabel("YouDied", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.42), UDim2.fromScale(0.8, 0.2), 56)
diedLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
diedLabel.Text = "YOU DIED"
diedLabel.Visible = false

-- Winner / restart banner (Phase 7), center, hidden until the party wipes.
local gameOverLabel = makeLabel("GameOver", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.58), UDim2.fromScale(0.9, 0.18), 36)
gameOverLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
gameOverLabel.Visible = false

-- Center crosshair — the laser gun now aims at screen centre, so mark it. Vital
-- on mobile/console, which have no mouse cursor. Built from two thin bars (a "+").
local crosshair = Instance.new("Frame")
crosshair.Name = "Crosshair"
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.fromScale(0.5, 0.5)
crosshair.Size = UDim2.fromOffset(28, 28)
crosshair.BackgroundTransparency = 1
crosshair.Parent = gui

local function makeBar(size: UDim2)
	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.Position = UDim2.fromScale(0.5, 0.5)
	bar.Size = size
	bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	bar.BackgroundTransparency = 0.1
	bar.BorderSizePixel = 0
	bar.Parent = crosshair
	local stroke = Instance.new("UIStroke") -- black outline so it shows on any background
	stroke.Thickness = 1
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Transparency = 0.35
	stroke.Parent = bar
end

makeBar(UDim2.fromOffset(28, 3)) -- horizontal
makeBar(UDim2.fromOffset(3, 28)) -- vertical

-- Welcome banner — greet the player by name with their personal Roblox UserId on
-- join, then fade it out. (Read locally here; the server's PlayerRegistry hook is
-- what records every user's id centrally.)
local welcome = makeLabel("Welcome", Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0.16), UDim2.fromScale(0.7, 0.06), 24)
welcome.TextColor3 = Color3.fromRGB(130, 235, 255)
welcome.Text = string.format("Welcome, %s!   ·   ID %d", player.DisplayName, player.UserId)
task.delay(6, function()
	for a = 0, 1, 0.08 do
		welcome.TextTransparency = a
		welcome.TextStrokeTransparency = math.clamp(0.4 + a, 0, 1)
		task.wait(0.04)
	end
	welcome.Visible = false
end)

-- Wave / kill / game-over updates from the server.
local waveInfo = ReplicatedStorage:WaitForChild("WaveInfo")
waveInfo.OnClientEvent:Connect(function(kind, value)
	if kind == "Wave" then
		gameOverLabel.Visible = false -- new round/wave starting
		if value and value > 0 then
			waveLabel.Text = "Wave " .. value
		else
			waveLabel.Text = "Get Ready..."
		end
	elseif kind == "Kill" then
		killLabel.Text = "Kills: " .. tostring(value or 0)
	elseif kind == "GameOver" then
		gameOverLabel.Text = string.format("🏆 %s survived the longest!\nRestarting...", tostring(value))
		gameOverLabel.Visible = true
	end
end)

-- Show "You Died" on death, hide overlays on respawn.
local function onCharacter(char: Model)
	diedLabel.Visible = false
	gameOverLabel.Visible = false
	crosshair.Visible = true
	local humanoid = char:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		diedLabel.Visible = true
		crosshair.Visible = false -- no aiming while spectating
	end)
end

player.CharacterAdded:Connect(onCharacter)
if player.Character then
	onCharacter(player.Character)
end
