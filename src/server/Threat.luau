-- Server Threat & Thief NPC ("Maling Siluman") + Base Lock System
-- Spawns every 75-120 seconds, walks to a random player's base, grabs highest-income character
-- and runs to the map edge; if its owner touches the thief within 10 seconds the character drops back.
-- Players may buy a Base Lock for $500 that blocks theft for 60 seconds (cooldown 120s).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Threat = {}

-- Taunt lines displayed on Maling Siluman's overhead billboard tag during different raid phases
local THIEF_PROWL_TAUNTS = {
	"Sniffing out unguarded Brainrots...",
	"Checking which base forgot its $500 Lock...",
	"Creeping out from the Shadow Edge...",
	"Targeting the highest-income pedestal...",
}

local THIEF_STEAL_TAUNTS = {
	"MINE NOW! Catch me in 10s if you can!",
	"Hehehe! Sprinting back to the Shadow Edge!",
	"Thanks for the top-tier Brainrot!",
}

local THIEF_BLOCKED_TAUNTS = {
	"Curses! A 60-second Base Lock forcefield!",
	"Locked out?! I'll be back in 75-120 seconds!",
	"A $500 emerald shield?! Foiled before I could even grab a pedestal!",
}

local THIEF_FOILED_TAUNTS = {
	"OUCH! You touched me inside the 10-second window! Dropping the Brainrot!",
	"Hey! Hands off! Take your Brainrot back, I'm retreating to the Shadow Edge!",
	"Intercepted! Your pedestal keeps its top earner this time!",
}

local EconomyModule: any = nil
local getPlotPositionCallback: ((number) -> Vector3)? = nil
local updateLockVisualCallback: ((number, boolean, number) -> ())? = nil
local spawnEdgePosition = Vector3.new(0, 3, -155)
local rng = Random.new()

function Threat.init(
	economy: any,
	getPlotPos: (number) -> Vector3,
	updateLockVis: (number, boolean, number) -> (),
	edgePos: Vector3?
)
	EconomyModule = economy
	getPlotPositionCallback = getPlotPos
	updateLockVisualCallback = updateLockVis
	if edgePos then
		spawnEdgePosition = edgePos
	end
end

function Threat.isBaseLocked(player: Player): (boolean, number)
	if not EconomyModule then
		return false, 0
	end
	local data = EconomyModule.getPlayerData(player)
	if not data then
		return false, 0
	end
	local now = os.clock()
	if data.lockExpiresAt > now then
		return true, math.ceil(data.lockExpiresAt - now)
	end
	return false, 0
end

function Threat.purchaseBaseLock(player: Player): (boolean, string)
	if not EconomyModule then
		return false, "System not ready"
	end
	local data = EconomyModule.getPlayerData(player)
	if not data then
		return false, "Player data not ready"
	end

	local now = os.clock()
	if data.lockExpiresAt > now then
		local rem = math.ceil(data.lockExpiresAt - now)
		EconomyModule.sendToast(player, string.format("Base Lock is already active (%ds left)!", rem), Color3.fromRGB(100, 220, 255))
		return false, "Already active"
	end

	if data.lockCooldownUntil > now then
		local cd = math.ceil(data.lockCooldownUntil - now)
		EconomyModule.sendToast(player, string.format("Base Lock on cooldown (%ds remaining)!", cd), Color3.fromRGB(255, 160, 80))
		return false, "On cooldown"
	end

	if data.cash < Config.BASE_LOCK_COST then
		EconomyModule.sendToast(
			player,
			string.format("Need $%d for Base Lock! (You have $%d)", Config.BASE_LOCK_COST, math.floor(data.cash)),
			Color3.fromRGB(255, 95, 95)
		)
		return false, "Not enough cash"
	end

	data.cash -= Config.BASE_LOCK_COST
	data.lockExpiresAt = now + Config.BASE_LOCK_DURATION
	data.lockCooldownUntil = now + Config.BASE_LOCK_COOLDOWN

	if data.plotIndex and updateLockVisualCallback then
		updateLockVisualCallback(data.plotIndex, true, Config.BASE_LOCK_DURATION)
	end

	EconomyModule.replicate(player)
	EconomyModule.sendToast(
		player,
		string.format("BASE LOCKED for %ds! %s cannot steal from you!", Config.BASE_LOCK_DURATION, Config.THIEF_NAME),
		Color3.fromRGB(80, 255, 160)
	)

	return true, "Base Lock activated"
