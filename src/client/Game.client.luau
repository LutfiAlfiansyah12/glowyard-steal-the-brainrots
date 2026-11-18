-- Client HUD & Feedback for Glowyard: Steal the Brainrots
-- Builds ScreenGui HUD in code (kept clear of the top-left Roblox menu area):
--   * Top-center Cash & /s rate banner + Conveyor Podium live buy status
--   * Right-side Base Inventory list (4 slots: character name, rarity color, mutation, +$/s)
--   * Bottom-right action buttons: Base Lock ($500, 60s lock / 120s cooldown) & Rebirth ($25,000 x (rebirths+1))
--   * Toast notification stack

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StateUpdateRemote = Remotes:WaitForChild("StateUpdate") :: RemoteEvent
local ConveyorUpdateRemote = Remotes:WaitForChild("ConveyorUpdate") :: RemoteEvent
local ToastRemote = Remotes:WaitForChild("Toast") :: RemoteEvent
local RequestRebirthRemote = Remotes:WaitForChild("RequestRebirth") :: RemoteEvent
local RequestBaseLockRemote = Remotes:WaitForChild("RequestBaseLock") :: RemoteEvent
local RequestBuyConveyorRemote = Remotes:WaitForChild("RequestBuyConveyor") :: RemoteEvent

local function formatMoney(amount: number): string
	local formatted = tostring(math.floor(amount))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then
			break
		end
	end
	return "$" .. formatted
end

--------------------------------------------------------------------------------
-- 1. ScreenGui Construction (Clear of top-left Roblox menu corner)
--------------------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GlowyardHud"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Top-Center Economy & Conveyor Banner
local topBanner = Instance.new("Frame")
topBanner.Name = "TopBanner"
topBanner.AnchorPoint = Vector2.new(0.5, 0)
topBanner.Position = UDim2.new(0.5, 0, 0, 10)
topBanner.Size = UDim2.fromOffset(460, 86)
topBanner.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
topBanner.BackgroundTransparency = 0.1
topBanner.BorderSizePixel = 0
topBanner.Parent = screenGui

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 12)
topCorner.Parent = topBanner

local topStroke = Instance.new("UIStroke")
topStroke.Color = Color3.fromRGB(0, 230, 255)
topStroke.Thickness = 2
topStroke.Parent = topBanner

local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "CashLabel"
cashLabel.Size = UDim2.new(0.58, -12, 0, 44)
cashLabel.Position = UDim2.fromOffset(14, 6)
cashLabel.BackgroundTransparency = 1
cashLabel.Font = Enum.Font.GothamBlack
cashLabel.TextColor3 = Color3.fromRGB(95, 255, 145)
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
cashLabel.TextScaled = true
cashLabel.Text = "$15  (+$1/s)"
cashLabel.Parent = topBanner

local multiplierLabel = Instance.new("TextLabel")
multiplierLabel.Name = "MultiplierLabel"
multiplierLabel.Size = UDim2.new(0.4, -12, 0, 40)
multiplierLabel.Position = UDim2.new(0.6, 0, 0, 8)
multiplierLabel.BackgroundTransparency = 1
multiplierLabel.Font = Enum.Font.GothamBold
multiplierLabel.TextColor3 = Color3.fromRGB(255, 215, 75)
multiplierLabel.TextXAlignment = Enum.TextXAlignment.Right
multiplierLabel.TextScaled = true
multiplierLabel.Text = "Rebirths: 0 (1.0x)"
multiplierLabel.Parent = topBanner

local conveyorStatusLabel = Instance.new("TextLabel")
conveyorStatusLabel.Name = "ConveyorStatus"
conveyorStatusLabel.Size = UDim2.new(0.7, -14, 0, 28)
conveyorStatusLabel.Position = UDim2.fromOffset(14, 52)
conveyorStatusLabel.BackgroundTransparency = 1
conveyorStatusLabel.Font = Enum.Font.GothamBold
conveyorStatusLabel.TextColor3 = Color3.fromRGB(210, 225, 255)
conveyorStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
conveyorStatusLabel.TextScaled = true
conveyorStatusLabel.Text = "Podium: Kucek Papera [Common] • $10 (+$1/s)"
conveyorStatusLabel.Parent = topBanner

