-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variables
local CLIENT_DATA
local ON_CHANGED_CALLBACKS = {}
local ON_LOADED_CALLBACKS = {}

local Packages = ReplicatedStorage.Packages

local DataServer

local Unify = require(Packages.Unify)
local Promise = require(Packages.Promise)

-- Types
type PlayerData = any
type Promise<T> = typeof(Promise.new())

-- Module
local Data = {}

do
	function Data:Get(): PlayerData?
		return CLIENT_DATA
	end

	function Data:GetAsync(): Promise<PlayerData>
		return Unify:Get("Data"):andThen(function(data: PlayerData)
			CLIENT_DATA = data
			return data
		end)
	end

	function Data:OnChanged(key: string, callback: (oldValue: any, newValue: any) -> any)
		local onChangedCallbacks = ON_CHANGED_CALLBACKS[key]

		if not onChangedCallbacks then
			onChangedCallbacks = {}

			ON_CHANGED_CALLBACKS[key] = onChangedCallbacks
		end

		table.insert(onChangedCallbacks, callback)
	end

	function Data:OnLoaded(callback: (playerData: PlayerData) -> any)
		local onLoadedCallbacks = ON_LOADED_CALLBACKS

		if not onLoadedCallbacks then
			onLoadedCallbacks = {}

			ON_LOADED_CALLBACKS = onLoadedCallbacks
		end

		table.insert(onLoadedCallbacks, callback, CLIENT_DATA)
	end
end

do
	DataServer = Unify:Get("DataServer")

	do
		DataServer.Changed:Connect(function(key: string, oldValue: any, newValue: any)
			print("Data changed:", key, oldValue, newValue)

			CLIENT_DATA[key] = newValue

			do
				local onChangedCallbacks = ON_CHANGED_CALLBACKS[key]

				if onChangedCallbacks then
					for i = 1, #onChangedCallbacks do
						local callback = onChangedCallbacks[i]

						if callback then
							task.spawn(callback, oldValue, newValue)
						end
					end
				end
			end
		end)

		DataServer.Loaded:Once(function(playerData: PlayerData)
			print("Data loaded:", playerData)

			CLIENT_DATA = playerData

			do
				local onLoadedCallbacks = ON_LOADED_CALLBACKS

				if onLoadedCallbacks then
					for i = 1, #onLoadedCallbacks do
						local callback = onLoadedCallbacks[i]

						if callback then
							task.spawn(callback, playerData)
						end
					end
				end
			end
		end)
	end
end

return Data
