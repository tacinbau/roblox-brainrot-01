-- PlayerState: one record per player, kept in one place on the server.
-- Cash, income, rebirths, the base they own, the brainrots standing on it,
-- shop items, lock and charm timers, and what they are carrying right now.
-- Saved to a DataStore in a pcall; the game never depends on the save working.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local PlayerState = {}
PlayerState.Players = {} -- [player] = state table

local STORE_NAME = "BrainrotBazaarV1"
local store = nil
local ok, result = pcall(function()
	return DataStoreService:GetDataStore(STORE_NAME)
end)
if ok then
	store = result
end

-- 8 base plots around the plaza, matching the pads in default.project.json.
PlayerState.BasePlots = {
	Vector3.new(46, 0, 19),
	Vector3.new(19, 0, 46),
	Vector3.new(-19, 0, 46),
	Vector3.new(-46, 0, 19),
	Vector3.new(-46, 0, -19),
	Vector3.new(-19, 0, -46),
	Vector3.new(19, 0, -46),
	Vector3.new(46, 0, -19),
}

-- Slot offsets inside a 20x20 base pad: two rows of five.
local SLOT_OFFSETS = {}
for row = 0, 1 do
	for col = 0, 4 do
		table.insert(SLOT_OFFSETS, Vector3.new(-8 + col * 4, 0, -4 + row * 8))
	end
end

function PlayerState.newState(player)
	return {
		player = player,
		cash = 0,
		rebirths = 0,
		baseIndex = 0,
		slots = {}, -- [slot] = brainrot record or nil
		unlockedSlots = BrainrotData.FreeSlots,
		hasSlap = false,
		hasCoil = false,
		lockUntil = 0,
		charmUntil = 0,
		carrying = nil, -- brainrot record being carried, or nil
		stealChannel = nil, -- { brainrot, startedAt } while channelling a steal
		knockedUntil = 0,
		leaderCash = nil,
		leaderIncome = nil,
		leaderRebirths = nil,
	}
end

-- The world position of a slot on a player's base. Pads sit with their top at y = 1.
function PlayerState.slotPosition(state, slot)
	local plot = PlayerState.BasePlots[state.baseIndex]
	local offset = SLOT_OFFSETS[slot]
	return plot + offset + Vector3.new(0, 1, 0)
end

function PlayerState.baseCenter(state)
	return PlayerState.BasePlots[state.baseIndex]
end

-- Is this player inside their own base (the safe zone during a wave)?
function PlayerState.isInOwnBase(state)
	local character = state.player.Character
	if character == nil then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return false
	end
	local center = PlayerState.baseCenter(state)
	local delta = root.Position - center
	return math.abs(delta.X) < 12 and math.abs(delta.Z) < 12
end

-- Income per second from everything standing on the player's base, times the
-- rebirth multiplier (x2 per rebirth).
function PlayerState.incomePerSecond(state)
	local total = 0
	for _, record in pairs(state.slots) do
		if record ~= nil then
			total = total + record.income
		end
	end
	return total * (2 ^ state.rebirths)
end

function PlayerState.firstFreeSlot(state)
	for slot = 1, state.unlockedSlots do
		if state.slots[slot] == nil then
			return slot
		end
	end
	return nil
end

function PlayerState.isBaseLocked(state)
	return os.time() < state.lockUntil
end

function PlayerState.hasLuckyCharm(state)
	return os.time() < state.charmUntil
end

function PlayerState.isKnockedDown(state)
	return os.clock() < state.knockedUntil
end

-- Build the leaderstats folder (Cash / Income / Rebirths) and wire it to the state.
function PlayerState.createLeaderstats(player, state)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	folder.Parent = player

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = state.cash
	cash.Parent = folder

	local income = Instance.new("IntValue")
	income.Name = "Income"
	income.Value = 0
	income.Parent = folder

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = state.rebirths
	rebirths.Parent = folder

	state.leaderCash = cash
	state.leaderIncome = income
	state.leaderRebirths = rebirths
end

function PlayerState.syncLeaderstats(state)
	if state.leaderCash ~= nil then
		state.leaderCash.Value = math.floor(state.cash)
	end
	if state.leaderIncome ~= nil then
		state.leaderIncome.Value = math.floor(PlayerState.incomePerSecond(state))
	end
	if state.leaderRebirths ~= nil then
		state.leaderRebirths.Value = state.rebirths
	end
end