local quickBuyButton = Instance.new("TextButton")
quickBuyButton.Name = "QuickBuyButton"
quickBuyButton.Size = UDim2.new(0.27, -10, 0, 28)
quickBuyButton.Position = UDim2.new(0.73, 0, 0, 52)
quickBuyButton.BackgroundColor3 = Color3.fromRGB(0, 195, 145)
quickBuyButton.Font = Enum.Font.GothamBold
quickBuyButton.TextColor3 = Color3.fromRGB(15, 20, 25)
quickBuyButton.TextScaled = true
quickBuyButton.Text = "Buy Podium"
quickBuyButton.Parent = topBanner

local qbCorner = Instance.new("UICorner")
qbCorner.CornerRadius = UDim.new(0, 6)
qbCorner.Parent = quickBuyButton

quickBuyButton.Activated:Connect(function()
	RequestBuyConveyorRemote:FireServer()
end)

--------------------------------------------------------------------------------
-- 2. Right-Side Base Inventory Panel + Action Buttons
--------------------------------------------------------------------------------
local rightPanel = Instance.new("Frame")
rightPanel.Name = "RightHudPanel"
rightPanel.AnchorPoint = Vector2.new(1, 0.5)
rightPanel.Position = UDim2.new(1, -14, 0.52, 0)
rightPanel.Size = UDim2.fromOffset(300, 390)
rightPanel.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
rightPanel.BackgroundTransparency = 0.1
rightPanel.BorderSizePixel = 0
rightPanel.Parent = screenGui

local rightCorner = Instance.new("UICorner")
rightCorner.CornerRadius = UDim.new(0, 12)
rightCorner.Parent = rightPanel

local rightStroke = Instance.new("UIStroke")
rightStroke.Color = Color3.fromRGB(130, 95, 255)
rightStroke.Thickness = 2
rightStroke.Parent = rightPanel

local invHeader = Instance.new("TextLabel")
invHeader.Name = "InventoryHeader"
invHeader.Size = UDim2.new(1, -20, 0, 32)
invHeader.Position = UDim2.fromOffset(10, 8)
invHeader.BackgroundTransparency = 1
invHeader.Font = Enum.Font.GothamBlack
invHeader.TextColor3 = Color3.fromRGB(235, 240, 255)
invHeader.TextScaled = true
invHeader.TextXAlignment = Enum.TextXAlignment.Left
invHeader.Text = "BASE PEDESTALS (0/4)"
invHeader.Parent = rightPanel

local slotsContainer = Instance.new("Frame")
slotsContainer.Name = "SlotsContainer"
slotsContainer.Size = UDim2.new(1, -20, 0, 212)
slotsContainer.Position = UDim2.fromOffset(10, 44)
slotsContainer.BackgroundTransparency = 1
slotsContainer.Parent = rightPanel

local slotsLayout = Instance.new("UIListLayout")
slotsLayout.Padding = UDim.new(0, 8)
slotsLayout.FillDirection = Enum.FillDirection.Vertical
slotsLayout.SortOrder = Enum.SortOrder.LayoutOrder
slotsLayout.Parent = slotsContainer

type SlotRow = {
	frame: Frame,
	stroke: UIStroke,
	titleLabel: TextLabel,
	subLabel: TextLabel,
}

local slotRows: { SlotRow } = {}
for i = 1, Config.MAX_PEDESTALS_PER_BASE do
	local row = Instance.new("Frame")
	row.Name = "Slot_" .. tostring(i)
	row.LayoutOrder = i
	row.Size = UDim2.new(1, 0, 0, 47)
	row.BackgroundColor3 = Color3.fromRGB(25, 30, 44)
	row.BorderSizePixel = 0
	row.Parent = slotsContainer

	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0, 8)
	rc.Parent = row

	local rs = Instance.new("UIStroke")
	rs.Color = Color3.fromRGB(65, 75, 95)
	rs.Thickness = 1.5
	rs.Parent = row

	local tLabel = Instance.new("TextLabel")
	tLabel.Name = "CharName"
	tLabel.Size = UDim2.new(1, -14, 0, 24)
	tLabel.Position = UDim2.fromOffset(8, 3)
	tLabel.BackgroundTransparency = 1
	tLabel.Font = Enum.Font.GothamBold
	tLabel.TextColor3 = Color3.fromRGB(160, 170, 190)
	tLabel.TextXAlignment = Enum.TextXAlignment.Left
	tLabel.TextScaled = true
	tLabel.Text = string.format("Pedestal #%d — Empty", i)
	tLabel.Parent = row

	local sLabel = Instance.new("TextLabel")
	sLabel.Name = "CharDetails"
	sLabel.Size = UDim2.new(1, -14, 0, 18)
	sLabel.Position = UDim2.fromOffset(8, 26)
	sLabel.BackgroundTransparency = 1
	sLabel.Font = Enum.Font.GothamMedium
	sLabel.TextColor3 = Color3.fromRGB(125, 135, 155)
	sLabel.TextXAlignment = Enum.TextXAlignment.Left
	sLabel.TextScaled = true
	sLabel.Text = "Buy a Brainrot at the center conveyor!"
	sLabel.Parent = row

	table.insert(slotRows, {
		frame = row,
		stroke = rs,
		titleLabel = tLabel,
		subLabel = sLabel,
	})
