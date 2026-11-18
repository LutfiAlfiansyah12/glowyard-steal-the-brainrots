-- Server Bootstrap for Glowyard: Steal the Brainrots
-- Builds the runtime world (conveyor strip + podium, 4 base plots with 4 pedestals each,
-- neon lamp posts, thief spawn edge), assigns plots to players, runs conveyor character shop,
-- wires Economy and Threat modules, and handles RemoteEvents.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Economy = require(script:WaitForChild("Economy"))
local Threat = require(script:WaitForChild("Threat"))

local rng = Random.new()

--------------------------------------------------------------------------------
-- 1. RemoteEvents Setup
--------------------------------------------------------------------------------
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

local function createRemote(name: string): RemoteEvent
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotesFolder
	return r
end

local remotes = {
	StateUpdate = createRemote("StateUpdate"),
	ConveyorUpdate = createRemote("ConveyorUpdate"),
	Toast = createRemote("Toast"),
	RequestRebirth = createRemote("RequestRebirth"),
	RequestBaseLock = createRemote("RequestBaseLock"),
	RequestBuyConveyor = createRemote("RequestBuyConveyor"),
}

--------------------------------------------------------------------------------
-- 2. Procedural Brainrot Character Visual Builder
--------------------------------------------------------------------------------
local function createCharacterFigure(
	charDef: { [string]: any },
	mutationName: string,
	effectiveIncome: number?,
	priceText: string?
): Model
	local model = Instance.new("Model")
	model.Name = charDef.name

	local rarity = charDef.rarity
	local primaryColor = Config.RARITY_COLORS[rarity] or Color3.fromRGB(180, 180, 180)
	local secondaryColor = Config.RARITY_SECONDARY_COLORS[rarity] or Color3.fromRGB(90, 90, 100)
	local accentColor = charDef.accentColor or primaryColor

	local bodyMaterial = Enum.Material.SmoothPlastic
	local trimColor = primaryColor
	if mutationName == "Golden" then
		trimColor = Color3.fromRGB(255, 215, 40)
		bodyMaterial = Enum.Material.Metal
	elseif mutationName == "Neon" then
		trimColor = Color3.fromRGB(0, 255, 235)
		bodyMaterial = Enum.Material.Neon
	elseif mutationName == "Rainbow" then
		trimColor = Color3.fromRGB(255, 105, 240)
		bodyMaterial = Enum.Material.Neon
	elseif rarity == "Secret" then
		-- Black-gold styling for Secret rarity
		bodyMaterial = Enum.Material.Glass
	end

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2.6, 2.8, 2.0)
	body.Anchored = true
	body.CanCollide = false
	body.Material = bodyMaterial
	body.Color = if rarity == "Secret" then secondaryColor else accentColor
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(2.2, 2.2, 2.2)
	head.Anchored = true
	head.CanCollide = false
	head.Material = Enum.Material.SmoothPlastic
	head.Color = primaryColor
	head.Parent = model

	local crown = Instance.new("Part")
	crown.Name = "AuraRing"
	crown.Shape = Enum.PartType.Cylinder
	crown.Size = Vector3.new(0.35, 3.4, 3.4)
	crown.Anchored = true
	crown.CanCollide = false
	crown.Material = Enum.Material.Neon
	crown.Color = trimColor
	crown.Parent = model

	local leftEye = Instance.new("Part")
	leftEye.Name = "LeftEye"
	leftEye.Shape = Enum.PartType.Ball
	leftEye.Size = Vector3.new(0.45, 0.45, 0.45)
	leftEye.Anchored = true
	leftEye.CanCollide = false
	leftEye.Material = Enum.Material.Neon
	leftEye.Color = charDef.eyeColor or Color3.fromRGB(255, 255, 255)
	leftEye.Parent = model

	local rightEye = Instance.new("Part")
	rightEye.Name = "RightEye"
	rightEye.Shape = Enum.PartType.Ball
	rightEye.Size = Vector3.new(0.45, 0.45, 0.45)
	rightEye.Anchored = true
	rightEye.CanCollide = false
	rightEye.Material = Enum.Material.Neon
	rightEye.Color = charDef.eyeColor or Color3.fromRGB(255, 255, 255)
	rightEye.Parent = model

	-- Character-specific custom accessory assembly for distinctive 3D silhouette
	local acc = Instance.new("Part")
	acc.Name = "SignatureAccessory"
	acc.Anchored = true
	acc.CanCollide = false
	acc.Material = Enum.Material.Neon
	acc.Color = trimColor

	local accSecondary = Instance.new("Part")
	accSecondary.Name = "SecondaryAccessory"
	accSecondary.Anchored = true
	accSecondary.CanCollide = false
	accSecondary.Material = Enum.Material.SmoothPlastic
	accSecondary.Color = secondaryColor

	local leftArm = Instance.new("Part")
	leftArm.Name = "LeftArm"
	leftArm.Size = Vector3.new(0.75, 2.0, 0.75)
	leftArm.Anchored = true
	leftArm.CanCollide = false
	leftArm.Material = bodyMaterial
	leftArm.Color = primaryColor
	leftArm.Parent = model

	local rightArm = Instance.new("Part")
	rightArm.Name = "RightArm"
	rightArm.Size = Vector3.new(0.75, 2.0, 0.75)
	rightArm.Anchored = true
	rightArm.CanCollide = false
	rightArm.Material = bodyMaterial
	rightArm.Color = primaryColor
	rightArm.Parent = model

	local pedestalPlinth = Instance.new("Part")
	pedestalPlinth.Name = "CharacterPlinth"
	pedestalPlinth.Shape = Enum.PartType.Cylinder
	pedestalPlinth.Size = Vector3.new(0.45, 3.8, 3.8)
	pedestalPlinth.Anchored = true
	pedestalPlinth.CanCollide = false
	pedestalPlinth.Material = Enum.Material.Metal
	pedestalPlinth.Color = secondaryColor
	pedestalPlinth.Parent = model

	-- Add ParticleEmitter for Mutation or High-Rarity Visual Flair
	if mutationName ~= "None" or rarity == "Secret" or rarity == "Mythic" or rarity == "Legendary" then
		local particles = Instance.new("ParticleEmitter")
		particles.Name = "AuraSparkles"
		particles.Color = ColorSequence.new(trimColor, primaryColor)
		particles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.25),
			NumberSequenceKeypoint.new(0.5, 0.55),
			NumberSequenceKeypoint.new(1, 0),
		})
		particles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 1),
		})
		particles.Lifetime = NumberRange.new(0.8, 1.6)
		particles.Rate = if mutationName == "Rainbow" then 28 elseif mutationName == "Neon" then 20 else 12
		particles.Speed = NumberRange.new(1.5, 3.5)
		particles.SpreadAngle = Vector2.new(180, 180)
		particles.LightEmission = 0.85
		particles.Parent = head
	end

	local accType = charDef.accessoryType or "PaperCrown"
	if accType == "PaperCrown" then
		-- Kucek Papera: folded origami crown + laundry receipt scroll
		acc.Size = Vector3.new(1.5, 0.75, 1.5)
		accSecondary.Size = Vector3.new(1.8, 0.25, 0.9)
		accSecondary.Color = Color3.fromRGB(245, 245, 235)
	elseif accType == "ChiliFuse" then
		-- Tahu Mercon: glowing red chili fuse stem + crispy tofu crust rim
		acc.Size = Vector3.new(0.45, 1.5, 0.45)
		acc.Color = Color3.fromRGB(255, 50, 20)
		accSecondary.Size = Vector3.new(2.9, 0.45, 2.7)
		accSecondary.Color = Color3.fromRGB(210, 120, 40)
	elseif accType == "SneakerCleats" then
		-- Bola Kaki Jalan: oversized neon cleats + headband visor
		acc.Size = Vector3.new(2.8, 0.55, 2.4)
		accSecondary.Size = Vector3.new(2.3, 0.35, 2.3)
		accSecondary.Color = Color3.fromRGB(30, 35, 45)
	elseif accType == "SubwooferWings" then
		-- Walet Bass: acoustic woofer wings + bass reflex port
		acc.Size = Vector3.new(4.4, 1.7, 0.75)
		accSecondary.Shape = Enum.PartType.Cylinder
		accSecondary.Size = Vector3.new(0.9, 1.6, 1.6)
		accSecondary.Color = Color3.fromRGB(20, 25, 40)
	elseif accType == "NeonMane" then
		-- Kuda Pongkong: electric horse mane crest + hydraulic knee guards
		acc.Size = Vector3.new(0.65, 2.5, 2.1)
		accSecondary.Size = Vector3.new(2.6, 0.6, 1.9)
		accSecondary.Color = Color3.fromRGB(65, 140, 245)
	elseif accType == "SultanTurban" then
		-- Capybara Sultan: royal velvet turban + golden tangerine jewel
		acc.Shape = Enum.PartType.Ball
		acc.Size = Vector3.new(2.6, 1.65, 2.6)
		acc.Color = Color3.fromRGB(255, 210, 55)
		accSecondary.Shape = Enum.PartType.Ball
		accSecondary.Size = Vector3.new(0.95, 0.95, 0.95)
		accSecondary.Material = Enum.Material.Neon
		accSecondary.Color = Color3.fromRGB(255, 145, 20)
	elseif accType == "EightScanners" then
		-- Gurita Kasir: octagonal barcode scanner halo + register visor
		acc.Shape = Enum.PartType.Cylinder
		acc.Size = Vector3.new(0.5, 4.4, 4.4)
		accSecondary.Size = Vector3.new(2.4, 0.5, 1.4)
		accSecondary.Material = Enum.Material.Neon
		accSecondary.Color = Color3.fromRGB(255, 45, 95)
	elseif accType == "SatelliteDish" then
		-- Bapak Signal: orbital transponder dish + 9G dipole antenna spire
		acc.Shape = Enum.PartType.Cylinder
		acc.Size = Vector3.new(0.4, 3.3, 3.3)
		accSecondary.Size = Vector3.new(0.35, 2.8, 0.35)
		accSecondary.Material = Enum.Material.Metal
		accSecondary.Color = Color3.fromRGB(235, 240, 250)
	elseif accType == "GoldenBitCrown" then
		-- Screwdriver Sultan: hex driver crown + magnetic torque collar
		acc.Size = Vector3.new(1.15, 2.1, 1.15)
		acc.Color = Color3.fromRGB(255, 215, 50)
		accSecondary.Size = Vector3.new(3.0, 0.55, 2.4)
		accSecondary.Material = Enum.Material.Metal
		accSecondary.Color = Color3.fromRGB(220, 175, 45)
	elseif accType == "BriefcaseJaws" then
		-- Buaya Bail: crocodile snout + ruby-latched legal briefcase
		acc.Size = Vector3.new(2.4, 0.95, 2.8)
		accSecondary.Size = Vector3.new(1.9, 1.4, 0.65)
		accSecondary.Color = Color3.fromRGB(45, 15, 22)
	elseif accType == "SolarHalo" then
		-- Mira Matahari: blazing solar corona ring + triple-shade visor
		acc.Shape = Enum.PartType.Cylinder
		acc.Size = Vector3.new(0.35, 4.7, 4.7)
		accSecondary.Size = Vector3.new(2.4, 0.65, 1.2)
		accSecondary.Color = Color3.fromRGB(20, 15, 25)
	elseif accType == "FiberOpticCape" then
		-- Pak De Fiber: black-gold fiber optic mantle + core conduit
		acc.Size = Vector3.new(3.1, 3.5, 0.4)
		accSecondary.Size = Vector3.new(2.8, 0.6, 2.2)
		accSecondary.Material = Enum.Material.Neon
		accSecondary.Color = Color3.fromRGB(255, 215, 55)
	elseif accType == "ReverseHourglass" then
		-- Ratu Reverse: temporal hourglass spire + obsidian-gold collar
		acc.Size = Vector3.new(1.85, 2.45, 0.85)
		accSecondary.Shape = Enum.PartType.Cylinder
		accSecondary.Size = Vector3.new(0.4, 3.6, 3.6)
		accSecondary.Material = Enum.Material.Neon
		accSecondary.Color = Color3.fromRGB(255, 220, 75)
	else
		-- CelestialObeliskCrown for GLIMMERDEEN: sovereign black-gold monolith + floating halo
		acc.Size = Vector3.new(1.65, 2.9, 1.65)
		accSecondary.Shape = Enum.PartType.Cylinder
		accSecondary.Size = Vector3.new(0.45, 4.9, 4.9)
		accSecondary.Material = Enum.Material.Neon
		accSecondary.Color = Color3.fromRGB(255, 235, 110)
	end
	acc.Parent = model
	accSecondary.Parent = model

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "InfoTag"
	billboard.Adornee = head
	billboard.Size = UDim2.fromOffset(210, 66)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = if rarity == "Secret" then Color3.fromRGB(12, 12, 16) else Color3.fromRGB(18, 22, 32)
	frame.BackgroundTransparency = 0.12
	frame.BorderSizePixel = 0
	frame.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = trimColor
	stroke.Thickness = 2
	stroke.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -10, 1, -6)
	label.Position = UDim2.fromOffset(5, 3)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = primaryColor
	label.TextScaled = true
	label.RichText = true

	local mutPrefix = if mutationName ~= "None" then ("[" .. mutationName .. "] ") else ""
	if priceText then
		label.Text = string.format("%s%s\n[%s] • $%d/s\n%s", mutPrefix, charDef.name, rarity, charDef.income, priceText)
	else
		local inc = effectiveIncome or charDef.income
		label.Text = string.format("%s%s\n[%s] • +$%d/s", mutPrefix, charDef.name, rarity, inc)
	end
	label.Parent = frame

	model.PrimaryPart = body
	return model