end

local function buildThiefModel(spawnPos: Vector3): (Model, BasePart, TextLabel)
	local model = Instance.new("Model")
	model.Name = Config.THIEF_NAME

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2.4, 3.2, 1.4)
	root.Position = spawnPos
	root.Anchored = true
	root.CanCollide = false
	root.Color = Color3.fromRGB(22, 20, 30)
	root.Material = Enum.Material.SmoothPlastic
	root.Parent = model

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2.4, 3.0, 1.3)
	torso.Position = spawnPos
	torso.Anchored = true
	torso.CanCollide = false
	torso.Color = Color3.fromRGB(25, 22, 35)
	torso.Material = Enum.Material.Fabric
	torso.Parent = model

	local cloakTrim = Instance.new("Part")
	cloakTrim.Name = "NeonTrim"
	cloakTrim.Size = Vector3.new(2.5, 0.35, 1.4)
	cloakTrim.Position = spawnPos + Vector3.new(0, 0.9, 0)
	cloakTrim.Anchored = true
	cloakTrim.CanCollide = false
	cloakTrim.Color = Color3.fromRGB(255, 45, 75)
	cloakTrim.Material = Enum.Material.Neon
	cloakTrim.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.8, 1.8, 1.8)
	head.Position = spawnPos + Vector3.new(0, 2.3, 0)
	head.Anchored = true
	head.CanCollide = false
	head.Color = Color3.fromRGB(15, 15, 20)
	head.Material = Enum.Material.SmoothPlastic
	head.Parent = model

	local leftEye = Instance.new("Part")
	leftEye.Name = "LeftEye"
	leftEye.Size = Vector3.new(0.35, 0.2, 0.2)
	leftEye.Position = spawnPos + Vector3.new(-0.4, 2.4, -0.8)
	leftEye.Anchored = true
	leftEye.CanCollide = false
	leftEye.Color = Color3.fromRGB(255, 40, 60)
	leftEye.Material = Enum.Material.Neon
	leftEye.Parent = model

	local rightEye = Instance.new("Part")
	rightEye.Name = "RightEye"
	rightEye.Size = Vector3.new(0.35, 0.2, 0.2)
	rightEye.Position = spawnPos + Vector3.new(0.4, 2.4, -0.8)
	rightEye.Anchored = true
	rightEye.CanCollide = false
	rightEye.Color = Color3.fromRGB(255, 40, 60)
	rightEye.Material = Enum.Material.Neon
	rightEye.Parent = model

	local leftArm = Instance.new("Part")
	leftArm.Name = "LeftArm"
	leftArm.Size = Vector3.new(0.65, 2.5, 0.65)
	leftArm.Position = spawnPos + Vector3.new(-1.55, 0.2, -0.3)
	leftArm.Anchored = true
	leftArm.CanCollide = false
	leftArm.Color = Color3.fromRGB(20, 18, 28)
	leftArm.Material = Enum.Material.SmoothPlastic
	leftArm.Parent = model

	local rightArm = Instance.new("Part")
	rightArm.Name = "RightArm"
	rightArm.Size = Vector3.new(0.65, 2.5, 0.65)
	rightArm.Position = spawnPos + Vector3.new(1.55, 0.2, -0.3)
	rightArm.Anchored = true
	rightArm.CanCollide = false
	rightArm.Color = Color3.fromRGB(20, 18, 28)
	rightArm.Material = Enum.Material.SmoothPlastic
	rightArm.Parent = model

	local shadowParticles = Instance.new("ParticleEmitter")
	shadowParticles.Name = "ShadowMist"
	shadowParticles.Color = ColorSequence.new(Color3.fromRGB(255, 40, 70), Color3.fromRGB(20, 10, 25))
	shadowParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 0),
	})
	shadowParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	shadowParticles.Lifetime = NumberRange.new(0.5, 1.1)
	shadowParticles.Rate = 18
	shadowParticles.Speed = NumberRange.new(1, 2.5)
	shadowParticles.Parent = torso

	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = model

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ThiefNameTag"
	billboard.Adornee = head
	billboard.Size = UDim2.fromOffset(220, 56)
	billboard.StudsOffset = Vector3.new(0, 2.4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head

	local tagFrame = Instance.new("Frame")
	tagFrame.Size = UDim2.fromScale(1, 1)
	tagFrame.BackgroundColor3 = Color3.fromRGB(20, 12, 24)
	tagFrame.BackgroundTransparency = 0.15
	tagFrame.BorderSizePixel = 0
	tagFrame.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = tagFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 50, 75)
	stroke.Thickness = 2
	stroke.Parent = tagFrame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "StatusLabel"
	nameLabel.Size = UDim2.new(1, -10, 1, -6)
	nameLabel.Position = UDim2.fromOffset(5, 3)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Color3.fromRGB(255, 95, 110)
	nameLabel.TextScaled = true
	nameLabel.Text = Config.THIEF_NAME .. "\n[Prowling...]"
	nameLabel.Parent = tagFrame

	model.PrimaryPart = root
	model.Parent = Workspace

	return model, root, nameLabel
