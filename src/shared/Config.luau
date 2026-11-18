-- Shared Game Configuration for Glowyard: Steal the Brainrots

local Config = {}

Config.ECONOMY_TICK_RATE = 1 -- seconds per tick
Config.STARTING_CASH = 15

Config.REBIRTH_BASE_COST = 25000
Config.REBIRTH_MULTIPLIER_BONUS = 0.5

Config.BASE_LOCK_COST = 500
Config.BASE_LOCK_DURATION = 60
Config.BASE_LOCK_COOLDOWN = 120

Config.THIEF_NAME = "Maling Siluman"
Config.THIEF_SPAWN_MIN = 75
Config.THIEF_SPAWN_MAX = 120
Config.THIEF_DROP_WINDOW = 10

Config.CONVEYOR_ROTATE_INTERVAL = 7
Config.MAX_PEDESTALS_PER_BASE = 4

Config.RARITY_ORDER = {
	"Common",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
	"Secret",
}

Config.RARITY_COLORS = {
	Common = Color3.fromRGB(165, 170, 180), -- grey
	Rare = Color3.fromRGB(65, 145, 255), -- blue
	Epic = Color3.fromRGB(175, 75, 255), -- purple
	Legendary = Color3.fromRGB(255, 145, 35), -- orange
	Mythic = Color3.fromRGB(255, 50, 65), -- red
	Secret = Color3.fromRGB(255, 215, 50), -- black-gold highlight
}

Config.RARITY_SECONDARY_COLORS = {
	Common = Color3.fromRGB(100, 105, 115),
	Rare = Color3.fromRGB(30, 80, 170),
	Epic = Color3.fromRGB(100, 35, 165),
	Legendary = Color3.fromRGB(175, 80, 15),
	Mythic = Color3.fromRGB(160, 20, 30),
	Secret = Color3.fromRGB(20, 20, 25), -- black core for black-gold Secret rarity
}

Config.RARITY_WEIGHTS = {
	Common = 44,
	Rare = 25,
	Epic = 15,
	Legendary = 9,
	Mythic = 5,
	Secret = 2,
}

-- Mutations rolled on purchase: 8% Golden (x2), 3% Neon (x3), 1% Rainbow (x5)
Config.MUTATIONS = {
	{
		name = "Rainbow",
		chance = 0.01,
		multiplier = 5,
		color = Color3.fromRGB(255, 110, 235),
	},
	{
		name = "Neon",
		chance = 0.03,
		multiplier = 3,
		color = Color3.fromRGB(0, 255, 230),
	},
	{
		name = "Golden",
		chance = 0.08,
		multiplier = 2,
		color = Color3.fromRGB(255, 215, 45),
	},
}

