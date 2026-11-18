-- BrainrotData: every number the game runs on, in one place.
-- The cast, the rarity ladder, mutations, slot prices, shop prices and rebirth costs.
-- Both the server (spawning, economy, shop) and the client (panels, labels) read this module.

local BrainrotData = {}

-- The cast: absurd meme-born characters, each with a base income per second.
-- bodyColor / headColor are RGB 0-255 triples; accent is the theme colour of the
-- character's accessory parts; accessory names what CharacterFactory builds for it.
BrainrotData.Characters = {
	{ id = "sock_goblin", name = "Sock Goblin", rarity = "Common", income = 1, bodyColor = {110, 200, 90}, headColor = {140, 220, 110}, accent = {240, 240, 240}, accessory = "sock" },
	{ id = "pigeon_professor", name = "Pigeon Professor", rarity = "Common", income = 3, bodyColor = {140, 140, 160}, headColor = {170, 170, 190}, accent = {40, 40, 60}, accessory = "glasses" },
	{ id = "banana_bandit", name = "Banana Bandit", rarity = "Uncommon", income = 8, bodyColor = {250, 220, 60}, headColor = {255, 235, 90}, accent = {30, 30, 30}, accessory = "mask" },
	{ id = "noodle_ninja", name = "Noodle Ninja", rarity = "Uncommon", income = 15, bodyColor = {240, 200, 120}, headColor = {250, 215, 140}, accent = {200, 60, 60}, accessory = "headband" },
	{ id = "cactus_cowboy", name = "Cactus Cowboy", rarity = "Rare", income = 30, bodyColor = {60, 180, 90}, headColor = {80, 200, 110}, accent = {150, 100, 50}, accessory = "hat" },
	{ id = "disco_duck", name = "Disco Duck", rarity = "Rare", income = 55, bodyColor = {255, 220, 60}, headColor = {255, 235, 120}, accent = {200, 200, 220}, accessory = "discoball" },
	{ id = "pizza_pirate", name = "Pizza Pirate", rarity = "Epic", income = 100, bodyColor = {250, 190, 90}, headColor = {255, 210, 120}, accent = {200, 40, 40}, accessory = "eyepatch" },
	{ id = "toilet_tornado", name = "Toilet Tornado", rarity = "Epic", income = 180, bodyColor = {240, 240, 245}, headColor = {220, 220, 230}, accent = {90, 160, 255}, accessory = "swirl" },
	{ id = "sir_cappuccino", name = "Sir Cappuccino", rarity = "Legendary", income = 350, bodyColor = {140, 95, 60}, headColor = {170, 120, 80}, accent = {245, 235, 210}, accessory = "foam" },
	{ id = "grandmas_wifi", name = "Grandma's WiFi", rarity = "Mythic", income = 750, bodyColor = {190, 190, 200}, headColor = {210, 210, 220}, accent = {90, 200, 90}, accessory = "antenna" },
	{ id = "golden_toilet_king", name = "Golden Toilet King", rarity = "Secret", income = 2000, bodyColor = {255, 210, 60}, headColor = {255, 225, 100}, accent = {255, 255, 255}, accessory = "crown" },
}

-- Rarity ladder: spawn weight out of 100, and the colour its name tag wears.
BrainrotData.Rarities = {
	Common = { weight = 40, color = {200, 200, 200} },
	Uncommon = { weight = 28, color = {90, 220, 90} },
	Rare = { weight = 16, color = {80, 160, 255} },
	Epic = { weight = 9, color = {190, 90, 255} },
	Legendary = { weight = 5, color = {255, 180, 40} },
	Mythic = { weight = 1.5, color = {255, 70, 120} },
	Secret = { weight = 0.5, color = {255, 230, 60} },
}

-- Mutations rolled on spawn: chance out of 100 and the income multiplier.
BrainrotData.Mutations = {
	{ name = "Normal", chance = 80, multiplier = 1 },
	{ name = "Golden", chance = 12, multiplier = 2 },
	{ name = "Diamond", chance = 6, multiplier = 5 },
	{ name = "Rainbow", chance = 2, multiplier = 10 },
}

-- A character's final income: base rate times its mutation multiplier.
function BrainrotData.incomeOf(character, mutation)
	local mult = 1
	for _, m in ipairs(BrainrotData.Mutations) do
		if m.name == mutation then
			mult = m.multiplier
			break
		end
	end
	return character.income * mult
