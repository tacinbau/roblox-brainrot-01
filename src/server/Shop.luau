-- Shop: everything bought with Cash from the GUI shop panel, plus rebirths and
-- extra base slots. The Slap Glove is a Tool with no script of its own: the
-- client fires the Slap remote when it is swung, and the server validates it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local Conveyor = require(script.Parent:WaitForChild("Conveyor"))
local Wave = require(script.Parent:WaitForChild("Wave"))

local Shop = {}

local context = nil
local slapCooldowns = {} -- [player] = os.clock() of last slap

-- Build the Slap Glove tool: a chunky glove handle, no script inside.
function Shop.buildSlapGlove()
	local tool = Instance.new("Tool")
	tool.Name = "Slap Glove"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.ToolTip = "Slap thieves to make them drop your brainrots!"

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1.5, 2.5, 1)
	handle.Color = Color3.fromRGB(255, 120, 160)
	handle.Material = Enum.Material.SmoothPlastic
	handle.Parent = tool
	return tool
end

function Shop.giveSlapGlove(state)
	local player = state.player
	local backpack = player:FindFirstChild("Backpack")
	if backpack ~= nil and backpack:FindFirstChild("Slap Glove") == nil then
		Shop.buildSlapGlove().Parent = backpack
	end
	local character = player.Character
	if character ~= nil and character:FindFirstChild("Slap Glove") == nil then
		-- Also hand it straight to a live character so it can be used at once.
		Shop.buildSlapGlove().Parent = character
	end
end

-- A slap: knock a nearby thief down and make them drop what they carry.
function Shop.onSlap(player)
	local state = PlayerState.Players[player]
	if state == nil or not state.hasSlap then
		return
	end
	if PlayerState.isKnockedDown(state) then
		return
	end
	local now = os.clock()
	if slapCooldowns[player] ~= nil and now - slapCooldowns[player] < 1.5 then
		return
	end
	slapCooldowns[player] = now

	local character = player.Character
	if character == nil then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return
	end
	local best = nil
	local bestDist = 9
	for _, other in pairs(PlayerState.Players) do
		if other.player ~= player then
			local otherChar = other.player.Character
			local otherRoot = otherChar ~= nil and otherChar:FindFirstChild("HumanoidRootPart") or nil
			if otherRoot ~= nil then
				local dist = (otherRoot.Position - root.Position).Magnitude
				if dist < bestDist then
					best = other
					bestDist = dist
				end
			end
		end
	end
	if best == nil then
		return
	end
	Wave.knockPlayerDown(best, 2)
	context.notify(player, "SLAP! " .. best.player.Name .. " dropped everything!", Color3.fromRGB(255, 220, 90))
	context.notify(best.player, player.Name .. " slapped you! You dropped your brainrot!", Color3.fromRGB(255, 120, 120))
	context.updateHud(best.player)
end

-- Buy one shop item with Cash.
function Shop.onShopBuy(player, itemId)
	local state = PlayerState.Players[player]
	if state == nil then
		return
	end
	local item = nil
	for _, candidate in ipairs(BrainrotData.ShopItems) do
		if candidate.id == itemId then
			item = candidate
			break
		end
	end
	if item == nil then
		return
	end
	if state.cash < item.price then
		context.notify(player, "Not enough Cash for the " .. item.name .. " (" .. BrainrotData.formatCash(item.price) .. ").", Color3.fromRGB(255, 120, 120))
		return
	end

	if itemId == "slap" then
		if state.hasSlap then
			context.notify(player, "You already own the Slap Glove!", Color3.fromRGB(255, 220, 90))
			return
		end
		state.cash = state.cash - item.price
		state.hasSlap = true
		Shop.giveSlapGlove(state)
	elseif itemId == "coil" then
		if state.hasCoil then
			context.notify(player, "You already own the Speed Coil!", Color3.fromRGB(255, 220, 90))
			return
		end
		state.cash = state.cash - item.price
		state.hasCoil = true
		local character = player.Character
		if character ~= nil then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid ~= nil then
				humanoid.WalkSpeed = 24
			end
		end
	elseif itemId == "lock" then
		state.cash = state.cash - item.price
		state.lockUntil = os.time() + BrainrotData.BaseLockDuration
		context.notify(player, "Base Lock active for 60 seconds! Nobody can steal from you.", Color3.fromRGB(120, 255, 140))
	elseif itemId == "charm" then
		state.cash = state.cash - item.price
		state.charmUntil = os.time() + BrainrotData.LuckyCharmDuration
		context.notify(player, "Lucky Charm active for 5 minutes! Mutation luck doubled!", Color3.fromRGB(120, 255, 140))
	end
	context.notify(player, "Bought " .. item.name .. "!", Color3.fromRGB(120, 255, 140))
	PlayerState.syncLeaderstats(state)
	context.updateHud(player)
end

-- Rebirth: pay $25,000 x (rebirths + 1), lose Cash and the whole collection,
-- gain x2 income forever and a new title over your character.
function Shop.onRebirthBuy(player)
	local state = PlayerState.Players[player]
	if state == nil then
		return
	end
	local cost = BrainrotData.rebirthCost(state.rebirths)
	if state.cash < cost then
		context.notify(player, "Rebirth costs " .. BrainrotData.formatCash(cost) .. ". Keep earning!", Color3.fromRGB(255, 120, 120))
		return
	end
	state.cash = 0
	state.rebirths = state.rebirths + 1
	for slot, record in pairs(state.slots) do
		if record ~= nil then
			Conveyor.despawnBrainrot(record)
		end
		state.slots[slot] = nil
	end
	PlayerState.dropCarried(state)
	PlayerState.refreshTitle(state)
	PlayerState.syncLeaderstats(state)
	context.notifyAll(player.Name .. " REBIRTHED! Income is now x" .. tostring(2 ^ state.rebirths) .. " forever!")
	context.updateHud(player)
end

-- Unlock one more base slot with Cash.
function Shop.onUnlockSlot(player, slot)
	local state = PlayerState.Players[player]
	if state == nil then
		return
	end
	slot = math.floor(tonumber(slot) or 0)
	local price = BrainrotData.SlotPrices[slot]
	if price == nil then
		return
	end
	if slot ~= state.unlockedSlots + 1 then
		return
	end
	if state.cash < price then
		context.notify(player, "Slot " .. tostring(slot) .. " costs " .. BrainrotData.formatCash(price) .. ".", Color3.fromRGB(255, 120, 120))
		return
	end
	state.cash = state.cash - price
	state.unlockedSlots = slot
	context.notify(player, "Unlocked base slot " .. tostring(slot) .. "!", Color3.fromRGB(120, 255, 140))
	PlayerState.syncLeaderstats(state)
	context.updateHud(player)
end

function Shop.init(gameContext)
	context = gameContext
	context.remotes.ShopBuy.OnServerEvent:Connect(Shop.onShopBuy)
	context.remotes.RebirthBuy.OnServerEvent:Connect(Shop.onRebirthBuy)
	context.remotes.UnlockSlot.OnServerEvent:Connect(Shop.onUnlockSlot)
	context.remotes.Slap.OnServerEvent:Connect(Shop.onSlap)
end

return Shop
