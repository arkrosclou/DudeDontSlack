--[[ Dude, Don't Slack! - a big icon when a raid mechanic lands on you (WoW 3.3.5a)

	The list holds spell ids. Each id is turned into its localized name, and
	your buffs and debuffs are matched by that name: one id covers the 10/25/
	heroic variants of a mechanic, which all share it, and the addon works on
	any client language. ]]

DudeDontSlack = {}
local DDS = DudeDontSlack

DDS.defaults = {
	point = { "CENTER", "CENTER", 0, 180 },
	locked = false,
	raidOnly = true,
	iconSize = 80,
	-- [spell id] = true. Ids taken from the DBM modules: the debuffs they
	-- announce on the player.
	auras = {
		-- Trial of the Crusader
		[66823] = true, -- Paralytic Toxin (Acidmaw)
		[66869] = true, -- Burning Bile (Dreadscale)
		[66237] = true, -- Incinerate Flesh (Jaraxxus)
		[66197] = true, -- Legion Flame (Jaraxxus)
		[66334] = true, -- Mistress' Kiss (Jaraxxus)
		[65950] = true, -- Touch of Light (Twin Val'kyr)
		[66001] = true, -- Touch of Darkness (Twin Val'kyr)
		[66013] = true, -- Penetrating Cold (Anub'arak)
		[67574] = true, -- Pursued by Anub'arak
		-- Icecrown Citadel
		[69146] = true, -- Coldflame, standing in it (Marrowgar)
		[71001] = true, -- Death and Decay, standing in it (Deathwhisper)
		[71237] = true, -- Curse of Torpor (Deathwhisper)
		[72293] = true, -- Mark of the Fallen Champion (Saurfang)
		[69279] = true, -- Gas Spore (Festergut)
		[69240] = true, -- Vile Gas (Festergut)
		[69674] = true, -- Mutated Infection (Rotface)
		[70447] = true, -- Volatile Ooze Adhesive (Putricide)
		[70672] = true, -- Gaseous Bloat (Putricide)
		[70911] = true, -- Unbound Plague (Putricide, heroic)
		[71340] = true, -- Pact of the Darkfallen, the chain (Blood-Queen)
		[71266] = true, -- Swarming Shadows (Blood-Queen)
		[70877] = true, -- Frenzied Bloodthirst (Blood-Queen)
		[70126] = true, -- Frost Beacon (Sindragosa)
		[69762] = true, -- Unchained Magic (Sindragosa)
		[70337] = true, -- Necrotic Plague (Lich King)
		[72754] = true, -- Defile, standing in it (Lich King)
		[68980] = true, -- Harvest Soul (Lich King)
		[69200] = true, -- Raging Spirit (Lich King)
		-- Ruby Sanctum
		[74505] = true, -- Enervating Brand (Baltharus)
		[74453] = true, -- Flame Beacon (Saviana)
		[74562] = true, -- Fiery Combustion (Halion)
		[74792] = true, -- Soul Consumption (Halion)
		-- Ulduar
		[65121] = true, -- Searing Light (XT-002)
		[64234] = true, -- Gravity Bomb (XT-002)
		[63276] = true, -- Mark of the Faceless (Vezax)
		[63802] = true, -- Brain Link (Yogg-Saron)
		[63830] = true, -- Malady of the Mind (Yogg-Saron)
	},
}

DDS.names = {} -- localized aura name -> true, built from db.auras

-- ---------------------------------------------------------------------------
-- rainbow text
-- ---------------------------------------------------------------------------
local function hueToRGB(h)
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local q = 1 - f
	i = i % 6
	if i == 0 then return 1, f, 0
	elseif i == 1 then return q, 1, 0
	elseif i == 2 then return 0, 1, f
	elseif i == 3 then return 0, q, 1
	elseif i == 4 then return f, 0, 1
	end
	return 1, 0, q
end

-- red to violet across the letters; spaces take no colour
function DDS.Rainbow(text)
	local letters = select(2, string.gsub(text, "%S", ""))
	local out, k = {}, 0
	for i = 1, #text do
		local c = string.sub(text, i, i)
		if c == " " then
			out[#out + 1] = c
		else
			local r, g, b = hueToRGB(0.83 * k / math.max(letters - 1, 1))
			k = k + 1
			out[#out + 1] = string.format("|cff%02x%02x%02x%s",
				math.floor(r * 255), math.floor(g * 255), math.floor(b * 255), c)
		end
	end
	return table.concat(out) .. "|r"
end

DDS.TITLE = DDS.Rainbow("Dude, Don't Slack!")

function DDS:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage(self.TITLE .. ": " .. tostring(msg))
end

-- ---------------------------------------------------------------------------
-- auras
-- ---------------------------------------------------------------------------
-- an id the client does not know simply resolves to nothing
function DDS:RebuildNames()
	wipe(self.names)
	for id in pairs(self.db.auras) do
		local name = GetSpellInfo(id)
		if name then self.names[name] = true end
	end
	if self.UpdateDisplay then self:UpdateDisplay() end
end

-- Every watched aura on the player, buffs and debuffs, in the order the client
-- lists them. Returned table is reused.
local FILTERS = { "HARMFUL", "HELPFUL" }
local active = {}

function DDS:ScanAuras()
	local n = 0
	if not next(self.names) then
		for i = 1, #active do active[i] = nil end
		return active
	end
	for _, filter in ipairs(FILTERS) do
		local i = 1
		while true do
			local name, _, icon, count, _, duration, expires = UnitAura("player", i, filter)
			if not name then break end
			if self.names[name] then
				n = n + 1
				local a = active[n] or {}
				a.icon, a.count, a.duration, a.expires = icon, count, duration, expires
				active[n] = a
			end
			i = i + 1
		end
	end
	for i = n + 1, #active do active[i] = nil end
	return active
end

-- ---------------------------------------------------------------------------
-- init
-- ---------------------------------------------------------------------------
local function copy(v)
	if type(v) ~= "table" then return v end
	local t = {}
	for k, x in pairs(v) do t[k] = copy(x) end
	return t
end

function DDS:Init()
	DudeDontSlackDB = DudeDontSlackDB or {}
	for k, v in pairs(self.defaults) do
		if DudeDontSlackDB[k] == nil then DudeDontSlackDB[k] = copy(v) end
	end
	self.db = DudeDontSlackDB
	self:CreateDisplay()
	self:RebuildNames()
	self:InitConfig()
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("ADDON_LOADED")
driver:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 ~= "DudeDontSlack" then return end
		self:UnregisterEvent("ADDON_LOADED")
		DDS:Init()
		self:RegisterEvent("UNIT_AURA")
		self:RegisterEvent("PLAYER_ENTERING_WORLD")
		self:RegisterEvent("RAID_ROSTER_UPDATE")
	elseif event == "UNIT_AURA" then
		if arg1 == "player" then DDS:UpdateDisplay() end
	else
		DDS:UpdateDisplay()
	end
end)
