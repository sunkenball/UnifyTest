local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Variables
local Packages = ReplicatedStorage.Packages

local Unify = require(Packages.Unify)

local DataServer: typeof(require(script.Parent.Parent.Framework.DataServer))

-- Module
local Clicks = {
	Client = {},
}

function Clicks.Client:Click(...: any)
	return self.Server:Click(...)
end

function Clicks:Click(player: Player)
	local playerData = DataServer:GetAsync(player)

	if not playerData then
		return
	end

	print(playerData.Clicks)

	playerData.Clicks += 1

	print(playerData.Clicks)
end

do
	DataServer = Unify:Get("DataServer")
end

return Clicks