end

-- Base Lock Button ($500, 60s duration, 120s cooldown)
local baseLockButton = Instance.new("TextButton")
baseLockButton.Name = "BaseLockButton"
baseLockButton.Size = UDim2.new(1, -20, 0, 52)
baseLockButton.Position = UDim2.fromOffset(10, 266)
baseLockButton.BackgroundColor3 = Color3.fromRGB(30, 150, 225)
baseLockButton.Font = Enum.Font.GothamBlack
baseLockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
baseLockButton.TextScaled = true
baseLockButton.Text = string.format("BASE LOCK ($%d)\nBlocks Maling Siluman for %ds", Config.BASE_LOCK_COST, Config.BASE_LOCK_DURATION)
baseLockButton.Parent = rightPanel

local lockCorner = Instance.new("UICorner")
lockCorner.CornerRadius = UDim.new(0, 8)
lockCorner.Parent = baseLockButton

baseLockButton.Activated:Connect(function()
	RequestBaseLockRemote:FireServer()
end)

-- Rebirth Button ($25,000 x (rebirths+1), +0.5x permanent income multiplier)
local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "RebirthButton"
rebirthButton.Size = UDim2.new(1, -20, 0, 52)
rebirthButton.Position = UDim2.fromOffset(10, 326)
rebirthButton.BackgroundColor3 = Color3.fromRGB(215, 135, 25)
rebirthButton.Font = Enum.Font.GothamBlack
rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthButton.TextScaled = true
rebirthButton.Text = "REBIRTH ($25,000)\n+0.5x Permanent Income Multiplier"
rebirthButton.Parent = rightPanel

local rebirthCorner = Instance.new("UICorner")
rebirthCorner.CornerRadius = UDim.new(0, 8)
rebirthCorner.Parent = rebirthButton

rebirthButton.Activated:Connect(function()
	RequestRebirthRemote:FireServer()
end)

--------------------------------------------------------------------------------
-- 3. Toast Notifications Container (Bottom-Center)
--------------------------------------------------------------------------------
local toastContainer = Instance.new("Frame")
toastContainer.Name = "ToastContainer"
toastContainer.AnchorPoint = Vector2.new(0.5, 1)
toastContainer.Position = UDim2.new(0.5, 0, 1, -22)
toastContainer.Size = UDim2.fromOffset(500, 160)
toastContainer.BackgroundTransparency = 1
toastContainer.Parent = screenGui

local toastLayout = Instance.new("UIListLayout")
toastLayout.FillDirection = Enum.FillDirection.Vertical
toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
toastLayout.Padding = UDim.new(0, 6)
toastLayout.Parent = toastContainer

local function showToast(message: string, color: Color3?)
	local toastColor = color or Color3.fromRGB(255, 230, 110)

	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 36)
	card.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
	card.BackgroundTransparency = 0.08
	card.BorderSizePixel = 0
	card.Parent = toastContainer

	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 8)
	cc.Parent = card

	local cs = Instance.new("UIStroke")
	cs.Color = toastColor
	cs.Thickness = 2
	cs.Parent = card

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -16, 1, -6)
	label.Position = UDim2.fromOffset(8, 3)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = toastColor
	label.TextScaled = true
	label.Text = message
	label.Parent = card

	task.delay(4.0, function()
		if card.Parent then
			local tween = TweenService:Create(card, TweenInfo.new(0.35), { BackgroundTransparency = 1 })
			local textTween = TweenService:Create(label, TweenInfo.new(0.35), { TextTransparency = 1 })
			tween:Play()
			textTween:Play()
			tween.Completed:Wait()
			card:Destroy()
		end
	end)
