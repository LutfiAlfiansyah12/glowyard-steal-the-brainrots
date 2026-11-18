-- Server Economy & Player State Management for Glowyard: Steal the Brainrots

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Economy = {}

export type PlacedCharacter = {
	uid: string,
	name: string,
	rarity: string,
	baseIncome: number,
	mutation: string,
	mutationMultiplier: number,
	effectiveIncome: number,
	slotIndex: number,
}

export type PlayerData = {
	cash: number,
	rebirths: number,
	characters: { PlacedCharacter },
	plotIndex: number?,
	lockExpiresAt: number,
	lockCooldownUntil: number,
}

local playerStates: { [Player]: PlayerData } = {}
local stateUpdateRemote: RemoteEvent? = nil
local toastRemote: RemoteEvent? = nil
local onBaseVisualsChanged: ((Player, PlayerData) -> ())? = nil
local uidCounter = 0

local function nextUid(): string
	uidCounter += 1
	return "char_" .. tostring(uidCounter)
end

function Economy.init(
	remotes: {
		StateUpdate: RemoteEvent,
		Toast: RemoteEvent,
	},
	visualCallback: (Player, PlayerData) -> ()
)
	stateUpdateRemote = remotes.StateUpdate
	toastRemote = remotes.Toast
	onBaseVisualsChanged = visualCallback
end

function Economy.initPlayer(player: Player, plotIndex: number?): PlayerData
	local data: PlayerData = {
		cash = Config.STARTING_CASH,
		rebirths = 0,
		characters = {},
		plotIndex = plotIndex,
		lockExpiresAt = 0,
		lockCooldownUntil = 0,
	}
	playerStates[player] = data

	-- Leaderstats for Roblox player list visibility
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cashStat = Instance.new("IntValue")
	cashStat.Name = "Cash"
	cashStat.Value = data.cash
	cashStat.Parent = leaderstats

	local rebirthStat = Instance.new("IntValue")
	rebirthStat.Name = "Rebirths"
	rebirthStat.Value = data.rebirths
	rebirthStat.Parent = leaderstats

	Economy.replicate(player)
	return data
end

function Economy.removePlayer(player: Player)
	playerStates[player] = nil
end

function Economy.getPlayerData(player: Player): PlayerData?
	return playerStates[player]
end

function Economy.getAllPlayerStates(): { [Player]: PlayerData }
	return playerStates
end

function Economy.getRebirthMultiplier(player: Player): number
	local data = playerStates[player]
	if not data then
		return 1
	end
	return Config.getRebirthMultiplier(data.rebirths)
end

function Economy.getIncomePerSecond(player: Player): number
	local data = playerStates[player]
	if not data then
		return 0
	end
	local rebirthMult = Config.getRebirthMultiplier(data.rebirths)
	local total = 0
	for _, entry in ipairs(data.characters) do
		local charIncome = math.floor(entry.baseIncome * entry.mutationMultiplier * rebirthMult + 0.5)
		entry.effectiveIncome = charIncome
		total += charIncome
	end
	return total
end

function Economy.sendToast(player: Player, message: string, color: Color3?)
	if toastRemote then
		toastRemote:FireClient(player, message, color or Color3.fromRGB(255, 235, 120))
	end
end

function Economy.broadcastToast(message: string, color: Color3?)
	if toastRemote then
		toastRemote:FireAllClients(message, color or Color3.fromRGB(255, 190, 90))
	end
end