end

local function positionCharacterFigure(model: Model, basePos: Vector3, faceTarget: Vector3)
	local lookFlat = Vector3.new(faceTarget.X, basePos.Y, faceTarget.Z)
	local cf = if (lookFlat - basePos).Magnitude > 0.05 then CFrame.lookAt(basePos, lookFlat) else CFrame.new(basePos)

	local body = model:FindFirstChild("Body") :: BasePart?
	local head = model:FindFirstChild("Head") :: BasePart?
	local crown = model:FindFirstChild("AuraRing") :: BasePart?
	local leftEye = model:FindFirstChild("LeftEye") :: BasePart?
	local rightEye = model:FindFirstChild("RightEye") :: BasePart?
	local acc = model:FindFirstChild("SignatureAccessory") :: BasePart?
	local accSecondary = model:FindFirstChild("SecondaryAccessory") :: BasePart?
	local leftArm = model:FindFirstChild("LeftArm") :: BasePart?
	local rightArm = model:FindFirstChild("RightArm") :: BasePart?
	local plinth = model:FindFirstChild("CharacterPlinth") :: BasePart?

	if plinth then
		plinth.CFrame = (cf * CFrame.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	end
	if body then
		body.CFrame = cf * CFrame.new(0, 1.5, 0)
	end
	if leftArm then
		leftArm.CFrame = cf * CFrame.new(-1.65, 1.65, 0) * CFrame.Angles(0, 0, math.rad(14))
	end
	if rightArm then
		rightArm.CFrame = cf * CFrame.new(1.65, 1.65, 0) * CFrame.Angles(0, 0, math.rad(-14))
	end
	if head then
		head.CFrame = cf * CFrame.new(0, 3.6, 0)
	end
	if crown then
		crown.CFrame = (cf * CFrame.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90))
	end
	if leftEye then
		leftEye.CFrame = cf * CFrame.new(-0.5, 3.8, -0.95)
	end
	if rightEye then
		rightEye.CFrame = cf * CFrame.new(0.5, 3.8, -0.95)
	end
	if acc then
		acc.CFrame = cf * CFrame.new(0, 5.0, 0)
	end
	if accSecondary then
		accSecondary.CFrame = cf * CFrame.new(0, 2.75, -0.85)
	end
