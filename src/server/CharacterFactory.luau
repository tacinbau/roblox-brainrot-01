-- CharacterFactory: builds every brainrot character as a little Model made of Parts.
-- No catalog assets, no decals, no meshes, no sounds: just Parts, colours and a
-- BillboardGui name tag with the name, rarity and $/sec label.

local CharacterFactory = {}

local function rgb(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function makePart(name, size, color, position, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Material = Enum.Material.SmoothPlastic
	if shape ~= nil then
		part.Shape = shape
	end
	return part
end

-- One themed accessory per character, built from Parts on the head.
local function buildAccessory(accessory, accent, headTop)
	local parts = {}
	if accessory == "sock" then
		-- A floppy sock draped over the head.
		local sock = makePart("Sock", Vector3.new(1.6, 1.2, 0.4), rgb(accent), headTop + Vector3.new(0, 0.5, 0))
		table.insert(parts, sock)
		local toe = makePart("SockToe", Vector3.new(0.8, 0.8, 0.4), rgb({220, 60, 60}), headTop + Vector3.new(0.9, 0.2, 0))
		table.insert(parts, toe)
	elseif accessory == "glasses" then
		-- Round professor glasses: two rings and a bridge.
		for _, dx in ipairs({ -0.55, 0.55 }) do
			local lens = makePart("Lens", Vector3.new(0.9, 0.9, 0.2), rgb(accent), headTop + Vector3.new(dx, -0.2, 1.0))
			table.insert(parts, lens)
		end
		local bridge = makePart("Bridge", Vector3.new(0.5, 0.2, 0.2), rgb(accent), headTop + Vector3.new(0, -0.2, 1.0))
		table.insert(parts, bridge)
		-- A tiny graduation cap on top.
		local cap = makePart("Cap", Vector3.new(2.2, 0.3, 2.2), rgb(accent), headTop + Vector3.new(0, 1.2, 0))
		table.insert(parts, cap)
	elseif accessory == "mask" then
		-- A bandit eye mask across the face.
		local mask = makePart("Mask", Vector3.new(1.9, 0.7, 0.3), rgb(accent), headTop + Vector3.new(0, -0.2, 1.0))
		table.insert(parts, mask)
	elseif accessory == "headband" then
		-- A ninja headband with two fluttering tails.
		local band = makePart("Band", Vector3.new(2.1, 0.5, 2.1), rgb(accent), headTop + Vector3.new(0, 0.6, 0))
		table.insert(parts, band)
		local tail = makePart("Tail", Vector3.new(0.4, 1.4, 0.2), rgb(accent), headTop + Vector3.new(0.9, 0.2, -1.0))
		table.insert(parts, tail)
	elseif accessory == "hat" then
		-- A cowboy hat: brim and crown.
		local brim = makePart("Brim", Vector3.new(3.2, 0.3, 3.2), rgb(accent), headTop + Vector3.new(0, 0.9, 0))
		table.insert(parts, brim)
		local crown = makePart("Crown", Vector3.new(1.6, 1.0, 1.6), rgb(accent), headTop + Vector3.new(0, 1.5, 0))
		table.insert(parts, crown)
	elseif accessory == "discoball" then
		-- A mirror ball floating over the head, spinning in the walk bob.
		local ball = makePart("DiscoBall", Vector3.new(1.6, 1.6, 1.6), rgb(accent), headTop + Vector3.new(0, 1.8, 0), Enum.PartType.Ball)
		ball.Material = Enum.Material.Metal
		table.insert(parts, ball)
	elseif accessory == "eyepatch" then
		-- A pirate eye patch and a pepperoni dot.
		local patch = makePart("Patch", Vector3.new(0.8, 0.8, 0.2), rgb(accent), headTop + Vector3.new(-0.5, -0.1, 1.0))
		table.insert(parts, patch)
		local pepperoni = makePart("Pepperoni", Vector3.new(0.7, 0.7, 0.2), rgb({200, 40, 40}), headTop + Vector3.new(0.6, -0.6, 1.0), Enum.PartType.Ball)
		table.insert(parts, pepperoni)
	elseif accessory == "swirl" then
		-- A tornado swirl: three stacked spinning rings above the toilet body.
		for i, size in ipairs({ 2.4, 1.8, 1.2 }) do
			local ring = makePart("Swirl" .. i, Vector3.new(size, 0.6, size), rgb(accent), headTop + Vector3.new(0, 0.9 + i * 0.7, 0))
			table.insert(parts, ring)
		end
	elseif accessory == "foam" then
		-- Cappuccino foam: a white dome on the cup.
		local foam = makePart("Foam", Vector3.new(1.8, 1.0, 1.8), rgb(accent), headTop + Vector3.new(0, 1.0, 0), Enum.PartType.Ball)
		table.insert(parts, foam)
	elseif accessory == "antenna" then
		-- Grandma's WiFi router antenna with a blinking-look tip.
		local rod = makePart("Antenna", Vector3.new(0.3, 2.0, 0.3), rgb(accent), headTop + Vector3.new(0.7, 1.6, 0))
		table.insert(parts, rod)
		local tip = makePart("AntennaTip", Vector3.new(0.6, 0.6, 0.6), rgb({255, 220, 60}), headTop + Vector3.new(0.7, 2.7, 0), Enum.PartType.Ball)
		table.insert(parts, tip)
		-- A grey hair bun.
		local bun = makePart("Bun", Vector3.new(1.2, 1.2, 1.2), rgb({200, 200, 210}), headTop + Vector3.new(-0.6, 1.1, -0.4), Enum.PartType.Ball)
		table.insert(parts, bun)
	elseif accessory == "crown" then
		-- A golden crown with three points.
		local base = makePart("CrownBase", Vector3.new(2.2, 0.5, 2.2), rgb(accent), headTop + Vector3.new(0, 1.0, 0))
		table.insert(parts, base)
		for _, dx in ipairs({ -0.8, 0, 0.8 }) do
			local point = makePart("CrownPoint", Vector3.new(0.5, 0.9, 0.5), rgb(accent), headTop + Vector3.new(dx, 1.6, 0))
			table.insert(parts, point)
		end
	end
	return parts
end

-- Build a brainrot character Model at `position` (the feet position).
-- mutation tints the body: Golden is gold, Diamond is ice blue, Rainbow is pink.
function CharacterFactory.buildBrainrot(characterDef, mutation, position)
	local model = Instance.new("Model")
	model.Name = characterDef.name

	local bodyColor = rgb(characterDef.bodyColor)
	local headColor = rgb(characterDef.headColor)
	if mutation == "Golden" then
		bodyColor = Color3.fromRGB(255, 210, 60)
		headColor = Color3.fromRGB(255, 225, 100)
	elseif mutation == "Diamond" then
		bodyColor = Color3.fromRGB(150, 220, 255)
		headColor = Color3.fromRGB(190, 235, 255)
	elseif mutation == "Rainbow" then
		bodyColor = Color3.fromRGB(255, 120, 200)
		headColor = Color3.fromRGB(255, 170, 220)
	end

	-- Body: a chunky rounded block. Head: a ball on top. Feet: two little blocks.
	local body = makePart("Body", Vector3.new(3, 2.6, 2), bodyColor, position + Vector3.new(0, 1.8, 0))
	body.CanCollide = true
	body.CanQuery = true
	body.Parent = model
	model.PrimaryPart = body

	local head = makePart("Head", Vector3.new(2.2, 2.2, 2.2), headColor, position + Vector3.new(0, 4.1, 0), Enum.PartType.Ball)
	head.Parent = model

	-- Eyes: two white balls with dark pupils on the face (+Z side).
	for _, dx in ipairs({ -0.55, 0.55 }) do
		local eye = makePart("Eye", Vector3.new(0.5, 0.6, 0.3), Color3.fromRGB(255, 255, 255), position + Vector3.new(dx, 4.3, 1.1), Enum.PartType.Ball)
		eye.Parent = model
		local pupil = makePart("Pupil", Vector3.new(0.25, 0.3, 0.15), Color3.fromRGB(20, 20, 20), position + Vector3.new(dx, 4.3, 1.25), Enum.PartType.Ball)
		pupil.Parent = model
	end

	for _, dx in ipairs({ -0.8, 0.8 }) do
		local foot = makePart("Foot", Vector3.new(1.1, 0.6, 1.6), rgb(characterDef.accent), position + Vector3.new(dx, 0.3, 0))
		foot.Parent = model
	end

	local headTop = position + Vector3.new(0, 5.2, 0)
	for _, part in ipairs(buildAccessory(characterDef.accessory, characterDef.accent, headTop)) do
		part.Parent = model
	end

	-- Name tag: name, rarity and $/sec, readable from across the plaza.
	local tag = Instance.new("BillboardGui")
	tag.Name = "NameTag"
	tag.Size = UDim2.fromOffset(140, 54)
	tag.StudsOffset = Vector3.new(0, 6.4, 0)
	tag.AlwaysOnTop = true
	tag.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = characterDef.name
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Parent = tag

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "RateLabel"
	rateLabel.Position = UDim2.new(0, 0, 0.55, 0)
	rateLabel.Size = UDim2.new(1, 0, 0.45, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = ""
	rateLabel.TextScaled = true
	rateLabel.Font = Enum.Font.SourceSansBold
	rateLabel.TextColor3 = Color3.fromRGB(255, 230, 90)
	rateLabel.TextStrokeTransparency = 0
	rateLabel.Parent = tag

	return model
end

-- Refresh the name tag after the mutation and income are known.
function CharacterFactory.setBrainrotLabel(model, characterDef, mutation, incomePerSecond)
	local tag = model:FindFirstChild("NameTag")
	if tag == nil then
		return
	end
	local nameLabel = tag:FindFirstChild("NameLabel")
	local rateLabel = tag:FindFirstChild("RateLabel")
	if nameLabel ~= nil then
		local label = characterDef.name
		if mutation ~= "Normal" then
			label = mutation .. " " .. label
		end
		nameLabel.Text = label
	end
	if rateLabel ~= nil then
		rateLabel.Text = characterDef.rarity .. "  $" .. tostring(incomePerSecond) .. "/s"
	end
end

return CharacterFactory
