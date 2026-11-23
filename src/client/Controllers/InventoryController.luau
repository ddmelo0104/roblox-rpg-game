--!strict
--[[
	InventoryController.luau
	The client's copy of the player's bag and equipment (US-017) and of their fame totals (US-029), as
	the server last sent them, and the requests to equip and unequip (US-018). The server decides;
	this copy is only for showing and for predicting the cooldowns. The inventory and mastery screens
	read it.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared:WaitForChild("Items") :: ModuleScript)
local Mastery = require(Shared:WaitForChild("Mastery") :: ModuleScript)
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)
local ItemsConfig = require(Shared:WaitForChild("Config"):WaitForChild("Items") :: ModuleScript)
local Notices = require(script.Parent.Parent.Notices)

-- Game text (Portuguese).
local INVENTORY_NAME = "Inventário"

local InventoryController = {}

local bag: { any } = {}
local equipped: { [string]: any } = {}
local progress: any = Mastery.newProgress()
local changedEvent = Instance.new("BindableEvent")

-- Fires after every new copy from the server (inventory or fame).
InventoryController.changed = changedEvent.Event

-- The items in the bag (copies).
function InventoryController.bag(): { any }
	return bag
end

-- What the character wears, by slot (copies).
function InventoryController.equipped(): { [string]: any }
	return equipped
end

-- The fame totals of each item kind and line (a copy).
function InventoryController.progress(): any
	return progress
end

-- The attributes the equipment gives, with the specialization and mastery levels, computed the same
-- way as on the server.
function InventoryController.stats(): any
	return Items.characterStats(equipped, Mastery.levelsOf(progress))
end

-- Asks the server to equip the bag item with this uid.
function InventoryController.equip(uid: string)
	Remotes.event("RequestEquip"):FireServer(uid)
end

-- Asks the server to move what is worn in `slot` back to the bag.
function InventoryController.unequip(slot: string)
	if #bag >= ItemsConfig.INVENTORY_SIZE then
		Notices.showReason(INVENTORY_NAME, "BagFull")
		return
	end
	Remotes.event("RequestUnequip"):FireServer(slot)
end

function InventoryController:Start()
	Remotes.event("InventoryUpdate").OnClientEvent:Connect(function(newBag: { any }, newEquipped: { [string]: any })
		bag = newBag
		equipped = newEquipped
		changedEvent:Fire()
	end)
	Remotes.event("ProgressUpdate").OnClientEvent:Connect(function(newProgress: any)
		if newProgress then
			progress = newProgress
			changedEvent:Fire()
		end
	end)
end

return InventoryController