end

--------------------------------------------------------------------------------
-- 3. Runtime World Construction
--------------------------------------------------------------------------------
local worldFolder = Instance.new("Folder")
worldFolder.Name = "GlowyardWorld"
worldFolder.Parent = Workspace

-- Style Baseplate
local baseplate = Workspace:FindFirstChild("Baseplate") :: Part?
if baseplate then
	baseplate.Size = Vector3.new(512, 20, 512)
	baseplate.Position = Vector3.new(0, -10, 0)
	baseplate.Color = Color3.fromRGB(26, 28, 38)
	baseplate.Material = Enum.Material.Concrete
end

-- SpawnLocation near center plaza
local spawnLocation = Instance.new("SpawnLocation")
spawnLocation.Name = "PlazaSpawn"
spawnLocation.Size = Vector3.new(12, 1, 12)
spawnLocation.Position = Vector3.new(0, 0.5, 32)
spawnLocation.Anchored = true
spawnLocation.Neutral = true
spawnLocation.Color = Color3.fromRGB(45, 55, 75)
spawnLocation.Material = Enum.Material.SmoothPlastic
spawnLocation.TopSurface = Enum.SurfaceType.Smooth
spawnLocation.Parent = worldFolder

-- Conveyor Strip & Rotating Display Podium at Center (0, 0, 0)
local conveyorFolder = Instance.new("Folder")
conveyorFolder.Name = "ConveyorStrip"
conveyorFolder.Parent = worldFolder