-- Load a saved record (cash, rebirths, unlocked slots). The collection itself
-- is never saved: brainrots are earned fresh each session.
function PlayerState.loadSaved(player, state)
	if store == nil then
		return
	end
	local okLoad, saved = pcall(function()
		return store:GetAsync("player_" .. tostring(player.UserId))
	end)
	if not okLoad or type(saved) ~= "table" then
		return
	end
	if type(saved.cash) == "number" then
		state.cash = math.max(0, saved.cash)
	end
	if type(saved.rebirths) == "number" then
		state.rebirths = math.max(0, math.floor(saved.rebirths))
	end
	if type(saved.unlockedSlots) == "number" then
		state.unlockedSlots = math.clamp(math.floor(saved.unlockedSlots), BrainrotData.FreeSlots, BrainrotData.MaxSlots)
	end
	if saved.hasCoil == true then
		state.hasCoil = true
	end
	if saved.hasSlap == true then
		state.hasSlap = true
	end
end

function PlayerState.save(state)
	if store == nil then
		return
	end
	local data = {
		cash = math.floor(state.cash),
		rebirths = state.rebirths,
		unlockedSlots = state.unlockedSlots,
		hasCoil = state.hasCoil,
		hasSlap = state.hasSlap,
	}
	pcall(function()
		store:SetAsync("player_" .. tostring(state.player.UserId), data)
	end)
end

-- Give a player their base, leaderstats and title tag when they join.
function PlayerState.onPlayerAdded(player)
	local state = PlayerState.newState(player)
	-- First free base plot; fall back to plot 1 if the server is full.
	local taken = {}
	for _, other in pairs(PlayerState.Players) do
		taken[other.baseIndex] = true
	end
	for i = 1, #PlayerState.BasePlots do
		if not taken[i] then
			state.baseIndex = i
			break
		end
	end
	if state.baseIndex == 0 then
		state.baseIndex = 1
	end
	PlayerState.loadSaved(player, state)
	PlayerState.createLeaderstats(player, state)
	PlayerState.syncLeaderstats(state)
	PlayerState.Players[player] = state

	player.CharacterAdded:Connect(function(character)
		PlayerState.onCharacterSpawned(player, state, character)
	end)
	return state
end

-- When the character spawns: move them to the spawn pad, apply the Speed Coil,
-- and hang their rebirth title over their head.
function PlayerState.onCharacterSpawned(player, state, character)
	local humanoid = character:WaitForChild("Humanoid")
	if state.hasCoil then
		humanoid.WalkSpeed = 24
	end
	task.wait(0.2)
	local root = character:FindFirstChild("HumanoidRootPart")
	if root ~= nil then
		root.CFrame = CFrame.new(0, 3, 80)
	end
	local head = character:FindFirstChild("Head")
	if head ~= nil then
		local tag = Instance.new("BillboardGui")
		tag.Name = "RebirthTitle"
		tag.Size = UDim2.fromOffset(160, 30)
		tag.StudsOffset = Vector3.new(0, 3.2, 0)
		tag.AlwaysOnTop = true
		tag.Parent = head
		local label = Instance.new("TextLabel")
		label.Name = "TitleLabel"
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = BrainrotData.titleFor(state.rebirths)
		label.TextScaled = true
		label.Font = Enum.Font.FredokaOne
		label.TextColor3 = Color3.fromRGB(255, 220, 80)
		label.TextStrokeTransparency = 0
		label.Parent = tag
	end
end

function PlayerState.refreshTitle(state)
	local character = state.player.Character
	if character == nil then
		return
	end
	local head = character:FindFirstChild("Head")
	if head == nil then
		return
	end
	local tag = head:FindFirstChild("RebirthTitle")
	if tag == nil then
		return
	end
	local label = tag:FindFirstChild("TitleLabel")
	if label ~= nil then
		label.Text = BrainrotData.titleFor(state.rebirths)
	end
end

-- Drop whatever the player is carrying, back to its owner's base if the slot
-- is still free, otherwise it wanders off (despawns).
function PlayerState.dropCarried(state)
	local record = state.carrying
	if record == nil then
		return
	end
	state.carrying = nil
	if record.model ~= nil then
		record.model.Parent = workspace
	end
	local owner = record.owner
	if owner ~= nil and owner.slots[record.slot] == nil then
		owner.slots[record.slot] = record
		record.state = "base"
		local pos = PlayerState.slotPosition(owner, record.slot)
		if record.model ~= nil then
			record.model:SetPrimaryPartCFrame(CFrame.new(pos))
		end
	else
		record.state = "gone"
		if record.model ~= nil then
			record.model:Destroy()
		end
	end
end

function PlayerState.onPlayerRemoving(player)
	local state = PlayerState.Players[player]
	if state == nil then
		return
	end
	PlayerState.dropCarried(state)
	for _, record in pairs(state.slots) do
		if record ~= nil and record.model ~= nil then
			record.model:Destroy()
		end
	end
	PlayerState.save(state)
	PlayerState.Players[player] = nil
end

Players.PlayerAdded:Connect(PlayerState.onPlayerAdded)
Players.PlayerRemoving:Connect(PlayerState.onPlayerRemoving)

return PlayerState