end

--------------------------------------------------------------------------------
-- 4. State Updates & ProximityPrompt Feedback
--------------------------------------------------------------------------------
local mutationColors: { [string]: Color3 } = {
	Golden = Color3.fromRGB(255, 215, 45),
	Neon = Color3.fromRGB(0, 255, 230),
	Rainbow = Color3.fromRGB(255, 110, 235),
}

StateUpdateRemote.OnClientEvent:Connect(function(state: { [string]: any })
	local cash = state.cash or 0
	local income = state.incomePerSecond or 0
	local rebirths = state.rebirths or 0
	local rebirthMult = state.rebirthMultiplier or 1
	local rebirthCost = state.rebirthCost or Config.REBIRTH_BASE_COST
	local lockRem = state.lockRemaining or 0
	local lockCd = state.lockCooldownRemaining or 0
	local chars = state.characters or {}

	cashLabel.Text = string.format("%s  (+%s/s)", formatMoney(cash), formatMoney(income))
	multiplierLabel.Text = string.format("Rebirths: %d (%.1fx)", rebirths, rebirthMult)
	invHeader.Text = string.format("BASE #%s PEDESTALS (%d/%d)", tostring(state.plotIndex or 1), #chars, Config.MAX_PEDESTALS_PER_BASE)

	-- Reset all 4 slot rows first
	for i = 1, Config.MAX_PEDESTALS_PER_BASE do
		local row = slotRows[i]
		row.stroke.Color = Color3.fromRGB(65, 75, 95)
		row.titleLabel.TextColor3 = Color3.fromRGB(145, 155, 175)
		row.titleLabel.Text = string.format("Pedestal #%d — Empty", i)
		row.subLabel.TextColor3 = Color3.fromRGB(115, 125, 145)
		row.subLabel.Text = "Buy a Brainrot at the center conveyor!"
	end

	-- Populate placed characters
	for _, c in ipairs(chars) do
		local slotIdx = c.slotIndex or 1
		local row = slotRows[slotIdx]
		if row then
			local rColor = Config.RARITY_COLORS[c.rarity] or Color3.fromRGB(220, 220, 220)
			row.stroke.Color = rColor
			row.titleLabel.TextColor3 = rColor
			row.titleLabel.Text = string.format("#%d %s [%s]", slotIdx, c.name, c.rarity)

			if c.mutation and c.mutation ~= "None" then
				row.subLabel.TextColor3 = mutationColors[c.mutation] or Color3.fromRGB(255, 225, 100)
				row.subLabel.Text = string.format("★ %s (x%d)  •  +%s/s", c.mutation, c.mutationMultiplier or 1, formatMoney(c.effectiveIncome))
			else
				row.subLabel.TextColor3 = Color3.fromRGB(160, 245, 185)
				row.subLabel.Text = string.format("Standard  •  +%s/s", formatMoney(c.effectiveIncome))
			end
		end
	end

	-- Base Lock Button status
	if lockRem > 0 then
		baseLockButton.BackgroundColor3 = Color3.fromRGB(45, 195, 120)
		baseLockButton.Text = string.format("BASE LOCK ACTIVE (%ds)\nProtected from %s", lockRem, Config.THIEF_NAME)
	elseif lockCd > 0 then
		baseLockButton.BackgroundColor3 = Color3.fromRGB(75, 82, 100)
		baseLockButton.Text = string.format("BASE LOCK COOLDOWN (%ds)\nCost: $%d", lockCd, Config.BASE_LOCK_COST)
	else
		baseLockButton.BackgroundColor3 = Color3.fromRGB(30, 150, 225)
		baseLockButton.Text = string.format("BUY BASE LOCK ($%d)\nBlocks %s for %ds", Config.BASE_LOCK_COST, Config.THIEF_NAME, Config.BASE_LOCK_DURATION)
	end

	-- Rebirth Button status
	local nextMult = Config.getRebirthMultiplier(rebirths + 1)
	if cash >= rebirthCost then
		rebirthButton.BackgroundColor3 = Color3.fromRGB(245, 165, 30)
	else
		rebirthButton.BackgroundColor3 = Color3.fromRGB(130, 90, 35)
	end
	rebirthButton.Text = string.format("REBIRTH (%s)\nReset for %.1fx Permanent Multiplier", formatMoney(rebirthCost), nextMult)
end)

ConveyorUpdateRemote.OnClientEvent:Connect(function(info: { [string]: any })
	local rColor = Config.RARITY_COLORS[info.rarity] or Color3.fromRGB(220, 225, 255)
	conveyorStatusLabel.TextColor3 = rColor
	conveyorStatusLabel.Text = string.format(
		"Podium: %s [%s] • %s (+%s/s) [%ds]",
		info.name,
		info.rarity,
		formatMoney(info.price),
		formatMoney(info.income),
		info.secondsRemaining or 0
	)
end)

ToastRemote.OnClientEvent:Connect(function(message: string, color: Color3?)
	showToast(message, color)
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, triggeredPlayer: Player)
	if triggeredPlayer == player and prompt.Name == "BuyBrainrotPrompt" then
		quickBuyButton.Text = "Buying..."
		task.delay(0.4, function()
			if quickBuyButton.Parent then
				quickBuyButton.Text = "Buy Podium"
			end
		end)
	end
end)

