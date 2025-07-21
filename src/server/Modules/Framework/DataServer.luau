-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Variables
local ON_PLAYER_REMOVING_CALLBACKS = {}

local IS_STUDIO = RunService:IsStudio()

local STUDIO_VERSION = "0.0.0"
local GAME_VERSION = "0.0.0"

local MOCK = false

local DATA_VERSION = if IS_STUDIO then STUDIO_VERSION else GAME_VERSION

local MAX_DATA_RETRIES = 10
local DATA_RETRY_DELAY = 1

local Packages = ReplicatedStorage.Packages
local Shared = ReplicatedStorage.Shared

local ProfileStore = require(Packages.ProfileStore)

local DATA_TEMPLATE = require(Shared.Configs.Template)

local PlayersData: { [Player]: typeof(DATA_TEMPLATE) } = {}
local PlayersSessions: { [Player]: typeof(ProfileStore.New()) } = {}

-- Module
local Data = {
	Client = {},
}

function Data.Client:Get(...: any)
	return self.Server:Get(...)
end

function Data.Client.Changed(...: any)
	return
end

function Data.Client.Loaded(...: any)
	return
end

function Data:Get(player: Player)
	return PlayersData[player]
end

function Data:GetAsync(player: Player, timeout: number?)
	local start = os.clock()

	repeat
		task.wait()
	until PlayersData[player] or os.clock() - start >= (timeout or 60)

	return PlayersData[player]
end

function Data:GetRaw(player: Player)
	local mimic = self:Get(player)

	if not mimic then
		return
	end

	return getmetatable(mimic).__index
end

function Data:Create(player: Player)
	local playerSession
	local userId = player.UserId

	for _ = 1, MAX_DATA_RETRIES do
		playerSession = self._profileStore:StartSessionAsync(`{userId}_{DATA_VERSION}`, {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})

		if playerSession then
			break
		end

		task.wait(DATA_RETRY_DELAY)
	end

	if not playerSession then
		return player:Kick(
			`Failed to load session after {MAX_DATA_RETRIES * DATA_RETRY_DELAY} seconds and {MAX_DATA_RETRIES} attempts.`
		)
	end

	playerSession:AddUserId(userId)

	playerSession:Reconcile()

	do
		local onSessionEnd

		onSessionEnd = playerSession.OnSessionEnd:Connect(function()
			local callbacks = ON_PLAYER_REMOVING_CALLBACKS[player]

			if callbacks then
				for i = 1, #callbacks do
					local callback = callbacks[i]

					if callback then
						task.spawn(callback, player)
					end
				end
			end

			ON_PLAYER_REMOVING_CALLBACKS[player] = nil

			PlayersData[player] = nil
			PlayersSessions[player] = nil

			onSessionEnd:Disconnect()
		end)
	end

	local playerData = playerSession.Data

	local dataMimic = setmetatable({}, {
		__index = playerData,
		__tostring = function()
			return "Print a specific index of the player data"
		end,
		__newindex = function(_, key: string, newValue: any)
			local oldValue = playerData[key]

			playerData[key] = newValue

			Data.Client.Changed:Fire(player, key, oldValue, newValue)
		end,
	})

	return playerData, dataMimic, playerSession
end

function Data:OnPlayerRemoving(player: Player, callback: () -> any)
	ON_PLAYER_REMOVING_CALLBACKS[player] = ON_PLAYER_REMOVING_CALLBACKS[player] or {}

	table.insert(ON_PLAYER_REMOVING_CALLBACKS[player], callback)
end

function Data.onPlayerAdded(player: Player)
	local rawData, mimicData, session = Data:Create(player)

	PlayersData[player] = mimicData
	PlayersSessions[player] = session

	Data.Client.Loaded:Fire(player, rawData)
end

function Data.onPlayerRemoving(player: Player)
	local playerSession = PlayersSessions[player]

	if not playerSession then
		return
	end

	playerSession:EndSession()
end

do
	local profileStore = ProfileStore.New(if IS_STUDIO then "Studio" else "Game", DATA_TEMPLATE)

	Data._profileStore = if MOCK then profileStore.Mock else profileStore
end

do
	Players.PlayerAdded:Connect(Data.onPlayerAdded)
	Players.PlayerRemoving:Connect(Data.onPlayerRemoving)

	for _, player in Players:GetPlayers() do
		task.spawn(Data.onPlayerAdded, player)
	end
end

return Data