end

-- Roll a rarity by weight. Returns the rarity name.
function BrainrotData.rollRarity()
	local roll = math.random() * 100
	local running = 0
	for rarity, data in pairs(BrainrotData.Rarities) do
		running = running + data.weight
		if roll <= running then
			return rarity
		end
	end
	return "Common"
end

-- Roll a mutation. lucky doubles the chance of every non-Normal mutation.
function BrainrotData.rollMutation(lucky)
	local roll = math.random() * 100
	local running = 0
	for _, m in ipairs(BrainrotData.Mutations) do
		local chance = m.chance
		if lucky and m.name ~= "Normal" then
			chance = chance * 2
		end
		running = running + chance
		if roll <= running then
			return m.name
		end
	end
	return "Normal"
end

-- Pick a random character of a given rarity.
function BrainrotData.randomCharacterOfRarity(rarity)
	local pool = {}
	for _, c in ipairs(BrainrotData.Characters) do
		if c.rarity == rarity then
			table.insert(pool, c)
		end
	end
	return pool[math.random(1, #pool)]
end

-- Conveyor tuning: a new brainrot every 7 seconds, ~45 seconds to cross the belt.
BrainrotData.SpawnInterval = 7
BrainrotData.BeltStartZ = -55
BrainrotData.BeltEndZ = 55
BrainrotData.BeltLength = BrainrotData.BeltEndZ - BrainrotData.BeltStartZ
BrainrotData.CrossTime = 45
BrainrotData.WalkSpeed = BrainrotData.BeltLength / BrainrotData.CrossTime

-- Bases: 6 free slots, slots 7-10 bought with Cash.
BrainrotData.FreeSlots = 6
BrainrotData.MaxSlots = 10
BrainrotData.SlotPrices = { [7] = 500, [8] = 2500, [9] = 10000, [10] = 50000 }

-- The shop: bought with Cash from the GUI shop panel.
BrainrotData.ShopItems = {
	{ id = "slap", name = "Slap Glove", price = 100, desc = "Slap thieves to make them drop your brainrots!" },
	{ id = "coil", name = "Speed Coil", price = 500, desc = "+8 walk speed, forever" },
	{ id = "lock", name = "Base Lock", price = 1000, desc = "Nobody can steal from your base for 60 seconds" },
	{ id = "charm", name = "Lucky Charm", price = 2500, desc = "Mutation luck doubled for 5 minutes" },
}

-- Rebirth: costs $25,000 x (rebirths + 1); resets Cash and the collection,
-- doubles ALL income per rebirth and grants a title over your character.
function BrainrotData.rebirthCost(rebirths)
	return 25000 * (rebirths + 1)
end

BrainrotData.Titles = {
	[0] = "Newbie",
	[1] = "Rookie Collector",
	[2] = "Brainrot Boss",
	[3] = "Meme Lord",
	[4] = "Bazaar Legend",
	[5] = "Mythic Master",
	[6] = "Brainrot God",
}

function BrainrotData.titleFor(rebirths)
	if rebirths >= 6 then
		return BrainrotData.Titles[6]
	end
	return BrainrotData.Titles[rebirths] or BrainrotData.Titles[0]
end

-- The Brainrot Wave: every 180 seconds, 20 seconds of warning, then a wall
-- sweeps the plaza for about 15 seconds. Your base is the safe zone.
BrainrotData.WaveInterval = 180
BrainrotData.WaveWarning = 20
BrainrotData.WaveDuration = 15
BrainrotData.WaveKnockdown = 3

-- Steal: hold a touch on another player's brainrot for 3 seconds to pick it up.
BrainrotData.StealChannel = 3
BrainrotData.BaseLockDuration = 60
BrainrotData.LuckyCharmDuration = 300

-- Money formatting for labels: 1234 -> $1,234, 2500000 -> $2.50M.
function BrainrotData.formatCash(amount)
	amount = math.floor(amount)
	if amount >= 1000000 then
		return "$" .. string.format("%.2fM", amount / 1000000)
	elseif amount >= 10000 then
		return "$" .. string.format("%.1fK", amount / 1000)
	end
	local s = tostring(amount)
	local out = ""
	while #s > 3 do
		out = "," .. string.sub(s, -3) .. out
		s = string.sub(s, 1, -4)
	end
	return "$" .. s .. out
end

return BrainrotData
