-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variables
local ClicksServer

local Packages = ReplicatedStorage.Packages

local Unify = require(Packages.Unify)

-- Module
local Clicks = {}

function Clicks.onActivated()
	ClicksServer:Click()
end

do
	ClicksServer = Unify:Get("ClicksServer")

	-- GuiButton.Activated:Connect(Clicks.onActivated)

	task.delay(5, Clicks.onActivated)
end

return Clicks