local beltBase = Instance.new("Part")
beltBase.Name = "ConveyorFrame"
beltBase.Size = Vector3.new(56, 1.4, 14)
beltBase.Position = Vector3.new(0, 0.7, 0)
beltBase.Anchored = true
beltBase.Color = Color3.fromRGB(35, 38, 50)
beltBase.Material = Enum.Material.Metal
beltBase.Parent = conveyorFolder

local beltSurface = Instance.new("Part")
beltSurface.Name = "ConveyorBelt"
beltSurface.Size = Vector3.new(52, 0.3, 10)
beltSurface.Position = Vector3.new(0, 1.5, 0)
beltSurface.Anchored = true
beltSurface.Color = Color3.fromRGB(20, 22, 28)
beltSurface.Material = Enum.Material.DiamondPlate
beltSurface.Parent = conveyorFolder

for i = -2, 2 do
	local stripe = Instance.new("Part")
	stripe.Name = "NeonChevron_" .. tostring(i)
	stripe.Size = Vector3.new(1.2, 0.35, 9.4)
	stripe.Position = Vector3.new(i * 10, 1.52, 0)
	stripe.Anchored = true
	stripe.CanCollide = false
	stripe.Color = Color3.fromRGB(0, 235, 255)
	stripe.Material = Enum.Material.Neon
	stripe.Parent = conveyorFolder
end

-- Central Podium for the active character on sale
local podiumPart = Instance.new("Part")
podiumPart.Name = "SalePodium"
podiumPart.Shape = Enum.PartType.Cylinder
podiumPart.Size = Vector3.new(2.2, 10, 10)
podiumPart.CFrame = CFrame.new(0, 2.5, 0) * CFrame.Angles(0, 0, math.rad(90))
podiumPart.Anchored = true
podiumPart.Color = Color3.fromRGB(50, 56, 76)
podiumPart.Material = Enum.Material.SmoothPlastic
podiumPart.Parent = conveyorFolder

local podiumRing = Instance.new("Part")
podiumRing.Name = "PodiumNeonRing"
podiumRing.Shape = Enum.PartType.Cylinder
podiumRing.Size = Vector3.new(0.4, 10.8, 10.8)
podiumRing.CFrame = CFrame.new(0, 3.5, 0) * CFrame.Angles(0, 0, math.rad(90))
podiumRing.Anchored = true
podiumRing.CanCollide = false
podiumRing.Color = Color3.fromRGB(0, 255, 210)
podiumRing.Material = Enum.Material.Neon
podiumRing.Parent = conveyorFolder

-- ProximityPrompt on the Podium for purchasing the showcased character
local buyPrompt = Instance.new("ProximityPrompt")
buyPrompt.Name = "BuyBrainrotPrompt"
buyPrompt.ActionText = "Buy Brainrot"
buyPrompt.ObjectText = "Conveyor Podium"
buyPrompt.HoldDuration = 0
buyPrompt.MaxActivationDistance = 18
buyPrompt.RequiresLineOfSight = false
buyPrompt.KeyboardKeyCode = Enum.KeyCode.E
buyPrompt.Parent = podiumPart

-- Podium Overhead Price Tag BillboardGui
local podiumBillboard = Instance.new("BillboardGui")
podiumBillboard.Name = "PodiumPriceTag"
podiumBillboard.Adornee = podiumPart
podiumBillboard.Size = UDim2.fromOffset(280, 95)
podiumBillboard.StudsOffset = Vector3.new(0, 8.8, 0)
podiumBillboard.AlwaysOnTop = true
podiumBillboard.Parent = podiumPart

local podiumTagFrame = Instance.new("Frame")
podiumTagFrame.Size = UDim2.fromScale(1, 1)
podiumTagFrame.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
podiumTagFrame.BackgroundTransparency = 0.08
podiumTagFrame.BorderSizePixel = 0
podiumTagFrame.Parent = podiumBillboard

local podiumCorner = Instance.new("UICorner")
podiumCorner.CornerRadius = UDim.new(0, 10)
podiumCorner.Parent = podiumTagFrame

local podiumStroke = Instance.new("UIStroke")
podiumStroke.Color = Color3.fromRGB(0, 255, 210)
podiumStroke.Thickness = 2.5
podiumStroke.Parent = podiumTagFrame

local podiumTitleLabel = Instance.new("TextLabel")
podiumTitleLabel.Name = "Title"
podiumTitleLabel.Size = UDim2.new(1, -12, 0.38, 0)
podiumTitleLabel.Position = UDim2.fromOffset(6, 4)
podiumTitleLabel.BackgroundTransparency = 1
podiumTitleLabel.Font = Enum.Font.GothamBlack
podiumTitleLabel.TextScaled = true
podiumTitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
podiumTitleLabel.Text = "CONVEYOR SHOP"
podiumTitleLabel.Parent = podiumTagFrame

local podiumStatsLabel = Instance.new("TextLabel")
podiumStatsLabel.Name = "Stats"
podiumStatsLabel.Size = UDim2.new(1, -12, 0.34, 0)
podiumStatsLabel.Position = UDim2.new(0, 6, 0.38, 0)
podiumStatsLabel.BackgroundTransparency = 1
podiumStatsLabel.Font = Enum.Font.GothamBold
podiumStatsLabel.TextScaled = true
podiumStatsLabel.TextColor3 = Color3.fromRGB(120, 255, 160)
podiumStatsLabel.Text = "$10 • +$1/s"
podiumStatsLabel.Parent = podiumTagFrame

