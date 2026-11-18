-- Brainrot Bazaar client: the whole interface over the 3D world.
-- Top bar (Cash / income / rebirths), collection panel, shop panel, wave banner,
-- notification feed, steal progress bar and a short tutorial hint at spawn.
-- Keys are read with UserInputService:IsKeyDown and bound with
-- ContextActionService, never an InputBegan handler that the camera eats.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
local updateHud = remotes:WaitForChild("UpdateHud")
local notifyRemote = remotes:WaitForChild("Notify")
local waveAlert = remotes:WaitForChild("WaveAlert")
local carryProgress = remotes:WaitForChild("CarryProgress")
local shopBuy = remotes:WaitForChild("ShopBuy")
local rebirthBuy = remotes:WaitForChild("RebirthBuy")
local unlockSlot = remotes:WaitForChild("UnlockSlot")
local slapRemote = remotes:WaitForChild("Slap")

local RARITY_COLORS = {}
for rarity, data in pairs(BrainrotData.Rarities) do
	RARITY_COLORS[rarity] = Color3.fromRGB(data.color[1], data.color[2], data.color[3])
end

-- ---------------------------------------------------------------- gui helpers

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function makeLabel(parent, name, text, size, position, textSize, color, font)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = textSize
	label.TextColor3 = color
	label.Font = font or Enum.Font.SourceSansBold
	label.TextStrokeTransparency = 0.2
	label.Parent = parent
	return label
end

local function makeButton(parent, name, text, size, position, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text
	button.TextSize = 15
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.SourceSansBold
	button.TextWrapped = true
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	return button
end

local function makePanel(parent, name, size, position)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.Size = size
	panel.Position = position
	panel.BackgroundColor3 = Color3.fromRGB(20, 24, 40)
	panel.BackgroundTransparency = 0.25
	panel.BorderSizePixel = 0
	panel.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel
	return panel
end

-- ---------------------------------------------------------------- top bar

-- Centred, clear of the top-left Roblox menu buttons.
local topBar = makePanel(gui, "TopBar", UDim2.new(0, 560, 0, 46), UDim2.new(0.5, -280, 0, 8))
local cashLabel = makeLabel(topBar, "Cash", "$0", UDim2.new(0.34, 0, 1, 0), UDim2.new(0, 8, 0, 0), 22, Color3.fromRGB(120, 255, 140))
local incomeLabel = makeLabel(topBar, "Income", "+$0/s", UDim2.new(0.33, 0, 1, 0), UDim2.new(0.34, 0, 0, 0), 20, Color3.fromRGB(255, 230, 90))
local rebirthLabel = makeLabel(topBar, "Rebirths", "Rebirths: 0", UDim2.new(0.33, 0, 1, 0), UDim2.new(0.67, 0, 0, 0), 20, Color3.fromRGB(255, 180, 255))

-- ---------------------------------------------------------------- wave banner

local waveBanner = makePanel(gui, "WaveBanner", UDim2.new(0, 480, 0, 54), UDim2.new(0.5, -240, 0, 62))
waveBanner.BackgroundColor3 = Color3.fromRGB(120, 20, 160)
waveBanner.Visible = false
local waveLabel = makeLabel(waveBanner, "WaveText", "", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 22, Color3.fromRGB(255, 255, 255), Enum.Font.FredokaOne)

local waveCountdown = 0
local waveActive = false

-- ---------------------------------------------------------------- collection panel (right side)

local collectionPanel = makePanel(gui, "CollectionPanel", UDim2.new(0, 250, 0, 380), UDim2.new(1, -262, 0, 62))
makeLabel(collectionPanel, "Title", "MY BASE", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 6), 20, Color3.fromRGB(255, 255, 255), Enum.Font.FredokaOne)
local slotList = Instance.new("Frame")
slotList.Name = "SlotList"
slotList.Size = UDim2.new(1, -16, 1, -44)
slotList.Position = UDim2.new(0, 8, 0, 38)
slotList.BackgroundTransparency = 1
slotList.Parent = collectionPanel

local slotRows = {}
for slot = 1, BrainrotData.MaxSlots do
	local row = Instance.new("Frame")
	row.Name = "Slot" .. tostring(slot)
	row.Size = UDim2.new(1, 0, 0, 28)
	row.Position = UDim2.new(0, 0, 0, (slot - 1) * 30)
	row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	row.BackgroundTransparency = 0.85
	row.BorderSizePixel = 0
	row.Parent = slotList
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = row
	local label = makeLabel(row, "SlotLabel", "", UDim2.new(1, -8, 1, 0), UDim2.new(0, 4, 0, 0), 14, Color3.fromRGB(255, 255, 255))
	label.TextXAlignment = Enum.TextXAlignment.Left
	slotRows[slot] = label