function Economy.replicate(player: Player)
	local data = playerStates[player]
	if not data then
		return
	end

	local incomePerSec = Economy.getIncomePerSecond(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local cashStat = leaderstats:FindFirstChild("Cash") :: IntValue?
		if cashStat then
			cashStat.Value = math.floor(data.cash)
		end
		local rebirthStat = leaderstats:FindFirstChild("Rebirths") :: IntValue?
		if rebirthStat then
			rebirthStat.Value = data.rebirths
		end
	end

	if stateUpdateRemote then
		local now = os.clock()
		local serializedChars = {}
		for _, c in ipairs(data.characters) do
			table.insert(serializedChars, {
				uid = c.uid,
				name = c.name,
				rarity = c.rarity,
				baseIncome = c.baseIncome,
				mutation = c.mutation,
				mutationMultiplier = c.mutationMultiplier,
				effectiveIncome = c.effectiveIncome,
				slotIndex = c.slotIndex,
			})
		end

		stateUpdateRemote:FireClient(player, {
			cash = math.floor(data.cash),
			rebirths = data.rebirths,
			rebirthMultiplier = Config.getRebirthMultiplier(data.rebirths),
			rebirthCost = Config.getRebirthCost(data.rebirths),
			incomePerSecond = incomePerSec,
			characters = serializedChars,
			plotIndex = data.plotIndex,
			lockRemaining = math.max(0, math.ceil(data.lockExpiresAt - now)),
			lockCooldownRemaining = math.max(0, math.ceil(data.lockCooldownUntil - now)),
		})
	end
end

local function findAvailableOrLowestSlot(data: PlayerData): (number, number?)
	local usedSlots: { [number]: number } = {}
	for idx, c in ipairs(data.characters) do
		usedSlots[c.slotIndex] = idx
	end
	for slot = 1, Config.MAX_PEDESTALS_PER_BASE do
		if not usedSlots[slot] then
			return slot, nil
		end
	end
	-- If all 4 pedestals are full, find the lowest-income character slot
	local lowestIdx = 1
	local lowestVal = math.huge
	for idx, c in ipairs(data.characters) do
		if c.effectiveIncome < lowestVal then
			lowestVal = c.effectiveIncome
			lowestIdx = idx
		end
	end
	return data.characters[lowestIdx].slotIndex, lowestIdx
end

function Economy.purchaseCharacter(player: Player, charDef: { [string]: any }, rng: Random?): (boolean, string)
	local data = playerStates[player]
	if not data then
		return false, "Player data not ready."
	end

	local price = charDef.price
	if data.cash < price then
		Economy.sendToast(player, string.format("Need $%d to buy %s!", price, charDef.name), Color3.fromRGB(255, 95, 95))
		return false, "Not enough cash"
	end

	local mutationName, mutationMult = Config.rollMutation(rng)
	local rebirthMult = Config.getRebirthMultiplier(data.rebirths)
	local newEffectiveIncome = math.floor(charDef.income * mutationMult * rebirthMult + 0.5)

	local targetSlot, replaceIdx = findAvailableOrLowestSlot(data)
	if replaceIdx then
		local existing = data.characters[replaceIdx]
		if existing and existing.effectiveIncome > newEffectiveIncome then
			Economy.sendToast(
				player,
				"All 4 pedestals full with higher-income Brainrots!",
				Color3.fromRGB(255, 140, 80)
			)
			return false, "Base full"
		end
		table.remove(data.characters, replaceIdx)
	end

	data.cash -= price

	local placed: PlacedCharacter = {
		uid = nextUid(),
		name = charDef.name,
		rarity = charDef.rarity,
		baseIncome = charDef.income,
		mutation = mutationName,
		mutationMultiplier = mutationMult,
		effectiveIncome = newEffectiveIncome,
		slotIndex = targetSlot,
	}

	table.insert(data.characters, placed)
	table.sort(data.characters, function(a, b)
		return a.slotIndex < b.slotIndex
	end)

	Economy.getIncomePerSecond(player)

	if onBaseVisualsChanged then
		onBaseVisualsChanged(player, data)
	end
	Economy.replicate(player)

	local mutTag = if mutationName ~= "None" then string.format(" [%s x%d!]", mutationName, mutationMult) else ""
	Economy.sendToast(
		player,
		string.format("Bought %s (%s)%s -> +$%d/s!", charDef.name, charDef.rarity, mutTag, placed.effectiveIncome),
		Config.RARITY_COLORS[charDef.rarity]
	)

	-- Broadcast server-wide announcement when a player pulls a rare mutation or Mythic/Secret Brainrot
	if mutationName == "Rainbow" or mutationName == "Neon" or charDef.rarity == "Secret" or charDef.rarity == "Mythic" then
		Economy.broadcastToast(
			string.format(
				"JACKPOT: %s acquired %s [%s]%s earning +$%d/s on Base #%d!",
				player.DisplayName,
				charDef.name,
				charDef.rarity,
				mutTag,
				placed.effectiveIncome,
				data.plotIndex or 1
			),
			Config.RARITY_COLORS[charDef.rarity]
		)
	end

	return true, "Purchased"
end

function Economy.attemptRebirth(player: Player): (boolean, string)
	local data = playerStates[player]
	if not data then
		return false, "Player not initialized"
	end

	local cost = Config.getRebirthCost(data.rebirths)
	if data.cash < cost then
		Economy.sendToast(
			player,
			string.format("Rebirth requires $%d! (You have $%d)", cost, math.floor(data.cash)),
			Color3.fromRGB(255, 95, 95)
		)
		return false, "Insufficient cash"
	end

	data.rebirths += 1
	data.cash = Config.STARTING_CASH
	data.characters = {}

	if onBaseVisualsChanged then
		onBaseVisualsChanged(player, data)
	end
	Economy.replicate(player)

	local newMult = Config.getRebirthMultiplier(data.rebirths)
	Economy.sendToast(
		player,
		string.format("REBIRTH #%d! Permanent %.1fx Income Multiplier!", data.rebirths, newMult),
		Color3.fromRGB(255, 215, 50)
	)
	Economy.broadcastToast(
		string.format("ASCENSION: %s reached REBIRTH #%d (%.1fx Permanent Income Multiplier)!", player.DisplayName, data.rebirths, newMult),
		Color3.fromRGB(255, 215, 50)
	)
	return true, "Rebirth complete"
end

-- Returns a formatted summary of a player's current base economy for diagnostics and HUD inspection
function Economy.getPlayerEconomySummary(player: Player): { [string]: any }
	local data = playerStates[player]
	if not data then
		return {
			cash = 0,
			rebirths = 0,
			multiplier = 1.0,
			nextRebirthCost = Config.REBIRTH_BASE_COST,
			incomePerSecond = 0,
			characterCount = 0,
			highestIncomeCharacter = "None",
		}
	end

	local highestName = "None"
	local highestVal = 0
	for _, c in ipairs(data.characters) do
		if c.effectiveIncome > highestVal then
			highestVal = c.effectiveIncome
			highestName = string.format("%s (%s, +$%d/s)", c.name, c.mutation, c.effectiveIncome)
		end
	end

	return {
		cash = math.floor(data.cash),
		rebirths = data.rebirths,
		multiplier = Config.getRebirthMultiplier(data.rebirths),
		nextRebirthCost = Config.getRebirthCost(data.rebirths),
		incomePerSecond = Economy.getIncomePerSecond(player),
		characterCount = #data.characters,
		highestIncomeCharacter = highestName,
	}
end

function Economy.stealHighestIncomeCharacter(player: Player): PlacedCharacter?
	local data = playerStates[player]
	if not data or #data.characters == 0 then
		return nil
	end

	Economy.getIncomePerSecond(player)
	local bestIdx = 1
	local bestIncome = -1
	for idx, c in ipairs(data.characters) do
		if c.effectiveIncome > bestIncome then
			bestIncome = c.effectiveIncome
			bestIdx = idx
		end
	end

	local stolen = table.remove(data.characters, bestIdx)
	if stolen then
		if onBaseVisualsChanged then
			onBaseVisualsChanged(player, data)
		end
		Economy.replicate(player)
	end
	return stolen
end

function Economy.returnStolenCharacter(player: Player, stolenChar: PlacedCharacter): boolean
	local data = playerStates[player]
	if not data then
		return false
	end

	local slot, replaceIdx = findAvailableOrLowestSlot(data)
	if replaceIdx then
		table.remove(data.characters, replaceIdx)
	end
	stolenChar.slotIndex = slot
	table.insert(data.characters, stolenChar)
	table.sort(data.characters, function(a, b)
		return a.slotIndex < b.slotIndex
	end)

	Economy.getIncomePerSecond(player)
	if onBaseVisualsChanged then
		onBaseVisualsChanged(player, data)
	end
	Economy.replicate(player)
	return true
end

function Economy.startTickLoop()
	task.spawn(function()
		while true do
			task.wait(Config.ECONOMY_TICK_RATE)
			for _, player in ipairs(Players:GetPlayers()) do
				local data = playerStates[player]
				if data then
					local income = Economy.getIncomePerSecond(player)
					if income > 0 then
						data.cash += income
					end
					Economy.replicate(player)
				end
			end
		end
	end)
end

return Economy