--------------------------------------------------------------------------------
-- 5. Brainrot Cast Index & Game Rules Modal (Bottom-Left Toggle Button)
--------------------------------------------------------------------------------
local indexToggleBtn = Instance.new("TextButton")
indexToggleBtn.Name = "CastIndexButton"
indexToggleBtn.AnchorPoint = Vector2.new(0, 1)
indexToggleBtn.Position = UDim2.new(0, 16, 1, -22)
indexToggleBtn.Size = UDim2.fromOffset(195, 44)
indexToggleBtn.BackgroundColor3 = Color3.fromRGB(28, 34, 52)
indexToggleBtn.Font = Enum.Font.GothamBlack
indexToggleBtn.TextColor3 = Color3.fromRGB(255, 220, 95)
indexToggleBtn.TextScaled = true
indexToggleBtn.Text = "BRAINROT INDEX (14)"
indexToggleBtn.Parent = screenGui

local idxBtnCorner = Instance.new("UICorner")
idxBtnCorner.CornerRadius = UDim.new(0, 10)
idxBtnCorner.Parent = indexToggleBtn

local idxBtnStroke = Instance.new("UIStroke")
idxBtnStroke.Color = Color3.fromRGB(255, 215, 70)
idxBtnStroke.Thickness = 2
idxBtnStroke.Parent = indexToggleBtn

local indexModal = Instance.new("Frame")
indexModal.Name = "CastIndexModal"
indexModal.AnchorPoint = Vector2.new(0.5, 0.5)
indexModal.Position = UDim2.new(0.5, -80, 0.52, 0)
indexModal.Size = UDim2.fromOffset(520, 380)
indexModal.BackgroundColor3 = Color3.fromRGB(14, 18, 28)
indexModal.BackgroundTransparency = 0.04
indexModal.BorderSizePixel = 0
indexModal.Visible = false
indexModal.Parent = screenGui

local modalCorner = Instance.new("UICorner")
modalCorner.CornerRadius = UDim.new(0, 14)
modalCorner.Parent = indexModal

local modalStroke = Instance.new("UIStroke")
modalStroke.Color = Color3.fromRGB(255, 215, 70)
modalStroke.Thickness = 2.5
modalStroke.Parent = indexModal

local modalTitle = Instance.new("TextLabel")
modalTitle.Size = UDim2.new(1, -24, 0, 36)
modalTitle.Position = UDim2.fromOffset(12, 8)
modalTitle.BackgroundTransparency = 1
modalTitle.Font = Enum.Font.GothamBlack
modalTitle.TextColor3 = Color3.fromRGB(255, 230, 110)
modalTitle.TextScaled = true
modalTitle.Text = "GLOWYARD BRAINROT LADDER & MUTATION ODDS"
modalTitle.Parent = indexModal