end

-- ---------------------------------------------------------------- shop panel (left side)

local shopPanel = makePanel(gui, "ShopPanel", UDim2.new(0, 250, 0, 330), UDim2.new(0, 12, 0, 62))
makeLabel(shopPanel, "Title", "SHOP", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 6), 20, Color3.fromRGB(255, 255, 255), Enum.Font.FredokaOne)
local shopY = 40
for _, item in ipairs(BrainrotData.ShopItems) do
	local button = makeButton(shopPanel, "Buy_" .. item.id, item.name .. "  " .. BrainrotData.formatCash(item.price), UDim2.new(1, -16, 0, 36), UDim2.new(0, 8, 0, shopY), Color3.fromRGB(40, 140, 90))
	button.MouseButton1Click:Connect(function()
		shopBuy:FireServer(item.id)
	end)
	makeLabel(shopPanel, "Desc_" .. item.id, item.desc, UDim2.new(1, -16, 0, 16), UDim2.new(0, 8, 0, shopY + 38), 12, Color3.fromRGB(200, 200, 200), Enum.Font.SourceSans)
	shopY = shopY + 58
end
local rebirthButton = makeButton(shopPanel, "Rebirth", "REBIRTH", UDim2.new(1, -16, 0, 40), UDim2.new(0, 8, 0, shopY + 4), Color3.fromRGB(160, 40, 200))
local rebirthCostLabel = makeLabel(shopPanel, "RebirthCost", "", UDim2.new(1, -16, 0, 18), UDim2.new(0, 8, 0, shopY + 46), 13, Color3.fromRGB(255, 220, 255))
rebirthButton.MouseButton1Click:Connect(function()
	rebirthBuy:FireServer()
end)

-- ---------------------------------------------------------------- notifications (bottom-left)

local feed = Instance.new("Frame")
feed.Name = "Feed"
feed.Size = UDim2.new(0, 380, 0, 150)
feed.Position = UDim2.new(0, 12, 1, -162)
feed.BackgroundTransparency = 1
feed.Parent = gui