-- 14 Original Characters across 6 rarities
-- Each entry defines unique visual geometry parameters, accessories, slogans, and lore
-- so every character on the conveyor podium and base pedestals looks distinct and memorable.
Config.CHARACTERS = {
	-- Common
	{
		id = "kucek_papera",
		name = "Kucek Papera",
		rarity = "Common",
		income = 1,
		price = 10,
		accentColor = Color3.fromRGB(220, 220, 210),
		secondaryAccent = Color3.fromRGB(175, 180, 170),
		eyeColor = Color3.fromRGB(255, 255, 210),
		headShape = "Ball",
		bodyScale = Vector3.new(2.4, 2.5, 1.9),
		headScale = Vector3.new(2.1, 2.1, 2.1),
		accessoryType = "PaperCrown",
		idleStyle = "Wobble",
		tagline = "Folded out of yesterday's laundry receipt!",
		lore = "A crumpled paper duckling who furiously rubs its eyes whenever someone mentions taxes. Generates steady pocket lint and crisp one-dollar bills.",
	},
	{
		id = "tahu_mercon",
		name = "Tahu Mercon",
		rarity = "Common",
		income = 2,
		price = 25,
		accentColor = Color3.fromRGB(245, 165, 85),
		secondaryAccent = Color3.fromRGB(225, 55, 35),
		eyeColor = Color3.fromRGB(255, 80, 30),
		headShape = "Block",
		bodyScale = Vector3.new(2.7, 2.6, 2.5),
		headScale = Vector3.new(2.3, 2.3, 2.3),
		accessoryType = "ChiliFuse",
		idleStyle = "Simmer",
		tagline = "Stuffed with 400 bird's-eye chilies and zero regret!",
		lore = "Deep-fried at 9,000 degrees in a roadside wok, this cubic firecracker tofu sizzles on its pedestal and pops spicy coins onto the floor every second.",
	},
	{
		id = "bola_kaki_jalan",
		name = "Bola Kaki Jalan",
		rarity = "Common",
		income = 3,
		price = 45,
		accentColor = Color3.fromRGB(235, 240, 250),
		secondaryAccent = Color3.fromRGB(35, 40, 50),
		eyeColor = Color3.fromRGB(80, 220, 255),
		headShape = "Ball",
		bodyScale = Vector3.new(2.6, 2.2, 2.6),
		headScale = Vector3.new(2.5, 2.5, 2.5),
		accessoryType = "SneakerCleats",
		idleStyle = "Bounce",
		tagline = "Kicked over the stadium fence in 2014 and kept walking!",
		lore = "A plastic street-soccer ball that sprouted oversized rubber cleats and refuses to stop dribbling itself around the neighborhood.",
	},
	-- Rare
	{
		id = "walet_bass",
		name = "Walet Bass",
		rarity = "Rare",
		income = 8,
		price = 120,
		accentColor = Color3.fromRGB(70, 160, 255),
		secondaryAccent = Color3.fromRGB(25, 55, 140),
		eyeColor = Color3.fromRGB(0, 245, 255),
		headShape = "Ball",
		bodyScale = Vector3.new(2.5, 2.9, 2.0),
		headScale = Vector3.new(2.1, 2.0, 2.2),
		accessoryType = "SubwooferWings",
		idleStyle = "Pulse",
		tagline = "180-decibel swiftlet nesting inside a dual subwoofer box!",
		lore = "Every chirp drops a 40Hz sub-bass shockwave that rattles neon lamp posts and shakes loose change out of passing clouds.",
	},
	{
		id = "kuda_pongkong",
		name = "Kuda Pongkong",
		rarity = "Rare",
		income = 10,
		price = 160,
		accentColor = Color3.fromRGB(110, 195, 255),
		secondaryAccent = Color3.fromRGB(50, 115, 210),
		eyeColor = Color3.fromRGB(170, 240, 255),
		headShape = "Block",
		bodyScale = Vector3.new(2.8, 3.0, 2.2),
		headScale = Vector3.new(2.0, 2.4, 2.5),
		accessoryType = "NeonMane",
		idleStyle = "GallopSquat",
		tagline = "Perpetually squatting stallion with hydraulic knees!",
		lore = "Refuses to trot like an ordinary horse; instead it hops in a low-rider squat stance while neighing synthesized eurobeat chords.",
	},
	-- Epic
	{
		id = "capybara_sultan",
		name = "Capybara Sultan",
		rarity = "Epic",
		income = 25,
		price = 420,
		accentColor = Color3.fromRGB(190, 110, 255),
		secondaryAccent = Color3.fromRGB(255, 200, 50),
		eyeColor = Color3.fromRGB(255, 235, 130),
		headShape = "Block",
		bodyScale = Vector3.new(3.1, 2.8, 2.6),
		headScale = Vector3.new(2.4, 2.1, 2.7),
		accessoryType = "SultanTurban",
		idleStyle = "RoyalFloat",
		tagline = "Unbothered. Moisturized. Balancing three golden tangerines.",
		lore = "Draped in velvet purple robes and a jewel-encrusted turban, this supreme rodent signs oil treaties in its sleep while dividends rain down.",
	},
	{
		id = "gurita_kasir",
		name = "Gurita Kasir",
		rarity = "Epic",
		income = 30,
		price = 540,
		accentColor = Color3.fromRGB(215, 90, 240),
		secondaryAccent = Color3.fromRGB(120, 35, 175),
		eyeColor = Color3.fromRGB(110, 255, 195),
		headShape = "Ball",
		bodyScale = Vector3.new(2.9, 2.7, 2.9),
		headScale = Vector3.new(2.6, 2.5, 2.6),
		accessoryType = "EightScanners",
		idleStyle = "RapidScan",
		tagline = "Eight tentacles, eight barcode lasers, zero pricing errors!",
		lore = "The undefeated minimarket octopus cashier who scans 600 snacks per minute and prints kilometer-long thermal receipts of pure profit.",
	},
	-- Legendary
	{
		id = "bapak_signal",
		name = "Bapak Signal",
		rarity = "Legendary",
		income = 60,
		price = 1200,
		accentColor = Color3.fromRGB(255, 165, 50),
		secondaryAccent = Color3.fromRGB(210, 85, 20),
		eyeColor = Color3.fromRGB(255, 240, 120),
		headShape = "Block",
		bodyScale = Vector3.new(2.7, 3.2, 2.1),
		headScale = Vector3.new(2.2, 2.2, 2.2),
		accessoryType = "SatelliteDish",
		idleStyle = "Broadcast",
		tagline = "Five bars of 9G reception anywhere in the multiverse!",
		lore = "Climbed onto the roof to adjust the TV antenna in 1998 and fused with a telecommunications satellite. Now beams high-frequency cash packets directly to your base.",
	},
	{
		id = "screwdriver_sultan",
		name = "Screwdriver Sultan",
		rarity = "Legendary",
		income = 75,
		price = 1600,
		accentColor = Color3.fromRGB(255, 130, 35),
		secondaryAccent = Color3.fromRGB(235, 200, 65),
		eyeColor = Color3.fromRGB(255, 195, 70),
		headShape = "Cylinder",
		bodyScale = Vector3.new(2.8, 3.3, 2.2),
		headScale = Vector3.new(2.2, 2.4, 2.2),
		accessoryType = "GoldenBitCrown",
		idleStyle = "TorqueSpin",
		tagline = "Righty-tighty into billionaire territory!",
		lore = "Wields a diamond-tipped flathead scepter capable of tightening loose bolts in the fabric of the economy, extracting $75 per revolution.",
	},
	-- Mythic
	{
		id = "buaya_bail",
		name = "Buaya Bail",
		rarity = "Mythic",
		income = 150,
		price = 3500,
		accentColor = Color3.fromRGB(255, 60, 80),
		secondaryAccent = Color3.fromRGB(165, 20, 40),
		eyeColor = Color3.fromRGB(255, 220, 60),
		headShape = "Block",
		bodyScale = Vector3.new(3.2, 3.1, 2.8),
		headScale = Vector3.new(2.4, 2.1, 3.2),
		accessoryType = "BriefcaseJaws",
		idleStyle = "SnapSwagger",
		tagline = "Objection overruled! Bail posted in solid ruby bars!",
		lore = "A crimson crocodile defense attorney in a double-breasted pinstripe vest who snaps shut every loophole and charges $150 a second in retainer fees.",
	},
	{
		id = "mira_matahari",
		name = "Mira Matahari",
		rarity = "Mythic",
		income = 180,
		price = 4500,
		accentColor = Color3.fromRGB(255, 95, 60),
		secondaryAccent = Color3.fromRGB(255, 205, 45),
		eyeColor = Color3.fromRGB(255, 255, 190),
		headShape = "Ball",
		bodyScale = Vector3.new(2.8, 3.4, 2.3),
		headScale = Vector3.new(2.5, 2.5, 2.5),
		accessoryType = "SolarHalo",
		idleStyle = "SolarFlare",
		tagline = "Wearing three pairs of sunglasses at midnight!",
		lore = "A walking solar eclipse wrapped in crimson-gold corona rings. Photosynthesis happens around her even indoors, Minting scorching banknotes out of thin air.",
	},
	-- Secret
	{
		id = "pak_de_fiber",
		name = "Pak De Fiber",
		rarity = "Secret",
		income = 400,
		price = 10000,
		accentColor = Color3.fromRGB(255, 215, 65),
		secondaryAccent = Color3.fromRGB(18, 18, 24),
		eyeColor = Color3.fromRGB(255, 230, 95),
		headShape = "Block",
		bodyScale = Vector3.new(3.1, 3.5, 2.4),
		headScale = Vector3.new(2.4, 2.4, 2.4),
		accessoryType = "FiberOpticCape",
		idleStyle = "LightSpeed",
		tagline = "Zero ping, infinite bandwidth, pure black-gold fiber!",
		lore = "The mystical uncle of the undersea backbone cable. Threads glowing golden glass filaments across the yard that pump $400/s at the speed of light.",
	},
	{
		id = "ratu_reverse",
		name = "Ratu Reverse",
		rarity = "Secret",
		income = 500,
		price = 13500,
		accentColor = Color3.fromRGB(255, 225, 90),
		secondaryAccent = Color3.fromRGB(15, 15, 22),
		eyeColor = Color3.fromRGB(255, 215, 50),
		headShape = "Ball",
		bodyScale = Vector3.new(3.0, 3.6, 2.5),
		headScale = Vector3.new(2.5, 2.5, 2.5),
		accessoryType = "ReverseHourglass",
		idleStyle = "TimeRewind",
		tagline = "Spends money backwards so her wallet only gets heavier!",
		lore = "Empress of the Inverted Clock. Whenever expenses try to leave her treasury, she flips a golden UNO-reverse sigil and turns debt into $500/s tribute.",
	},
	{
		id = "glimmerdeen",
		name = "GLIMMERDEEN",
		rarity = "Secret",
		income = 750,
		price = 20000,
		accentColor = Color3.fromRGB(255, 240, 120),
		secondaryAccent = Color3.fromRGB(10, 10, 16),
		eyeColor = Color3.fromRGB(255, 250, 185),
		headShape = "Ball",
		bodyScale = Vector3.new(3.4, 3.9, 2.8),
		headScale = Vector3.new(2.7, 2.7, 2.7),
		accessoryType = "CelestialObeliskCrown",
		idleStyle = "Ascendant",
		tagline = "THE APEX BRAINROT OF GLOWYARD — $750 PER SECOND!",
		lore = "An obsidian-and-sovereign-gold anomaly forged at the end of the conveyor belt. Radiates blinding wealth and commands the highest income in all of Glowyard.",
	},
}