local podiumMutationHint = Instance.new("TextLabel")
podiumMutationHint.Name = "Odds"
podiumMutationHint.Size = UDim2.new(1, -12, 0.24, 0)
podiumMutationHint.Position = UDim2.new(0, 6, 0.73, 0)
podiumMutationHint.BackgroundTransparency = 1
podiumMutationHint.Font = Enum.Font.GothamMedium
podiumMutationHint.TextScaled = true
podiumMutationHint.TextColor3 = Color3.fromRGB(255, 215, 90)
podiumMutationHint.Text = "Mutations: 8% Golden x2 | 3% Neon x3 | 1% Rainbow x5"
podiumMutationHint.Parent = podiumTagFrame

-- Neon Lamp Posts around the yard
local lampPositions = {
	Vector3.new(-36, 0, -25),
	Vector3.new(36, 0, -25),
	Vector3.new(-36, 0, 25),
	Vector3.new(36, 0, 25),
	Vector3.new(-95, 0, 0),
	Vector3.new(95, 0, 0),
	Vector3.new(0, 0, -95),
	Vector3.new(0, 0, 95),
}

local lampsFolder = Instance.new("Folder")
lampsFolder.Name = "NeonLampPosts"
lampsFolder.Parent = worldFolder

for idx, lpos in ipairs(lampPositions) do
	local lampModel = Instance.new("Model")
	lampModel.Name = "NeonLamp_" .. tostring(idx)

	local pole = Instance.new("Part")
	pole.Name = "Pole"
	pole.Size = Vector3.new(1.2, 16, 1.2)
	pole.Position = lpos + Vector3.new(0, 8, 0)
	pole.Anchored = true
	pole.Color = Color3.fromRGB(45, 50, 65)
	pole.Material = Enum.Material.Metal
	pole.Parent = lampModel

	local arm = Instance.new("Part")
	arm.Name = "Arm"
	arm.Size = Vector3.new(4, 0.8, 1.0)
	arm.Position = lpos + Vector3.new(1.4, 15.8, 0)
	arm.Anchored = true
	arm.Color = Color3.fromRGB(45, 50, 65)
	arm.Material = Enum.Material.Metal
	arm.Parent = lampModel

	local bulb = Instance.new("Part")
	bulb.Name = "NeonBulb"
	bulb.Size = Vector3.new(2.6, 0.8, 1.6)
	bulb.Position = lpos + Vector3.new(2.2, 15.2, 0)
	bulb.Anchored = true
	bulb.Color = if idx % 2 == 0 then Color3.fromRGB(0, 240, 255) else Color3.fromRGB(255, 90, 220)
	bulb.Material = Enum.Material.Neon
	bulb.Parent = lampModel

	local light = Instance.new("PointLight")
	light.Color = bulb.Color
	light.Brightness = 2.2
	light.Range = 36
	light.Parent = bulb

	lampModel.Parent = lampsFolder
end

-- Thief Spawn Edge Marker ("Maling Siluman" Lair Gate)
local thiefEdgePos = Vector3.new(0, 3, -155)
local thiefGate = Instance.new("Model")
thiefGate.Name = "ThiefSpawnEdge"

local gatePad = Instance.new("Part")
gatePad.Name = "ShadowEdgePad"
gatePad.Size = Vector3.new(26, 1, 12)
gatePad.Position = Vector3.new(0, 0.5, -155)
gatePad.Anchored = true
gatePad.Color = Color3.fromRGB(25, 12, 22)
gatePad.Material = Enum.Material.Slate
gatePad.Parent = thiefGate

local gateArch = Instance.new("Part")
gateArch.Name = "NeonThreatBeacon"
gateArch.Size = Vector3.new(22, 0.8, 1.2)
gateArch.Position = Vector3.new(0, 1.2, -150)
gateArch.Anchored = true
gateArch.Color = Color3.fromRGB(255, 45, 75)
gateArch.Material = Enum.Material.Neon
gateArch.Parent = thiefGate

local gateSign = Instance.new("BillboardGui")
gateSign.Size = UDim2.fromOffset(240, 50)
gateSign.Adornee = gateArch
gateSign.StudsOffset = Vector3.new(0, 4.5, 0)
gateSign.AlwaysOnTop = true
gateSign.Parent = gateArch

local gateText = Instance.new("TextLabel")
gateText.Size = UDim2.fromScale(1, 1)
gateText.BackgroundTransparency = 1
gateText.Font = Enum.Font.GothamBlack
gateText.TextScaled = true
gateText.TextColor3 = Color3.fromRGB(255, 70, 95)
gateText.Text = "SHADOW EDGE: MALING SILUMAN SPAWN"
gateText.Parent = gateSign

thiefGate.Parent = worldFolder

-- Four Rarity Ladder Showcase Pillars around the Central Conveyor Plaza
local pillarsFolder = Instance.new("Folder")
pillarsFolder.Name = "RarityShowcasePillars"
pillarsFolder.Parent = worldFolder

local pillarSpecs = {
	{ pos = Vector3.new(-28, 0, -14), title = "COMMON & RARE", detail = "Kucek Papera $1/s • Tahu Mercon $2/s\nBola Kaki Jalan $3/s • Walet Bass $8/s\nKuda Pongkong $10/s", color = Config.RARITY_COLORS.Rare },
	{ pos = Vector3.new(28, 0, -14), title = "EPIC & LEGENDARY", detail = "Capybara Sultan $25/s • Gurita Kasir $30/s\nBapak Signal $60/s • Screwdriver Sultan $75/s", color = Config.RARITY_COLORS.Legendary },
	{ pos = Vector3.new(-28, 0, 14), title = "MYTHIC & SECRET", detail = "Buaya Bail $150/s • Mira Matahari $180/s\nPak De Fiber $400/s • Ratu Reverse $500/s\nGLIMMERDEEN $750/s", color = Config.RARITY_COLORS.Secret },
	{ pos = Vector3.new(28, 0, 14), title = "MUTATIONS & REBIRTH", detail = "8% Golden (x2) • 3% Neon (x3) • 1% Rainbow (x5)\nRebirth: $25,000 x (rebirths+1) -> +0.5x Mult\nBase Lock: $500 (60s shield / 120s CD)", color = Color3.fromRGB(0, 255, 220) },
}