local function addNotification(text, color)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 22)
	label.Position = UDim2.new(0, 0, 1, -22)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = 15
	label.TextColor3 = color
	label.Font = Enum.Font.SourceSansBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextStrokeTransparency = 0.2
	label.Parent = feed
	-- Push older lines up; drop the oldest past five.
	local children = feed:GetChildren()
	table.sort(children, function(a, b)
		return a.Position.Y.Offset < b.Position.Y.Offset
	end)
	for i, child in ipairs(children) do
		if i > 5 then
			child:Destroy()
		else
			child.Position = UDim2.new(0, 0, 1, -22 * (#children - i + 1))
		end
	end
	task.delay(8, function()
		if label.Parent ~= nil then
			label:Destroy()
		end
	end)
end

-- ---------------------------------------------------------------- steal progress bar (centre)

local progressFrame = makePanel(gui, "StealProgress", UDim2.new(0, 300, 0, 30), UDim2.new(0.5, -150, 0.5, 90))
progressFrame.Visible = false
local progressFill = Instance.new("Frame")
progressFill.Name = "Fill"
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(255, 200, 40)
progressFill.BorderSizePixel = 0
progressFill.Parent = progressFrame
makeLabel(progressFrame, "StealLabel", "STEALING...", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 16, Color3.fromRGB(255, 255, 255))

-- ---------------------------------------------------------------- tutorial hint (bottom-centre)

local hint = makeLabel(gui, "TutorialHint", "Touch a brainrot on the belt to claim it! It earns $/s on your base. Watch out for the wave!", UDim2.new(0, 640, 0, 30), UDim2.new(0.5, -320, 1, -40), 17, Color3.fromRGB(255, 255, 255))
hint.BackgroundColor3 = Color3.fromRGB(20, 24, 40)
hint.BackgroundTransparency = 0.3
task.delay(20, function()
	hint:Destroy()
end)

-- ---------------------------------------------------------------- remote handlers

updateHud.OnClientEvent:Connect(function(data)
	cashLabel.Text = BrainrotData.formatCash(data.cash)
	incomeLabel.Text = "+" .. BrainrotData.formatCash(data.income) .. "/s"
	rebirthLabel.Text = "Rebirths: " .. tostring(data.rebirths) .. " (" .. data.title .. ")"
	rebirthCostLabel.Text = "Cost: " .. BrainrotData.formatCash(data.rebirthCost) .. " - income x" .. tostring(2 ^ (data.rebirths + 1))
	for slot = 1, BrainrotData.MaxSlots do
		local row = slotRows[slot]
		if slot > #data.slots and data.nextSlot == nil then
			row.Parent.Visible = false
		elseif slot <= #data.slots then
			row.Parent.Visible = true
			local entry = data.slots[slot]
			if entry == false then
				row.Text = tostring(slot) .. ".  (empty slot)"
				row.TextColor3 = Color3.fromRGB(180, 180, 180)
			else
				local label = tostring(slot) .. ".  " .. entry.name .. "  $" .. tostring(entry.income) .. "/s"
				if entry.mutation ~= "Normal" then
					label = tostring(slot) .. ".  " .. entry.mutation .. " " .. entry.name .. "  $" .. tostring(entry.income) .. "/s"
				end
				row.Text = label
				row.TextColor3 = RARITY_COLORS[entry.rarity] or Color3.fromRGB(255, 255, 255)
			end
		else
			row.Parent.Visible = false
		end
	end
	-- The unlock button lives in the row after the last unlocked slot.
	if data.nextSlot ~= nil then
		local row = slotRows[data.nextSlot.slot]
		if row ~= nil then
			row.Parent.Visible = true
			row.Text = "Unlock slot " .. tostring(data.nextSlot.slot) .. " - " .. BrainrotData.formatCash(data.nextSlot.price)
			row.TextColor3 = Color3.fromRGB(255, 220, 90)
			if row.Parent:FindFirstChild("UnlockButton") == nil then
				local unlock = Instance.new("TextButton")
				unlock.Name = "UnlockButton"
				unlock.Size = UDim2.new(1, 0, 1, 0)
				unlock.BackgroundTransparency = 1
				unlock.Text = ""
				unlock.Parent = row.Parent
				unlock.MouseButton1Click:Connect(function()
					unlockSlot:FireServer(data.nextSlot.slot)
				end)
			end
		end
	end
end)

notifyRemote.OnClientEvent:Connect(function(text, color)
	addNotification(text, color)
end)

waveAlert.OnClientEvent:Connect(function(kind, seconds)
	if kind == "warning" then
		waveActive = false
		waveCountdown = seconds
		waveBanner.Visible = true
		waveBanner.BackgroundColor3 = Color3.fromRGB(160, 60, 20)
	elseif kind == "active" then
		waveActive = true
		waveCountdown = seconds
		waveBanner.Visible = true
		waveBanner.BackgroundColor3 = Color3.fromRGB(120, 20, 160)
	elseif kind == "clear" then
		waveBanner.Visible = false
		waveActive = false
	end
end)

carryProgress.OnClientEvent:Connect(function(progress)
	if progress <= 0 then
		progressFrame.Visible = false
	else
		progressFrame.Visible = true
		progressFill.Size = UDim2.new(progress, 0, 1, 0)
	end
end)

-- Wave countdown ticker, once a second.
task.spawn(function()
	while true do
		task.wait(1)
		if waveBanner.Visible and waveCountdown > 0 then
			waveCountdown = waveCountdown - 1
			if waveActive then
				waveLabel.Text = "BRAINROT WAVE! Get to your base! " .. tostring(waveCountdown) .. "s"
			else
				waveLabel.Text = "BRAINROT WAVE IN " .. tostring(waveCountdown) .. "s - GET TO YOUR BASE!"
			end
		end
	end
end)

-- ---------------------------------------------------------------- slap tool

-- When the Slap Glove is equipped, swinging it (click) fires the Slap remote.
-- The server checks ownership, range and cooldown.
local function watchTool(tool)
	if tool.Name ~= "Slap Glove" then
		return
	end
	tool.Activated:Connect(function()
		slapRemote:FireServer()
	end)
end

local function watchCharacter(character)
	for _, tool in ipairs(character:GetChildren()) do
		if tool:IsA("Tool") then
			watchTool(tool)
		end
	end
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			watchTool(child)
		end
	end)
end

if player.Character ~= nil then
	watchCharacter(player.Character)
end
player.CharacterAdded:Connect(watchCharacter)

-- E key also swings the glove, bound through ContextActionService so the
-- camera scripts never swallow it.
ContextActionService:BindAction("BrainrotSlap", function(_, state, _)
	if state == Enum.UserInputState.Begin then
		slapRemote:FireServer()
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.E)

print("Brainrot Bazaar client ready!")