Config.CHARACTER_BY_NAME = {}
Config.CHARACTER_BY_ID = {}
for _, char in ipairs(Config.CHARACTERS) do
	Config.CHARACTER_BY_NAME[char.name] = char
	Config.CHARACTER_BY_ID[char.id] = char
end

Config.RARITY_INDEX = {}
for idx, rName in ipairs(Config.RARITY_ORDER) do
	Config.RARITY_INDEX[rName] = idx
end

-- Detailed Lore & Collector Archives for each of the 14 Original Brainrots
-- Used by the client Brainrot Index encyclopedia and conveyor inspection panel
Config.COLLECTOR_ARCHIVES = {
	["Kucek Papera"] = {
		originZone = "Laundry Receipt Folding Basin",
		favoriteSnack = "Starch-soaked Origami Crumbs",
		signatureMove = "Double-Crease Eye Rub",
		collectorQuote = "Never iron a Kucek Papera while it's counting singles; the steam makes its paper feathers multiply.",
		defenseRating = "Flimsy against wind, steadfast on a neon pedestal.",
		fieldReport = "First spotted waddling out of an automatic receipt printer at 3:14 AM. When placed on a Glowyard base pedestal, it rhythmically folds tiny paper bills out of ambient humidity at a rate of $1 per second.",
	},
	["Tahu Mercon"] = {
		originZone = "Roadside Wok Crater #88",
		favoriteSnack = "Crushed Rawit Pepper Seeds & Boiling Cooking Oil",
		signatureMove = "Scoville Shrapnel Pop",
		collectorQuote = "Stand three studs back when Tahu Mercon sneezes or your eyebrows will smell like sambal for a week.",
		defenseRating = "Too spicy for ordinary pests, but Maling Siluman wears heatproof gloves.",
		fieldReport = "A golden-brown cube of deep-fried tofu packed to maximum capacity with blazing bird's-eye chilies. The internal pressure vents as a continuous $2/s stream of sizzling coins.",
	},
	["Bola Kaki Jalan"] = {
		originZone = "Asphalt Alleyway Goalpost",
		favoriteSnack = "Vulcanized Rubber Shoe Polish",
		signatureMove = "Self-Nutmeg Bicycle Kick",
		collectorQuote = "It doesn't wait for a striker—it calls its own fouls, blows its own whistle, and scores its own royalties.",
		defenseRating = "High bounce velocity; perpetually lacing up its cleats.",
		fieldReport = "After being booted over a rusty corrugated fence during an overtime neighborhood match, this street ball grew a pair of neon-trimmed cleats and began marching from yard to yard earning $3/s.",
	},
	["Walet Bass"] = {
		originZone = "Echo Cavern Soundstage Tower",
		favoriteSnack = "Sub-40Hz Sine Waves & Copper Voice Coils",
		signatureMove = "Twin-Ported Woofer Drop",
		collectorQuote = "You feel Walet Bass in your ribcage five seconds before you see its blue neon wings on the conveyor.",
		defenseRating = "Acoustic pressure wave keeps dust off the entire plot.",
		fieldReport = "A swiftlet that built its nest inside a custom dual-15-inch trunk subwoofer. Every wingbeat resonates at the exact frequency required to vibrate $8/s straight into its owner's vault.",
	},
	["Kuda Pongkong"] = {
		originZone = "Low-Rider Overpass Roundabout",
		favoriteSnack = "Synthetic Hydraulic Fluid & Sugar Cubes",
		signatureMove = "Perpetual Eurobeat Squat-Hop",
		collectorQuote = "Why gallop on four legs when you can bounce on two knees with neon suspension springs?",
		defenseRating = "Unshakeable center of gravity.",
		fieldReport = "An azure steed famous across Glowyard for never standing upright. Locked in a legendary deep-squat power stance, Kuda Pongkong pumps its hydraulic hocks to mint $10 every second.",
	},
	["Capybara Sultan"] = {
		originZone = "Velvet Hot-Spring Oasis Pavilion",
		favoriteSnack = "24-Karat Leafed Mandarin Oranges",
		signatureMove = "Sovereign Side-Eye Decree",
		collectorQuote = "Empires rise and fall, Maling Siluman prowls the shadows, yet Capybara Sultan remains completely unbothered.",
		defenseRating = "Radiates serene aristocratic aura.",
		fieldReport = "Crowned with a jeweled purple-and-gold turban, this ultra-composed rodent presides over a miniature sovereign wealth fund that distributes $25/s in royal stipends.",
	},
	["Gurita Kasir"] = {
		originZone = "24-Hour Neon Minimarket Checkout Lane 9",
		favoriteSnack = "Thermal Receipt Rolls & Iced Barcode Tea",
		signatureMove = "Octuple Laser Price-Check Barrage",
		collectorQuote = "Beep-beep-beep-beep! Eight items bagged, change counted, loyalty points applied in 0.04 seconds.",
		defenseRating = "Can wrap eight tentacles around a cash register simultaneously.",
		fieldReport = "Equipped with an infrared barcode scanner in every suction cup, Gurita Kasir processes imaginary midnight snack transactions at blinding speed, ringing up $30/s without ever taking a break.",
	},
	["Bapak Signal"] = {
		originZone = "Rooftop Bamboo Antenna Mast",
		favoriteSnack = "High-Gain Coaxial Static & Fried Banana Fritters",
		signatureMove = "Omnidirectional 9G Packet Beam",
		collectorQuote = "Raise the pole two inches left—wait, hold it right there! Full bars across all four base plots!",
		defenseRating = "Intercepts encrypted shadow transmissions from 200 studs away.",
		fieldReport = "Half neighborhood dad, half orbital parabolic transponder. Bapak Signal aligns his dorsal satellite dish toward the ionosphere and downloads $60/s in pure untraceable airtime credit.",
	},
	["Screwdriver Sultan"] = {
		originZone = "Imperial Hardware Citadel",
		favoriteSnack = " Magnetic Titanium Washers & Brass Threads",
		signatureMove = "Clockwise Sovereign Torque Spin",
		collectorQuote = "When the economy comes loose, only a diamond-cut flathead crown can torque it back into profit.",
		defenseRating = "Hardened chrome-vanadium exterior.",
		fieldReport = "Adorned in molten orange armor and a rotating golden driver bit crown, Screwdriver Sultan tightens invisible fiscal bolts every second to yield $75/s.",
	},
	["Buaya Bail"] = {
		originZone = "Crimson Mangrove Courthouse Steps",
		favoriteSnack = "Wax-Sealed Subpoenas & Ruby Cufflinks",
		signatureMove = "Habeas Corpus Jaw Snap",
		collectorQuote = "He doesn't just beat the charges—he invoices the courtroom for $150 a second while chewing on the gavel.",
		defenseRating = "Armored scales tailored into a bespoke double-breasted suit.",
		fieldReport = "A mythic crocodile barrister carrying a reinforced titanium briefcase in his jaws. Every snap of his snout settles another high-stakes arbitration for $150/s.",
	},
	["Mira Matahari"] = {
		originZone = "Zenith Corona Observatory",
		favoriteSnack = "Concentrated UV Photons & Chili Mango Slices",
		signatureMove = "Triple-Sunglasses Solar Flare",
		collectorQuote = "It's always high noon on whichever pedestal Mira Matahari stands on.",
		defenseRating = "Blindingly radiant corona ring.",
		fieldReport = "Surrounded by a levitating plasma halo that turns midnight into golden hour, Mira Matahari converts raw solar radiation into $180/s of scorching mythic revenue.",
	},
	["Pak De Fiber"] = {
		originZone = "Submarine Dark-Fiber Trench Junction",
		favoriteSnack = "Spliced Quartz Cores & Black-Gold Kopi Tubruk",
		signatureMove = "Zero-Latency Terabit Pulse",
		collectorQuote = "Copper wires are for amateurs; Pak De pumps pure golden photons straight into your bank balance.",
		defenseRating = "Cloaked in braided Kevlar and obsidian glass sheathing.",
		fieldReport = "A Secret-tier black-and-gold titan draped in a cape of glowing fiber-optic filaments. Routes intercontinental wealth packets through your base at $400/s.",
	},
	["Ratu Reverse"] = {
		originZone = "Inverted Clockwork Palace",
		favoriteSnack = "Counter-Clockwise Sand Grains & Gilded Mirrors",
		signatureMove = "Royal Uno-Paradox Flip",
		collectorQuote = "Try to bill Ratu Reverse and watch your own wallet pay her $500 a second in interest.",
		defenseRating = "Temporal distortion field around her obsidian-gold throne.",
		fieldReport = "Wielding a floating black-gold hourglass whose sand falls upward, Ratu Reverse inverts every economic law in Glowyard to pull $500/s out of yesterday and tomorrow simultaneously.",
	},
	["GLIMMERDEEN"] = {
		originZone = "The Singularity Vault Beneath the Conveyor",
		favoriteSnack = "Compressed Supernovas & Sovereign Bullion",
		signatureMove = "Celestial Obelisk Overdrive",
		collectorQuote = "When GLIMMERDEEN rolls onto the central podium, the entire yard holds its breath—and Maling Siluman starts sprinting.",
		defenseRating = "Maximum Secret-tier black-gold resonance. Lock your base immediately upon purchase!",
		fieldReport = "The undisputed apex Secret Brainrot of Glowyard. Sculpted from void-black obsidian and crowned with a levitating sovereign-gold obelisk, GLIMMERDEEN commands $750/s base income (up to $3,750/s with a Rainbow x5 mutation before Rebirths!).",
	},
}

