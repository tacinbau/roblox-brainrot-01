-- Brainrot Bazaar: main server script. Builds the remotes, wires the modules
-- together, ticks every player's income once a second, and saves progress.
-- The loop: claim brainrots off the belt, park them on your base, earn $/s,
-- steal from rivals, outrun the wave, rebirth and climb the ladder.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local Conveyor = require(script.Parent:WaitForChild("Conveyor"))
local Wave = require(script.Parent:WaitForChild("Wave"))
local Shop = require(script.Parent:WaitForChild("Shop"))

-- ---------------------------------------------------------------- remotes

local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "BrainrotRemotes"
remotesFolder.Parent = ReplicatedStorage

local function makeRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotesFolder
	return remote
end

local remotes = {
	UpdateHud = makeRemote("UpdateHud"),
	Notify = makeRemote("Notify"),
	WaveAlert = makeRemote("WaveAlert"),
	CarryProgress = makeRemote("CarryProgress"),
	ShopBuy = makeRemote("ShopBuy"),
	RebirthBuy = makeRemote("RebirthBuy"),
	UnlockSlot = makeRemote("UnlockSlot"),
	Slap = makeRemote("Slap"),
}

-- ---------------------------------------------------------------- helpers

local context = {}

function context.notify(player, text, color)
	remotes.Notify:FireClient(player, text, color)
end

function context.notifyAll(text, color)
	for _, player in ipairs(Players:GetPlayers()) do
		remotes.Notify:FireClient(player, text, color or Color3.fromRGB(255, 255, 255))
	end
end

-- The HUD snapshot the client renders: cash, income, rebirths, every base slot,
-- the next slot's price, lock and charm timers, and the rebirth cost.
function context.updateHud(player)
	local state = PlayerState.Players[player]
	if state == nil then
		return
	end
	local slots = {}
	for slot = 1, state.unlockedSlots do
		local record = state.slots[slot]
		if record ~= nil then
			slots[slot] = { name = record.def.name, rarity = record.def.rarity, mutation = record.mutation, income = record.income }
		else
			slots[slot] = false
		end
	end
	local nextSlot = nil
	if state.unlockedSlots < BrainrotData.MaxSlots then
		nextSlot = { slot = state.unlockedSlots + 1, price = BrainrotData.SlotPrices[state.unlockedSlots + 1] }
	end
	remotes.UpdateHud:FireClient(player, {
		cash = math.floor(state.cash),
		income = math.floor(PlayerState.incomePerSecond(state)),
		rebirths = state.rebirths,
		slots = slots,
		nextSlot = nextSlot,
		lockSeconds = math.max(0, state.lockUntil - os.time()),
		charmSeconds = math.max(0, state.charmUntil - os.time()),
		hasSlap = state.hasSlap,
		hasCoil = state.hasCoil,
		rebirthCost = BrainrotData.rebirthCost(state.rebirths),
		title = BrainrotData.titleFor(state.rebirths),
	})
end

context.remotes = remotes

-- ---------------------------------------------------------------- world dressing

-- Paint the 10 slot pads on every base so players can see where brainrots go,
-- and hang an owner label over each base plot.
local function dressBases()
	for index, center in ipairs(PlayerState.BasePlots) do
		local pad = workspace:FindFirstChild("BasePad" .. tostring(index))
		if pad ~= nil then
			-- Owner label floating over the base.
			local tag = Instance.new("BillboardGui")
			tag.Name = "BaseLabel"
			tag.Size = UDim2.fromOffset(200, 40)
			tag.StudsOffset = Vector3.new(0, 9, 0)
			tag.AlwaysOnTop = true
			tag.Parent = pad
			local label = Instance.new("TextLabel")
			label.Name = "OwnerLabel"
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Text = "Base " .. tostring(index)
			label.TextScaled = true
			label.Font = Enum.Font.FredokaOne
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
			label.TextStrokeTransparency = 0
			label.Parent = tag
		end
		-- Slot pads: one small glowing tile per slot.
		for slot = 1, BrainrotData.MaxSlots do
			local pos = PlayerState.slotPosition({ baseIndex = index }, slot)
			local tile = Instance.new("Part")
			tile.Name = "SlotPad"
			tile.Size = Vector3.new(3.4, 0.2, 3.4)
			tile.Color = Color3.fromRGB(255, 255, 255)
			tile.Transparency = 0.6
			tile.Material = Enum.Material.Neon
			tile.Anchored = true
			tile.CanCollide = false
			tile.CanQuery = false
			tile.Position = Vector3.new(pos.X, 1.1, pos.Z)
			tile.Parent = workspace
		end
	end
end

-- Put the new owner's name on their base label.
local function labelBase(state)
	local pad = workspace:FindFirstChild("BasePad" .. tostring(state.baseIndex))
	if pad == nil then
		return
	end
	local tag = pad:FindFirstChild("BaseLabel")
	if tag == nil then
		return
	end
	local label = tag:FindFirstChild("OwnerLabel")
	if label ~= nil then
		label.Text = state.player.Name .. "'s Base"
	end
end

-- ---------------------------------------------------------------- boot

dressBases()
Conveyor.init(context)
Wave.init(context)
Shop.init(context)

Players.PlayerAdded:Connect(function(player)
	local state = PlayerState.Players[player]
	if state ~= nil then
		labelBase(state)
		if state.hasSlap then
			Shop.giveSlapGlove(state)
		end
		task.wait(1)
		context.updateHud(player)
		context.notify(player, "Welcome to Brainrot Bazaar! Touch a brainrot on the belt to claim it!", Color3.fromRGB(140, 220, 255))
	end
end)

-- Players who joined before this script ran (Studio solo play).
for _, player in ipairs(Players:GetPlayers()) do
	local state = PlayerState.Players[player]
	if state ~= nil then
		labelBase(state)
	end
end

-- Income tick: every second, pay every player their base income and refresh
-- their HUD and leaderstats.
task.spawn(function()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			local state = PlayerState.Players[player]
			if state ~= nil then
				state.cash = state.cash + PlayerState.incomePerSecond(state)
				PlayerState.syncLeaderstats(state)
				context.updateHud(player)
			end
		end
	end
end)

-- Save progress every 60 seconds, in a pcall inside PlayerState.save.
task.spawn(function()
	while true do
		task.wait(60)
		for _, state in pairs(PlayerState.Players) do
			PlayerState.save(state)
		end
	end
end)

print("Brainrot Bazaar is open for business!")