local modalSubtitle = Instance.new("TextLabel")
modalSubtitle.Size = UDim2.new(1, -24, 0, 22)
modalSubtitle.Position = UDim2.fromOffset(12, 44)
modalSubtitle.BackgroundTransparency = 1
modalSubtitle.Font = Enum.Font.GothamBold
modalSubtitle.TextColor3 = Color3.fromRGB(190, 220, 255)
modalSubtitle.TextScaled = true
modalSubtitle.Text = "Mutations: 8% Golden (x2) • 3% Neon (x3) • 1% Rainbow (x5) | Thief: Maling Siluman (10s Touch Recovery)"
modalSubtitle.Parent = indexModal

local listScroll = Instance.new("ScrollingFrame")
listScroll.Size = UDim2.new(1, -24, 1, -82)
listScroll.Position = UDim2.fromOffset(12, 72)
listScroll.BackgroundTransparency = 1
listScroll.BorderSizePixel = 0
listScroll.ScrollBarThickness = 6
listScroll.CanvasSize = UDim2.fromOffset(0, #Config.CHARACTERS * 54)
listScroll.Parent = indexModal

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listScroll

for idx, cdef in ipairs(Config.CHARACTERS) do
	local item = Instance.new("TextButton")
	item.LayoutOrder = idx
	item.Size = UDim2.new(1, -10, 0, 48)
	item.BackgroundColor3 = Color3.fromRGB(22, 27, 40)
	item.BorderSizePixel = 0
	item.Text = ""
	item.AutoButtonColor = true
	item.Parent = listScroll

	local ic = Instance.new("UICorner")
	ic.CornerRadius = UDim.new(0, 8)
	ic.Parent = item

	local is = Instance.new("UIStroke")
	is.Color = Config.RARITY_COLORS[cdef.rarity] or Color3.fromRGB(160, 160, 160)
	is.Thickness = 1.5
	is.Parent = item

	local nameLine = Instance.new("TextLabel")
	nameLine.Size = UDim2.new(1, -16, 0, 24)
	nameLine.Position = UDim2.fromOffset(8, 2)
	nameLine.BackgroundTransparency = 1
	nameLine.Font = Enum.Font.GothamBold
	nameLine.TextColor3 = Config.RARITY_COLORS[cdef.rarity] or Color3.fromRGB(255, 255, 255)
	nameLine.TextXAlignment = Enum.TextXAlignment.Left
	nameLine.TextScaled = true
	nameLine.Text = string.format("%d. %s [%s] — Price: %s • Income: +%s/s", idx, cdef.name, cdef.rarity, formatMoney(cdef.price), formatMoney(cdef.income))
	nameLine.Parent = item

	local loreLine = Instance.new("TextLabel")
	loreLine.Size = UDim2.new(1, -16, 0, 18)
	loreLine.Position = UDim2.fromOffset(8, 26)
	loreLine.BackgroundTransparency = 1
	loreLine.Font = Enum.Font.GothamMedium
	loreLine.TextColor3 = Color3.fromRGB(175, 185, 210)
	loreLine.TextXAlignment = Enum.TextXAlignment.Left
	loreLine.TextScaled = true
	local archive = Config.COLLECTOR_ARCHIVES and Config.COLLECTOR_ARCHIVES[cdef.name]
	local originText = if archive then (" [" .. archive.originZone .. "]") else ""
	loreLine.Text = (cdef.tagline or "") .. originText
	loreLine.Parent = item

	item.Activated:Connect(function()
		local rCol = Config.RARITY_COLORS[cdef.rarity] or Color3.fromRGB(255, 230, 120)
		local gInc = cdef.income * 2
		local nInc = cdef.income * 3
		local rbInc = cdef.income * 5
		showToast(
			string.format(
				"%s [%s]: Base +%s/s | Golden +%s/s | Neon +%s/s | Rainbow +%s/s",
				cdef.name,
				cdef.rarity,
				formatMoney(cdef.income),
				formatMoney(gInc),
				formatMoney(nInc),
				formatMoney(rbInc)
			),
			rCol
		)
	end)
end

-- Detail Inspection Footer inside the Cast Index Modal
local modalFooter = Instance.new("TextLabel")
modalFooter.Name = "ModalFooter"
modalFooter.Size = UDim2.new(1, -24, 0, 20)
modalFooter.Position = UDim2.new(0, 12, 1, -22)
modalFooter.BackgroundTransparency = 1
modalFooter.Font = Enum.Font.GothamMedium
modalFooter.TextColor3 = Color3.fromRGB(150, 235, 190)
modalFooter.TextScaled = true
modalFooter.Text = "Click any character entry above to preview its Golden (x2), Neon (x3), and Rainbow (x5) incomes!"
modalFooter.Parent = indexModal

-- Keyboard Shortcuts: [I] toggles Brainrot Index, [L] triggers Base Lock, [R] triggers Rebirth
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.I then
		indexModal.Visible = not indexModal.Visible
	elseif input.KeyCode == Enum.KeyCode.L then
		RequestBaseLockRemote:FireServer()
	elseif input.KeyCode == Enum.KeyCode.R then
		RequestRebirthRemote:FireServer()
	end
end)