function Config.getCharacterDetails(nameOrId: string): { [string]: any }?
	return Config.CHARACTER_BY_NAME[nameOrId] or Config.CHARACTER_BY_ID[nameOrId]
end

function Config.calculateEffectiveIncome(baseIncome: number, mutationMultiplier: number, rebirths: number): number
	local rMult = Config.getRebirthMultiplier(rebirths)
	return math.floor(baseIncome * mutationMultiplier * rMult + 0.5)
end

function Config.getRebirthCost(rebirths: number): number
	return Config.REBIRTH_BASE_COST * (rebirths + 1)
end

function Config.getRebirthMultiplier(rebirths: number): number
	return 1 + (rebirths * Config.REBIRTH_MULTIPLIER_BONUS)
end

function Config.rollMutation(rng: Random?): (string, number)
	local r = if rng then rng:NextNumber() else math.random()
	local cumulative = 0
	for _, mut in ipairs(Config.MUTATIONS) do
		cumulative += mut.chance
		if r <= cumulative then
			return mut.name, mut.multiplier
		end
	end
	return "None", 1
end

function Config.pickConveyorCharacter(rng: Random?): { [string]: any }
	local rand = rng or Random.new()
	local totalWeight = 0
	for _, char in ipairs(Config.CHARACTERS) do
		totalWeight += (Config.RARITY_WEIGHTS[char.rarity] or 1)
	end

	local pick = rand:NextNumber() * totalWeight
	local acc = 0
	for _, char in ipairs(Config.CHARACTERS) do
		acc += (Config.RARITY_WEIGHTS[char.rarity] or 1)
		if pick <= acc then
			return char
		end
	end
	return Config.CHARACTERS[1]
end

return Config
