local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages

local Unify = require(Packages.Unify)

do
	Unify:Add(script.Parent.Modules)
		:andThen(function()
			print("Modules loaded successfully.")
		end)
		:catch(function(err)
			warn("Failed to load modules:", err)
		end)
		:finally(function()
			print("Loading complete.")
		end)
end
