-- Wave: the Brainrot Wave. Every 180 seconds a 20-second warning banner counts
-- down, then a giant wall sweeps across the plaza for about 15 seconds.
-- Caught outside your base: knocked down for 3 seconds and you drop anything
-- you are carrying. Your base is the safe zone.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))

local Wave = {}
Wave.Wall = nil
Wave.WallX = 0

local context = nil

-- Knock a player down: drop what they carry, flatten them for `seconds`.
function Wave.knockPlayerDown(state, seconds)
	if state.knockedUntil > os.clock() then
		return
	end
	state.knockedUntil = os.clock() + seconds
	PlayerState.dropCarried(state)
	local character = state.player.Character
	if character == nil then
		return
	end
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid == nil then
		return
	end
	humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
	task.delay(seconds, function()
		if humanoid.Parent ~= nil and humanoid.Health > 0 then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end

-- Is this player caught by the wall right now? Safe inside their own base.
function Wave.isPlayerCaught(state)
	if PlayerState.isInOwnBase(state) then
		return false
	end
	local character = state.player.Character
	if character == nil then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return false
	end
	return math.abs(root.Position.X - Wave.WallX) < 6 and math.abs(root.Position.Z) < 70
end

-- Build the wall: a huge glowing slab that crosses the whole plaza.
function Wave.buildWall()
	local wall = Instance.new("Part")
	wall.Name = "BrainrotWaveWall"
	wall.Size = Vector3.new(2, 40, 140)
	wall.Color = Color3.fromRGB(190, 60, 255)
	wall.Material = Enum.Material.Neon
	wall.Anchored = true
	wall.CanCollide = false
	wall.CanQuery = false
	wall.Transparency = 0.35
	wall.Position = Vector3.new(-85, 20, 0)
	wall.Parent = workspace
	Wave.Wall = wall
	Wave.WallX = -85
	return wall
end

-- One wave: warn, sweep, clean up.
function Wave.runWave()
	context.remotes.WaveAlert:FireAllClients("warning", BrainrotData.WaveWarning)
	context.notifyAll("BRAINROT WAVE INCOMING! Get to your base in " .. tostring(BrainrotData.WaveWarning) .. " seconds!")
	task.wait(BrainrotData.WaveWarning)

	local wall = Wave.buildWall()
	context.remotes.WaveAlert:FireAllClients("active", BrainrotData.WaveDuration)
	context.notifyAll("THE BRAINROT WAVE IS HERE! Run to your base!")

	local startTime = os.clock()
	local duration = BrainrotData.WaveDuration
	while os.clock() - startTime < duration do
		local t = (os.clock() - startTime) / duration
		Wave.WallX = -85 + t * 170
		if wall.Parent ~= nil then
			wall.Position = Vector3.new(Wave.WallX, 20, 0)
		end
		-- Catch anyone outside their base who touches the wall's line.
		for _, state in pairs(PlayerState.Players) do
			if Wave.isPlayerCaught(state) then
				Wave.knockPlayerDown(state, BrainrotData.WaveKnockdown)
				context.notify(state.player, "The wave caught you! Knocked down for 3 seconds.", Color3.fromRGB(255, 120, 120))
				context.updateHud(state.player)
			end
		end
		task.wait(0.25)
	end

	if wall.Parent ~= nil then
		wall:Destroy()
	end
	Wave.Wall = nil
	context.remotes.WaveAlert:FireAllClients("clear", 0)
	context.notifyAll("The wave has passed. Back to the bazaar!")
end

-- The wave clock: first wave 180 seconds after the server starts, then forever.
function Wave.startWaveLoop()
	task.spawn(function()
		task.wait(BrainrotData.WaveInterval)
		while true do
			local ok, err = pcall(Wave.runWave)
			if not ok then
				warn("Brainrot Bazaar: wave failed: " .. tostring(err))
			end
			task.wait(BrainrotData.WaveInterval)
		end
	end)
end

function Wave.init(gameContext)
	context = gameContext
	Wave.startWaveLoop()
end

return Wave