end

local function positionThiefModel(model: Model, pos: Vector3, lookAt: Vector3, carryingLoot: boolean)
	local flatLook = Vector3.new(lookAt.X, pos.Y, lookAt.Z)
	local cf = if (flatLook - pos).Magnitude > 0.05 then CFrame.lookAt(pos, flatLook) else CFrame.new(pos)
	local bob = math.sin(os.clock() * 10) * 0.25

	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	local torso = model:FindFirstChild("Torso") :: BasePart?
	local trim = model:FindFirstChild("NeonTrim") :: BasePart?
	local head = model:FindFirstChild("Head") :: BasePart?
	local leftEye = model:FindFirstChild("LeftEye") :: BasePart?
	local rightEye = model:FindFirstChild("RightEye") :: BasePart?
	local leftArm = model:FindFirstChild("LeftArm") :: BasePart?
	local rightArm = model:FindFirstChild("RightArm") :: BasePart?
	local lootOrb = model:FindFirstChild("StolenLootOrb") :: BasePart?

	local armSwing = math.sin(os.clock() * 14) * math.rad(28)

	if root then
		root.CFrame = cf + Vector3.new(0, bob, 0)
	end
	if torso then
		torso.CFrame = cf + Vector3.new(0, bob, 0)
	end
	if trim then
		trim.CFrame = cf + Vector3.new(0, 0.9 + bob, 0)
	end
	if head then
		head.CFrame = cf + Vector3.new(0, 2.3 + bob, 0)
	end
	if leftEye then
		leftEye.CFrame = cf * CFrame.new(-0.4, 2.4 + bob, -0.85)
	end
	if rightEye then
		rightEye.CFrame = cf * CFrame.new(0.4, 2.4 + bob, -0.85)
	end
	if leftArm then
		leftArm.CFrame = (cf * CFrame.new(-1.55, 0.25 + bob, -0.35)) * CFrame.Angles(armSwing, 0, 0)
	end
	if rightArm then
		rightArm.CFrame = (cf * CFrame.new(1.55, 0.25 + bob, -0.35)) * CFrame.Angles(-armSwing, 0, 0)
	end
	if carryingLoot and lootOrb then
		lootOrb.CFrame = cf * CFrame.new(0, 1.4 + bob, -1.6)
	end
end

local function moveThiefTo(
	model: Model,
	startPos: Vector3,
	targetPos: Vector3,
	speed: number,
	carryingLoot: boolean,
	interruptCheck: ((Vector3) -> boolean)?
): (boolean, Vector3)
	local dist = (targetPos - startPos).Magnitude
	if dist < 0.5 then
		return false, targetPos
	end
	local duration = dist / speed
	local elapsed = 0
	local currentPos = startPos

	while elapsed < duration and model.Parent ~= nil do
		local dt = RunService.Heartbeat:Wait()
		elapsed += dt
		local alpha = math.clamp(elapsed / duration, 0, 1)
		currentPos = startPos:Lerp(targetPos, alpha)
		positionThiefModel(model, currentPos, targetPos, carryingLoot)

		if interruptCheck and interruptCheck(currentPos) then
			return true, currentPos
		end
	end

	return false, currentPos