for pIdx, pSpec in ipairs(pillarSpecs) do
	local obelisk = Instance.new("Part")
	obelisk.Name = "InfoMonolith_" .. tostring(pIdx)
	obelisk.Size = Vector3.new(6.5, 9.5, 1.4)
	obelisk.Position = pSpec.pos + Vector3.new(0, 4.75, 0)
	obelisk.Anchored = true
	obelisk.Color = Color3.fromRGB(24, 28, 40)
	obelisk.Material = Enum.Material.Metal
	obelisk.Parent = pillarsFolder

	local trim = Instance.new("Part")
	trim.Name = "MonolithTrim_" .. tostring(pIdx)
	trim.Size = Vector3.new(6.9, 0.45, 1.65)
	trim.Position = pSpec.pos + Vector3.new(0, 9.5, 0)
	trim.Anchored = true
	trim.Color = pSpec.color
	trim.Material = Enum.Material.Neon
	trim.Parent = pillarsFolder

	local bGui = Instance.new("BillboardGui")
	bGui.Size = UDim2.fromOffset(230, 86)
	bGui.Adornee = obelisk
	bGui.StudsOffset = Vector3.new(0, 1.5, 0)
	bGui.AlwaysOnTop = false
	bGui.MaxDistance = 85
	bGui.Parent = obelisk

	local bFrame = Instance.new("Frame")
	bFrame.Size = UDim2.fromScale(1, 1)
	bFrame.BackgroundColor3 = Color3.fromRGB(14, 18, 28)
	bFrame.BackgroundTransparency = 0.1
	bFrame.BorderSizePixel = 0
	bFrame.Parent = bGui

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 8)
	bCorner.Parent = bFrame

	local bStroke = Instance.new("UIStroke")
	bStroke.Color = pSpec.color
	bStroke.Thickness = 2
	bStroke.Parent = bFrame

	local bLabel = Instance.new("TextLabel")
	bLabel.Size = UDim2.new(1, -12, 1, -8)
	bLabel.Position = UDim2.fromOffset(6, 4)
	bLabel.BackgroundTransparency = 1
	bLabel.Font = Enum.Font.GothamBold
	bLabel.TextColor3 = pSpec.color
	bLabel.TextScaled = true
	bLabel.Text = pSpec.title .. "\n" .. pSpec.detail
	bLabel.Parent = bFrame
end

--------------------------------------------------------------------------------
-- 4. Four Player Base Plots (Each with 4 Pedestals + Lock Barrier Visual)
--------------------------------------------------------------------------------
type PlotInfo = {
	index: number,
	center: Vector3,
	owner: Player?,
	model: Model,
	signLabel: TextLabel,
	pedestals: { BasePart },
	figureFolder: Folder,
	lockShield: BasePart,
}

local plots: { PlotInfo } = {}
local plotConfigs = {
	{ index = 1, center = Vector3.new(-68, 0, -68), color = Color3.fromRGB(70, 180, 255) },
	{ index = 2, center = Vector3.new(68, 0, -68), color = Color3.fromRGB(255, 145, 65) },
	{ index = 3, center = Vector3.new(-68, 0, 68), color = Color3.fromRGB(165, 95, 255) },
	{ index = 4, center = Vector3.new(68, 0, 68), color = Color3.fromRGB(80, 240, 155) },
}

local pedestalOffsets = {
	Vector3.new(-11, 0, -11),
	Vector3.new(11, 0, -11),
	Vector3.new(-11, 0, 11),
	Vector3.new(11, 0, 11),
}

local plotsFolder = Instance.new("Folder")
plotsFolder.Name = "BasePlots"
plotsFolder.Parent = worldFolder

