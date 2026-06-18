-- PlayerRegistry: a SINGLE PlayerAdded hook that captures every user who joins,
-- so the whole player base of this server can be read from one place.
local Players = game:GetService("Players")

export type UserInfo = { name: string, displayName: string, userId: number, joinedAt: number }

-- UserId -> info, for everyone who has joined this server session.
local users: { [number]: UserInfo } = {}

local function trackedCount(): number
	local n = 0
	for _ in pairs(users) do n += 1 end
	return n
end

local function register(player: Player)
	users[player.UserId] = {
		name = player.Name,
		displayName = player.DisplayName,
		userId = player.UserId,
		joinedAt = os.time(),
	}
	print(string.format("[PlayerRegistry] %s (@%s) joined — UserId %d  [%d tracked]",
		player.DisplayName, player.Name, player.UserId, trackedCount()))
end

-- The single hook: every join flows through here.
Players.PlayerAdded:Connect(register)
for _, player in ipairs(Players:GetPlayers()) do
	register(player)
end

-- One place any other server script can read the whole list from:
--   local users = _G.GetRegisteredUsers()   -- { [userId] = { name, displayName, ... } }
_G.GetRegisteredUsers = function(): { [number]: UserInfo }
	return users
end

print("[PlayerRegistry] Loaded.")