end

function Threat.runRaidCycle()
	if not EconomyModule or not getPlotPositionCallback then
		return
	end

	local activePlayers = Players:GetPlayers()
	if #activePlayers == 0 then
		return
	end

	-- Pick a random player with a plot (prefer players with characters, otherwise any player)
	local candidatesWithChars: { Player } = {}
	local allCandidates: { Player } = {}
	for _, p in ipairs(activePlayers) do
		local pdata = EconomyModule.getPlayerData(p)
		if pdata and pdata.plotIndex then
			table.insert(allCandidates, p)
			if #pdata.characters > 0 then
				table.insert(candidatesWithChars, p)
			end
		end
	end

	local pool = if #candidatesWithChars > 0 then candidatesWithChars else allCandidates
	if #pool == 0 then
		return
	end

	local targetPlayer = pool[rng:NextInteger(1, #pool)]
	local targetData = EconomyModule.getPlayerData(targetPlayer)
	if not targetData or not targetData.plotIndex then
		return
	end

	local targetPlotPos = getPlotPositionCallback(targetData.plotIndex) + Vector3.new(0, 3.2, 0)
	local startPos = spawnEdgePosition

	EconomyModule.broadcastToast(
		string.format("WARNING: %s has emerged from the shadows and is heading toward %s's base!", Config.THIEF_NAME, targetPlayer.DisplayName),
		Color3.fromRGB(255, 75, 95)
	)

	local thiefModel, rootPart, statusLabel = buildThiefModel(startPos)
	local prowlTaunt = THIEF_PROWL_TAUNTS[rng:NextInteger(1, #THIEF_PROWL_TAUNTS)]
	statusLabel.Text = string.format("%s\nTarget: %s • %s", Config.THIEF_NAME, targetPlayer.DisplayName, prowlTaunt)

	-- Walk from spawn edge to target player's base
	moveThiefTo(thiefModel, startPos, targetPlotPos, 24, false, nil)

	if not targetPlayer.Parent then
		thiefModel:Destroy()
		return
	end

	-- Check Base Lock upon arrival
	local locked, remLock = Threat.isBaseLocked(targetPlayer)
	if locked then
		local blockedTaunt = THIEF_BLOCKED_TAUNTS[rng:NextInteger(1, #THIEF_BLOCKED_TAUNTS)]
		statusLabel.Text = string.format("%s\n[BLOCKED BY BASE LOCK!] %s", Config.THIEF_NAME, blockedTaunt)
		EconomyModule.sendToast(
			targetPlayer,
			string.format("Your Base Lock repelled %s! (%ds lock left)", Config.THIEF_NAME, remLock),
			Color3.fromRGB(80, 255, 165)
		)
		task.wait(1.2)
		moveThiefTo(thiefModel, targetPlotPos, startPos, 32, false, nil)
		thiefModel:Destroy()
		return
	end

	-- Attempt to steal highest-income character
	local stolen = EconomyModule.stealHighestIncomeCharacter(targetPlayer)
	if not stolen then
		statusLabel.Text = string.format("%s\n[Base Empty - Leaving]", Config.THIEF_NAME)
		EconomyModule.sendToast(
			targetPlayer,
			string.format("%s visited your base, but you had no Brainrots to steal!", Config.THIEF_NAME),
			Color3.fromRGB(200, 200, 220)
		)
		task.wait(1)
		moveThiefTo(thiefModel, targetPlotPos, startPos, 30, false, nil)
		thiefModel:Destroy()
		return
	end

	-- Attach visual stolen orb to the thief
	local lootOrb = Instance.new("Part")
	lootOrb.Name = "StolenLootOrb"
	lootOrb.Shape = Enum.PartType.Ball
	lootOrb.Size = Vector3.new(2.2, 2.2, 2.2)
	lootOrb.Anchored = true
	lootOrb.CanCollide = false
	lootOrb.Material = Enum.Material.Neon
	lootOrb.Color = Config.RARITY_COLORS[stolen.rarity] or Color3.fromRGB(255, 215, 50)
	lootOrb.Parent = thiefModel

	EconomyModule.sendToast(
		targetPlayer,
		string.format(
			"%s STOLE your %s ($%d/s)! Touch the thief within %ds to get it back!",
			Config.THIEF_NAME,
			stolen.name,
			stolen.effectiveIncome,
			Config.THIEF_DROP_WINDOW
		),
		Color3.fromRGB(255, 55, 75)
	)

	local stealTimestamp = os.clock()
	local recovered = false

	-- Also listen to BasePart.Touched on rootPart as direct touch backup
	local touchConn: RBXScriptConnection? = nil
	touchConn = rootPart.Touched:Connect(function(hit: BasePart)
		if recovered then
			return
		end
		if os.clock() - stealTimestamp > Config.THIEF_DROP_WINDOW then
			return
		end
		local character = targetPlayer.Character
		if character and hit:IsDescendantOf(character) then
			recovered = true
		end
	end)

	-- Run to the map edge over Config.THIEF_DROP_WINDOW (10s) so the owner has the full window to intercept
	local escapeDistance = (startPos - targetPlotPos).Magnitude
	local escapeSpeed = math.max(12, escapeDistance / (Config.THIEF_DROP_WINDOW + 0.5))

	local intercepted, _ = moveThiefTo(thiefModel, targetPlotPos, startPos, escapeSpeed, true, function(thiefPos: Vector3)
		local elapsed = os.clock() - stealTimestamp
		local remaining = math.max(0, Config.THIEF_DROP_WINDOW - elapsed)
		statusLabel.Text = string.format(
			"%s\nStole: %s (%.1fs to Touch!)",
			Config.THIEF_NAME,
			stolen.name,
			remaining
		)

		if recovered then
			return true
		end

		if elapsed <= Config.THIEF_DROP_WINDOW and targetPlayer.Character then
			local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp and (hrp.Position - thiefPos).Magnitude <= 8.5 then
				recovered = true
				return true
			end
		end
		return false
	end)

	if touchConn then
		touchConn:Disconnect()
	end

	if intercepted or recovered then
		EconomyModule.returnStolenCharacter(targetPlayer, stolen)
		local foiledTaunt = THIEF_FOILED_TAUNTS[rng:NextInteger(1, #THIEF_FOILED_TAUNTS)]
		statusLabel.Text = string.format("%s\n[FOILED! Dropped %s!] %s", Config.THIEF_NAME, stolen.name, foiledTaunt)
		EconomyModule.sendToast(
			targetPlayer,
			string.format("Recovered %s ($%d/s) from %s!", stolen.name, stolen.effectiveIncome, Config.THIEF_NAME),
			Color3.fromRGB(85, 255, 150)
		)
		task.wait(1.0)
	else
		EconomyModule.sendToast(
			targetPlayer,
			string.format("%s escaped with your %s!", Config.THIEF_NAME, stolen.name),
			Color3.fromRGB(255, 70, 70)
		)
	end

	thiefModel:Destroy()
end

function Threat.startLoop()
	-- Visual lock expiry monitor
	task.spawn(function()
		while true do
			task.wait(1)
			if EconomyModule and updateLockVisualCallback then
				local now = os.clock()
				for _, data in pairs(EconomyModule.getAllPlayerStates()) do
					if data.plotIndex then
						local isLocked = data.lockExpiresAt > now
						local rem = if isLocked then math.ceil(data.lockExpiresAt - now) else 0
						updateLockVisualCallback(data.plotIndex, isLocked, rem)
					end
				end
			end
		end
	end)

	-- Thief spawn timer loop (every 75-120 seconds)
	task.spawn(function()
		while true do
			local waitSeconds = rng:NextInteger(Config.THIEF_SPAWN_MIN, Config.THIEF_SPAWN_MAX)
			task.wait(waitSeconds)
			Threat.runRaidCycle()
		end
	end)
end

return Threat