for _, pcfg in ipairs(plotConfigs) do
	local plotModel = Instance.new("Model")
	plotModel.Name = "BasePlot_" .. tostring(pcfg.index)

	local floor = Instance.new("Part")
	floor.Name = "PlotFloor"
	floor.Size = Vector3.new(38, 1, 38)
	floor.Position = pcfg.center + Vector3.new(0, 0.5, 0)
	floor.Anchored = true
	floor.Color = Color3.fromRGB(36, 40, 54)
	floor.Material = Enum.Material.SmoothPlastic
	floor.Parent = plotModel

	local border = Instance.new("Part")
	border.Name = "NeonBorder"
	border.Size = Vector3.new(39.2, 0.5, 39.2)
	border.Position = pcfg.center + Vector3.new(0, 0.3, 0)
	border.Anchored = true
	border.Color = pcfg.color
	border.Material = Enum.Material.Neon
	border.Parent = plotModel

	local signPost = Instance.new("Part")
	signPost.Name = "SignPost"
	signPost.Size = Vector3.new(8, 3.5, 1)
	signPost.Position = pcfg.center + Vector3.new(0, 3.2, -18.5)
	signPost.Anchored = true
	signPost.Color = Color3.fromRGB(25, 28, 38)
	signPost.Material = Enum.Material.Metal
	signPost.Parent = plotModel

	local signGui = Instance.new("BillboardGui")
	signGui.Size = UDim2.fromOffset(220, 60)
	signGui.Adornee = signPost
	signGui.StudsOffset = Vector3.new(0, 2.5, 0)
	signGui.AlwaysOnTop = true
	signGui.Parent = signPost

	local signLabel = Instance.new("TextLabel")
	signLabel.Size = UDim2.fromScale(1, 1)
	signLabel.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
	signLabel.BackgroundTransparency = 0.15
	signLabel.Font = Enum.Font.GothamBold
	signLabel.TextColor3 = pcfg.color
	signLabel.TextScaled = true
	signLabel.Text = string.format("BASE #%d\n[Unclaimed]", pcfg.index)
	signLabel.Parent = signGui

	local signCorner = Instance.new("UICorner")
	signCorner.CornerRadius = UDim.new(0, 8)
	signCorner.Parent = signLabel

	-- 4 Pedestals per Base Plot
	local pedestals: { BasePart } = {}
	for sIdx, offset in ipairs(pedestalOffsets) do
		local ped = Instance.new("Part")
		ped.Name = "Pedestal_" .. tostring(sIdx)
		ped.Size = Vector3.new(7, 1.8, 7)
		ped.Position = pcfg.center + offset + Vector3.new(0, 1.4, 0)
		ped.Anchored = true
		ped.Color = Color3.fromRGB(52, 58, 78)
		ped.Material = Enum.Material.SmoothPlastic
		ped.Parent = plotModel

		local topPlate = Instance.new("Part")
		topPlate.Name = "PedestalTop_" .. tostring(sIdx)
		topPlate.Size = Vector3.new(6.2, 0.3, 6.2)
		topPlate.Position = ped.Position + Vector3.new(0, 1.0, 0)
		topPlate.Anchored = true
		topPlate.Color = pcfg.color
		topPlate.Material = Enum.Material.Neon
		topPlate.Parent = plotModel

		table.insert(pedestals, ped)
	end

	-- Base Lock Visual Forcefield Shield
	local lockShield = Instance.new("Part")
	lockShield.Name = "BaseLockShield"
	lockShield.Shape = Enum.PartType.Ball
	lockShield.Size = Vector3.new(44, 44, 44)
	lockShield.Position = pcfg.center + Vector3.new(0, 4, 0)
	lockShield.Anchored = true
	lockShield.CanCollide = false
	lockShield.Transparency = 1
	lockShield.Color = Color3.fromRGB(60, 255, 170)
	lockShield.Material = Enum.Material.ForceField
	lockShield.Parent = plotModel

	local figureFolder = Instance.new("Folder")
	figureFolder.Name = "PlacedFigures"
	figureFolder.Parent = plotModel

	plotModel.Parent = plotsFolder

	table.insert(plots, {
		index = pcfg.index,
		center = pcfg.center,
		owner = nil,
		model = plotModel,
		signLabel = signLabel,
		pedestals = pedestals,
		figureFolder = figureFolder,
		lockShield = lockShield,
	})
end

local function getPlotPosition(plotIndex: number): Vector3
	local plot = plots[plotIndex]
	return if plot then plot.center else Vector3.new(0, 0, 0)
end

local function updateLockVisual(plotIndex: number, isLocked: boolean, remainingSeconds: number)
	local plot = plots[plotIndex]
	if not plot then
		return
	end
	plot.lockShield.Transparency = if isLocked then 0.55 else 1
	if plot.owner then
		local lockText = if isLocked then string.format("\n[LOCKED: %ds]", remainingSeconds) else ""
		plot.signLabel.Text = string.format("BASE #%d • %s%s", plot.index, plot.owner.DisplayName, lockText)
	end
end

local function rebuildBaseVisuals(player: Player, data: Economy.PlayerData)
	if not data.plotIndex then
		return
	end
	local plot = plots[data.plotIndex]
	if not plot then
		return
	end

	plot.figureFolder:ClearAllChildren()

	for _, placed in ipairs(data.characters) do
		local charDef = Config.CHARACTER_BY_NAME[placed.name]
		local pedestal = plot.pedestals[placed.slotIndex]
		if charDef and pedestal then
			local fig = createCharacterFigure(charDef, placed.mutation, placed.effectiveIncome, nil)
			positionCharacterFigure(fig, pedestal.Position + Vector3.new(0, 1.1, 0), Vector3.new(0, 2, 0))
			fig.Parent = plot.figureFolder
		end
	end
end

--------------------------------------------------------------------------------
-- 5. Conveyor Podium Rotation & Purchase Logic
--------------------------------------------------------------------------------
local currentShowcaseChar: { [string]: any } = Config.CHARACTERS[1]
local showcaseModel: Model? = nil
local nextRotationTime = 0

local function broadcastConveyorState()
	local remaining = math.max(0, math.ceil(nextRotationTime - os.clock()))
	remotes.ConveyorUpdate:FireAllClients({
		name = currentShowcaseChar.name,
		rarity = currentShowcaseChar.rarity,
		income = currentShowcaseChar.income,
		price = currentShowcaseChar.price,
		secondsRemaining = remaining,
	})
end

local function setConveyorCharacter(charDef: { [string]: any })
	currentShowcaseChar = charDef
	nextRotationTime = os.clock() + Config.CONVEYOR_ROTATE_INTERVAL

	if showcaseModel then
		showcaseModel:Destroy()
		showcaseModel = nil
	end

	local rarityColor = Config.RARITY_COLORS[charDef.rarity] or Color3.fromRGB(255, 255, 255)
	podiumRing.Color = rarityColor
	podiumStroke.Color = rarityColor
	podiumTitleLabel.TextColor3 = rarityColor
	podiumTitleLabel.Text = string.format("%s [%s]", charDef.name, string.upper(charDef.rarity))
	podiumStatsLabel.Text = string.format("Price: $%d  •  Income: +$%d/s", charDef.price, charDef.income)

	buyPrompt.ObjectText = string.format("%s (%s)", charDef.name, charDef.rarity)
	buyPrompt.ActionText = string.format("Buy for $%d (+$%d/s)", charDef.price, charDef.income)

	local fig = createCharacterFigure(charDef, "None", charDef.income, string.format("BUY: $%d", charDef.price))
	positionCharacterFigure(fig, Vector3.new(0, 3.7, 0), Vector3.new(0, 3.7, 25))
	fig.Parent = conveyorFolder
	showcaseModel = fig

	broadcastConveyorState()
end

local function handleConveyorPurchase(player: Player)
	if not currentShowcaseChar then
		return
	end
	local success, _ = Economy.purchaseCharacter(player, currentShowcaseChar, rng)
	if success then
		-- Immediately roll a fresh character onto the conveyor podium
		setConveyorCharacter(Config.pickConveyorCharacter(rng))
	end