indexToggleBtn.Activated:Connect(function()
	indexModal.Visible = not indexModal.Visible
end)

--------------------------------------------------------------------------------
-- 6. Threat & Mutation Quick-Reference Tooltip Strip (Bottom-Center above Toasts)
--------------------------------------------------------------------------------
local rulesStrip = Instance.new("Frame")
rulesStrip.Name = "RulesHintStrip"
rulesStrip.AnchorPoint = Vector2.new(0.5, 1)
rulesStrip.Position = UDim2.new(0.5, 0, 1, -4)
rulesStrip.Size = UDim2.fromOffset(560, 20)
rulesStrip.BackgroundColor3 = Color3.fromRGB(14, 18, 26)
rulesStrip.BackgroundTransparency = 0.25
rulesStrip.BorderSizePixel = 0
rulesStrip.Parent = screenGui

local rsCorner = Instance.new("UICorner")
rsCorner.CornerRadius = UDim.new(0, 6)
rsCorner.Parent = rulesStrip

local rulesLabel = Instance.new("TextLabel")
rulesLabel.Size = UDim2.new(1, -12, 1, -2)
rulesLabel.Position = UDim2.fromOffset(6, 1)
rulesLabel.BackgroundTransparency = 1
rulesLabel.Font = Enum.Font.GothamMedium
rulesLabel.TextColor3 = Color3.fromRGB(185, 198, 225)
rulesLabel.TextScaled = true
rulesLabel.Text = "TIP: Press E at Center Podium to Buy • Touch Maling Siluman within 10s if he steals • Lock Base ($500) for 60s shield"
rulesLabel.Parent = rulesStrip

--------------------------------------------------------------------------------
-- 7. Live Conveyor Mutation Preview & Next-Rebirth Progression Tracker
--------------------------------------------------------------------------------
local mutationOddsBar = Instance.new("Frame")
mutationOddsBar.Name = "MutationOddsBar"
mutationOddsBar.AnchorPoint = Vector2.new(0.5, 0)
mutationOddsBar.Position = UDim2.new(0.5, 0, 0, 100)
mutationOddsBar.Size = UDim2.fromOffset(460, 24)
mutationOddsBar.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
mutationOddsBar.BackgroundTransparency = 0.18
mutationOddsBar.BorderSizePixel = 0
mutationOddsBar.Parent = screenGui

local mobCorner = Instance.new("UICorner")
mobCorner.CornerRadius = UDim.new(0, 6)
mobCorner.Parent = mutationOddsBar

local mobStroke = Instance.new("UIStroke")
mobStroke.Color = Color3.fromRGB(255, 215, 65)
mobStroke.Thickness = 1.2
mobStroke.Parent = mutationOddsBar

local mobLabel = Instance.new("TextLabel")
mobLabel.Name = "OddsText"
mobLabel.Size = UDim2.new(1, -12, 1, -2)
mobLabel.Position = UDim2.fromOffset(6, 1)
mobLabel.BackgroundTransparency = 1
mobLabel.Font = Enum.Font.GothamBold
mobLabel.TextColor3 = Color3.fromRGB(255, 230, 130)
mobLabel.TextScaled = true
mobLabel.Text = "Roll Odds on Purchase: Golden 8% (x2 $/s) • Neon 3% (x3 $/s) • Rainbow 1% (x5 $/s)"
mobLabel.Parent = mutationOddsBar

