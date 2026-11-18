-- Conveyor: the heart of the game. A new brainrot spawns on the central belt
-- every 7 seconds, walks ~45 seconds across the plaza, then despawns.
-- Touch (or click) one to claim it to your base; touch one in another player's
-- base to channel a steal and carry it home.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local CharacterFactory = require(script.Parent:WaitForChild("CharacterFactory"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))

local Conveyor = {}
Conveyor.Brainrots = {} -- live records, belt and base alike
Conveyor.NextId = 1

local context = nil -- set by init: { notify, notifyAll, updateHud, remotes }

-- Is any player running a Lucky Charm right now? A charm doubles mutation luck
-- for every brainrot that spawns while it is active.
local function anyLuckyCharm()
	for _, state in pairs(PlayerState.Players) do
		if PlayerState.hasLuckyCharm(state) then
			return true
		end
	end
	return false
end

-- Spawn one brainrot at the start of the belt and set it walking.
function Conveyor.spawnBrainrot()
	local rarity = BrainrotData.rollRarity()
	local def = BrainrotData.randomCharacterOfRarity(rarity)
	local mutation = BrainrotData.rollMutation(anyLuckyCharm())
	local income = BrainrotData.incomeOf(def, mutation)

	local id = Conveyor.NextId
	Conveyor.NextId = Conveyor.NextId + 1

	local startPos = Vector3.new(0, 1, BrainrotData.BeltStartZ)
	local model = CharacterFactory.buildBrainrot(def, mutation, startPos)
	CharacterFactory.setBrainrotLabel(model, def, mutation, income)
	model.Parent = workspace

	local record = {
		id = id,
		def = def,
		mutation = mutation,
		income = income,
		model = model,
		state = "belt",
		owner = nil,
		slot = nil,
		z = BrainrotData.BeltStartZ,
		bobPhase = math.random() * math.pi * 2,
		stealChannel = nil,
		touchLock = false,
	}
	Conveyor.Brainrots[id] = record

	-- Claim by touch, and by click for players who prefer it.
	local body = model.PrimaryPart
	body.Touched:Connect(function(hit)
		Conveyor.onBrainrotTouched(record, hit)
	end)
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 32
	click.MouseClick:Connect(function(player)
		Conveyor.claimBrainrot(player, record)
	end)
	click.Parent = body

	if mutation ~= "Normal" or def.rarity == "Mythic" or def.rarity == "Secret" or def.rarity == "Legendary" then
		local label = mutation
		if mutation == "Normal" then
			label = def.rarity
		end
		context.notifyAll(label .. " " .. def.name .. " is on the belt! $" .. tostring(income) .. "/s")
	end
	return record
end

-- Remove a brainrot from the world entirely.
function Conveyor.despawnBrainrot(record)
	Conveyor.Brainrots[record.id] = nil
	if record.owner ~= nil and record.slot ~= nil and record.owner.slots[record.slot] == record then
		record.owner.slots[record.slot] = nil
	end
	if record.model ~= nil then
		record.model:Destroy()
		record.model = nil
	end
end

-- Send a claimed brainrot to its owner's base slot.
function Conveyor.placeOnBase(record, ownerState, slot)
	record.state = "base"
	record.owner = ownerState
	record.slot = slot
	ownerState.slots[slot] = record
	local pos = PlayerState.slotPosition(ownerState, slot)
	if record.model ~= nil then
		record.model:SetPrimaryPartCFrame(CFrame.new(pos))
	end
end

-- Claim a brainrot off the belt into the player's first free base slot.
function Conveyor.claimBrainrot(player, record)
	if record.state ~= "belt" or record.model == nil then
		return
	end
	local state = PlayerState.Players[player]
	if state == nil or record.touchLock then
		return
	end
	if PlayerState.isKnockedDown(state) then
		return
	end
	local slot = PlayerState.firstFreeSlot(state)
	if slot == nil then
		context.notify(player, "Your base is full! Unlock more slots in your collection panel.", Color3.fromRGB(255, 120, 120))
		return
	end
	record.touchLock = true
	Conveyor.placeOnBase(record, state, slot)
	context.notify(player, "Claimed " .. record.def.name .. " ($" .. tostring(record.income) .. "/s) for your base!", Color3.fromRGB(120, 255, 140))
	context.updateHud(player)
	task.wait(0.5)
	record.touchLock = false
end

function Conveyor.onBrainrotTouched(record, hit)
	local character = hit.Parent
	if character == nil then
		return
	end
	local player = game:GetService("Players"):GetPlayerFromCharacter(character)
	if player == nil then
		return
	end
	if record.state == "belt" then
		Conveyor.claimBrainrot(player, record)
	elseif record.state == "base" then
		Conveyor.tryStartSteal(player, record)
	end
end

-- Start the 3-second steal channel on a brainrot in another player's base.
function Conveyor.tryStartSteal(player, record)
	local thiefState = PlayerState.Players[player]
	if thiefState == nil then
		return
	end
	if record.owner == thiefState then
		return
	end
	if record.owner == nil then
		return
	end
	if PlayerState.isBaseLocked(record.owner) then
		context.notify(player, "That base is locked! Come back later.", Color3.fromRGB(255, 120, 120))
		return
	end
	if thiefState.carrying ~= nil then
		context.notify(player, "You are already carrying a brainrot!", Color3.fromRGB(255, 120, 120))
		return
	end
	if PlayerState.isKnockedDown(thiefState) then
		return
	end
	if record.stealChannel ~= nil then
		return
	end
	record.stealChannel = { player = player, startedAt = os.clock() }
	context.notify(player, "Stealing " .. record.def.name .. "... hold still for 3 seconds!", Color3.fromRGB(255, 220, 90))