end

buyPrompt.Triggered:Connect(function(player: Player)
	handleConveyorPurchase(player)
end)

remotes.RequestBuyConveyor.OnServerEvent:Connect(function(player: Player)
	handleConveyorPurchase(player)
end)

remotes.RequestRebirth.OnServerEvent:Connect(function(player: Player)
	Economy.attemptRebirth(player)
end)

remotes.RequestBaseLock.OnServerEvent:Connect(function(player: Player)
	Threat.purchaseBaseLock(player)
end)

--------------------------------------------------------------------------------
-- 6. Wire Modules & Player Lifecycle
--------------------------------------------------------------------------------
Economy.init({
	StateUpdate = remotes.StateUpdate,
	Toast = remotes.Toast,
}, rebuildBaseVisuals)

Threat.init(Economy, getPlotPosition, updateLockVisual, thiefEdgePos)

local function assignPlot(player: Player): number?
	for _, plot in ipairs(plots) do
		if plot.owner == nil then
			plot.owner = player
			plot.signLabel.Text = string.format("BASE #%d • %s", plot.index, player.DisplayName)
			return plot.index
		end
	end
	return 1
end

local function releasePlot(player: Player)
	for _, plot in ipairs(plots) do
		if plot.owner == player then
			plot.owner = nil
			plot.figureFolder:ClearAllChildren()
			plot.lockShield.Transparency = 1
			plot.signLabel.Text = string.format("BASE #%d\n[Unclaimed]", plot.index)
		end
	end
end

local function onPlayerAdded(player: Player)
	local plotIdx = assignPlot(player)
	local data = Economy.initPlayer(player, plotIdx)

	-- Give new players 1 starter Kucek Papera so their base immediately generates $1/s
	-- while still keeping enough cash/income to interact with the conveyor right away.
	if #data.characters == 0 then
		local starterDef = Config.CHARACTERS[1]
		table.insert(data.characters, {
			uid = "starter_1",
			name = starterDef.name,
			rarity = starterDef.rarity,
			baseIncome = starterDef.income,
			mutation = "None",
			mutationMultiplier = 1,
			effectiveIncome = starterDef.income,
			slotIndex = 1,
		})
		rebuildBaseVisuals(player, data)
		Economy.replicate(player)
	end

	player.CharacterAdded:Connect(function(character)
		task.wait(0.15)
		local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp and plotIdx and plots[plotIdx] then
			hrp.CFrame = CFrame.new(plots[plotIdx].center + Vector3.new(0, 4, 0), Vector3.new(0, 4, 0))
		end
	end)

	task.defer(function()
		broadcastConveyorState()
		Economy.sendToast(
			player,
			string.format("Welcome to Glowyard! Assigned Base #%d. Buy Brainrots at the center conveyor!", plotIdx or 1),
			Color3.fromRGB(100, 235, 255)
		)
	end)
end

local function onPlayerRemoving(player: Player)
	releasePlot(player)
	Economy.removePlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, existingPlayer in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, existingPlayer)
end

-- Start Economy 1s tick loop & Threat thief loop
Economy.startTickLoop()
Threat.startLoop()

-- Start Conveyor showcase rotation loop (start with an affordable Common character first)
setConveyorCharacter(Config.CHARACTERS[1])
task.spawn(function()
	while true do
		task.wait(0.5)
		if os.clock() >= nextRotationTime then
			setConveyorCharacter(Config.pickConveyorCharacter(rng))
		else
			broadcastConveyorState()
		end
	end
end)

--------------------------------------------------------------------------------
-- 7. Yard Perimeter Neon Arches & Path Walkways (Runtime Visual Polish)
--------------------------------------------------------------------------------
local walkwaysFolder = Instance.new("Folder")
walkwaysFolder.Name = "NeonWalkways"
walkwaysFolder.Parent = worldFolder

for _, pcfg in ipairs(plotConfigs) do
	local midPoint = pcfg.center * 0.5
	local diff = pcfg.center - Vector3.new(0, 0, 0)
	local dist = math.max(10, diff.Magnitude - 34)
	local pathPart = Instance.new("Part")
	pathPart.Name = "WalkwayToPlot_" .. tostring(pcfg.index)
	pathPart.Size = Vector3.new(6, 0.25, dist)
	pathPart.CFrame = CFrame.lookAt(Vector3.new(midPoint.X, 0.15, midPoint.Z), Vector3.new(pcfg.center.X, 0.15, pcfg.center.Z))
	pathPart.Anchored = true
	pathPart.Color = Color3.fromRGB(34, 38, 52)
	pathPart.Material = Enum.Material.SmoothPlastic
	pathPart.Parent = walkwaysFolder

	local pathStrip = Instance.new("Part")
	pathStrip.Name = "NeonGuideStrip_" .. tostring(pcfg.index)
	pathStrip.Size = Vector3.new(0.65, 0.3, dist - 2)
	pathStrip.CFrame = pathPart.CFrame + Vector3.new(0, 0.05, 0)
	pathStrip.Anchored = true
	pathStrip.CanCollide = false
	pathStrip.Color = pcfg.color
	pathStrip.Material = Enum.Material.Neon
	pathStrip.Parent = walkwaysFolder
end

-- Smoothly rotate the active conveyor showcase figure's aura ring
local RunService = game:GetService("RunService")
local spinAngle = 0
RunService.Heartbeat:Connect(function(dt: number)
	spinAngle += dt * 1.1
	if showcaseModel and showcaseModel.Parent then
		local lookX = math.sin(spinAngle) * 20
		local lookZ = math.cos(spinAngle) * 20
		positionCharacterFigure(showcaseModel, Vector3.new(0, 3.7, 0), Vector3.new(lookX, 3.7, lookZ))
	end
end)