-- Update the top odds bar whenever the conveyor showcase rotates so players can see exact potential mutated incomes
ConveyorUpdateRemote.OnClientEvent:Connect(function(info: { [string]: any })
	local baseInc = tonumber(info.income) or 1
	mobLabel.Text = string.format(
		"If Mutated: Golden (8%%) +%s/s • Neon (3%%) +%s/s • Rainbow (1%%) +%s/s",
		formatMoney(baseInc * 2),
		formatMoney(baseInc * 3),
		formatMoney(baseInc * 5)
	)
end)

--------------------------------------------------------------------------------
-- 8. How-To-Play & Thief Defense Guide Overlay (Toggleable via [H] or Button)
--------------------------------------------------------------------------------
local guideToggleBtn = Instance.new("TextButton")
guideToggleBtn.Name = "GuideToggleButton"
guideToggleBtn.AnchorPoint = Vector2.new(0, 1)
guideToggleBtn.Position = UDim2.new(0, 220, 1, -22)
guideToggleBtn.Size = UDim2.fromOffset(165, 44)
guideToggleBtn.BackgroundColor3 = Color3.fromRGB(28, 42, 58)
guideToggleBtn.Font = Enum.Font.GothamBlack
guideToggleBtn.TextColor3 = Color3.fromRGB(110, 235, 255)
guideToggleBtn.TextScaled = true
guideToggleBtn.Text = "HOW TO PLAY [H]"
guideToggleBtn.Parent = screenGui

local gBtnCorner = Instance.new("UICorner")
gBtnCorner.CornerRadius = UDim.new(0, 10)
gBtnCorner.Parent = guideToggleBtn

local gBtnStroke = Instance.new("UIStroke")
gBtnStroke.Color = Color3.fromRGB(0, 225, 255)
gBtnStroke.Thickness = 2
gBtnStroke.Parent = guideToggleBtn

local guideCard = Instance.new("Frame")
guideCard.Name = "HowToPlayModal"
guideCard.AnchorPoint = Vector2.new(0, 1)
guideCard.Position = UDim2.new(0, 16, 1, -76)
guideCard.Size = UDim2.fromOffset(370, 220)
guideCard.BackgroundColor3 = Color3.fromRGB(14, 18, 28)
guideCard.BackgroundTransparency = 0.06
guideCard.BorderSizePixel = 0
guideCard.Visible = false
guideCard.Parent = screenGui

local gcCorner = Instance.new("UICorner")
gcCorner.CornerRadius = UDim.new(0, 12)
gcCorner.Parent = guideCard

local gcStroke = Instance.new("UIStroke")
gcStroke.Color = Color3.fromRGB(0, 225, 255)
gcStroke.Thickness = 2
gcStroke.Parent = guideCard

local guideText = Instance.new("TextLabel")
guideText.Size = UDim2.new(1, -20, 1, -16)
guideText.Position = UDim2.fromOffset(10, 8)
guideText.BackgroundTransparency = 1
guideText.Font = Enum.Font.GothamMedium
guideText.TextColor3 = Color3.fromRGB(220, 232, 255)
guideText.TextXAlignment = Enum.TextXAlignment.Left
guideText.TextYAlignment = Enum.TextYAlignment.Top
guideText.TextScaled = true
guideText.Text = table.concat({
	"GLOWYARD: STEAL THE BRAINROTS — RULES",
	"1. CONVEYOR SHOP: Walk to the center podium & press [E] (or click Buy Podium) to purchase the showcased Brainrot.",
	"2. BASE INCOME: Up to 4 pedestals per base earn cash every second. Buying when full upgrades your lowest-earning slot!",
	"3. MUTATIONS: Every purchase rolls 8% Golden (x2), 3% Neon (x3), or 1% Rainbow (x5) income!",
	"4. THIEF DEFENSE: Maling Siluman spawns every 75-120s to steal your highest earner. Touch him within 10s to recover it, or buy a Base Lock ($500) for a 60s shield (120s cooldown)!",
	"5. REBIRTH: Costs $25,000 x (rebirths+1). Resets cash & pedestals for a permanent +0.5x income multiplier!",
}, "\n\n")
guideText.Parent = guideCard

guideToggleBtn.Activated:Connect(function()
	guideCard.Visible = not guideCard.Visible
end)

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.H then
		guideCard.Visible = not guideCard.Visible
	end
end)