end

-- Finish a steal: lift the brainrot off the victim's base and onto the thief.
function Conveyor.completeSteal(record)
	local channel = record.stealChannel
	if channel == nil then
		return
	end
	local thief = channel.player
	local thiefState = PlayerState.Players[thief]
	record.stealChannel = nil
	if thiefState == nil then
		return
	end
	local owner = record.owner
	if owner ~= nil and record.slot ~= nil then
		owner.slots[record.slot] = nil
	end
	record.state = "carried"
	record.owner = nil
	record.slot = nil
	thiefState.carrying = record
	context.remotes.CarryProgress:FireClient(thief, 0)
	context.notify(thief, "You stole " .. record.def.name .. "! Run it home to your base!", Color3.fromRGB(255, 220, 90))
	if owner ~= nil then
		context.notify(owner.player, thief.Name .. " stole your " .. record.def.name .. "! Slap them to make them drop it!", Color3.fromRGB(255, 120, 120))
	end
	context.updateHud(thief)
	if owner ~= nil then
		context.updateHud(owner.player)
	end
end

-- A carried brainrot that reaches the thief's own base is theirs.
function Conveyor.tryDepositCarried(state)
	local record = state.carrying
	if record == nil then
		return
	end
	if not PlayerState.isInOwnBase(state) then
		return
	end
	local slot = PlayerState.firstFreeSlot(state)
	if slot == nil then
		-- No room at home: the brainrot slips away.
		context.notify(state.player, "Your base is full! The stolen " .. record.def.name .. " got away!", Color3.fromRGB(255, 120, 120))
		state.carrying = nil
		Conveyor.despawnBrainrot(record)
		return
	end
	state.carrying = nil
	Conveyor.placeOnBase(record, state, slot)
	context.notify(state.player, "Stolen " .. record.def.name .. " secured on your base! $" .. tostring(record.income) .. "/s", Color3.fromRGB(120, 255, 140))
	context.updateHud(state.player)
end

-- One frame of the belt: walk every belt brainrot, bob it, follow every carried
-- brainrot above its carrier's head, tick steal channels, despawn stragglers.
function Conveyor.onHeartbeat(dt)
	local now = os.clock()
	for id, record in pairs(Conveyor.Brainrots) do
		if record.model == nil then
			Conveyor.Brainrots[id] = nil
		elseif record.state == "belt" then
			record.z = record.z + BrainrotData.WalkSpeed * dt
			record.bobPhase = record.bobPhase + dt * 5
			local bob = math.sin(record.bobPhase) * 0.25
			local waddle = math.sin(record.bobPhase) * 0.08
			record.model:SetPrimaryPartCFrame(
				CFrame.new(0, 1 + bob, record.z) * CFrame.Angles(0, waddle, 0)
			)
			if record.z >= BrainrotData.BeltEndZ then
				Conveyor.despawnBrainrot(record)
			end
		elseif record.state == "carried" then
			-- Find the carrier and hover the brainrot over their head.
			local carrier = nil
			for _, state in pairs(PlayerState.Players) do
				if state.carrying == record then
					carrier = state
					break
				end
			end
			if carrier == nil then
				Conveyor.despawnBrainrot(record)
			else
				local character = carrier.player.Character
				local root = character ~= nil and character:FindFirstChild("HumanoidRootPart") or nil
				local humanoid = character ~= nil and character:FindFirstChild("Humanoid") or nil
				if root == nil or humanoid == nil or humanoid.Health <= 0 then
					PlayerState.dropCarried(carrier)
					context.updateHud(carrier.player)
				else
					record.model:SetPrimaryPartCFrame(CFrame.new(root.Position + Vector3.new(0, 7, 0)))
					Conveyor.tryDepositCarried(carrier)
				end
			end
		end
	end

	-- Steal channels: progress while the thief stays close, cancel if they leave.
	for _, record in pairs(Conveyor.Brainrots) do
		local channel = record.stealChannel
		if channel ~= nil then
			local thief = channel.player
			local thiefState = PlayerState.Players[thief]
			local character = thief ~= nil and thief.Character or nil
			local root = character ~= nil and character:FindFirstChild("HumanoidRootPart") or nil
			local ok = false
			if thiefState ~= nil and root ~= nil and record.model ~= nil and not PlayerState.isKnockedDown(thiefState) then
				local dist = (root.Position - record.model:GetPrimaryPartCFrame().Position).Magnitude
				ok = dist < 10
			end
			if not ok then
				record.stealChannel = nil
				if thief ~= nil then
					context.remotes.CarryProgress:FireClient(thief, 0)
					context.notify(thief, "Steal interrupted!", Color3.fromRGB(255, 120, 120))
				end
			else
				local progress = (now - channel.startedAt) / BrainrotData.StealChannel
				if progress >= 1 then
					Conveyor.completeSteal(record)
				else
					context.remotes.CarryProgress:FireClient(thief, progress)
				end
			end
		end
	end
end

-- Spawn loop: a fresh brainrot every SpawnInterval seconds, forever.
function Conveyor.startSpawnLoop()
	task.spawn(function()
		while true do
			task.wait(BrainrotData.SpawnInterval)
			local ok, err = pcall(Conveyor.spawnBrainrot)
			if not ok then
				warn("Brainrot Bazaar: spawn failed: " .. tostring(err))
			end
		end
	end)
	RunService.Heartbeat:Connect(Conveyor.onHeartbeat)
end

function Conveyor.init(gameContext)
	context = gameContext
	Conveyor.startSpawnLoop()
end

return Conveyor
