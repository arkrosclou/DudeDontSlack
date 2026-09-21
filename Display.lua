--[[ Dude, Don't Slack! - the frame.

	One square icon per watched aura on you, left to right, with the duration
	spiral and the stack count. Nothing on you, nothing on screen.

	Unlocked, the frame always shows (a question mark stands in when there is
	no aura) so it can be dragged into place; right-click opens the options.
]]

local DDS = DudeDontSlack

local FLAT = "Interface\\Buttons\\WHITE8X8"
local FONT = "Fonts\\FRIZQT__.TTF"
local PLACEHOLDER = "Interface\\Icons\\INV_Misc_QuestionMark"
local GAP = 4

-- ---------------------------------------------------------------------------
-- icons
-- ---------------------------------------------------------------------------
local function createIcon(parent)
	local b = CreateFrame("Frame", nil, parent)
	-- 1px black edge around the icon
	b:SetBackdrop({ bgFile = FLAT })
	b:SetBackdropColor(0, 0, 0, 1)

	b.tex = b:CreateTexture(nil, "ARTWORK")
	b.tex:SetPoint("TOPLEFT", 1, -1)
	b.tex:SetPoint("BOTTOMRIGHT", -1, 1)
	b.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	b.cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
	b.cd:SetAllPoints(b.tex)
	b.cd:SetReverse(true)

	-- above the spiral
	local top = CreateFrame("Frame", nil, b)
	top:SetAllPoints()
	top:SetFrameLevel(b.cd:GetFrameLevel() + 1)
	b.count = top:CreateFontString(nil, "OVERLAY")
	b.count:SetPoint("BOTTOMRIGHT", -3, 3)
	-- Frost Beacon: the side DBM sent you to
	b.side = top:CreateFontString(nil, "OVERLAY")
	b.side:SetPoint("CENTER", 0, 0)
	b.side:SetTextColor(1, 0.82, 0)
	return b
end

-- DBM's own localized word, with chevrons toward the side
local function sideText(side)
	local L = DBM_COMMON_L
	local word = type(L) == "table" and L[side] or side
	word = string.upper(word or side)
	if side == "LEFT" then return "<< " .. word
	elseif side == "RIGHT" then return word .. " >>"
	end
	return ">> " .. word .. " <<"
end

-- The Frost Beacon icon is an arrow pointing down; turned a quarter it points
-- to the side DBM sent you to. Corners are given as upper-left, lower-left,
-- upper-right, lower-right, trimmed of the icon's own border.
local L0, L1 = 0.07, 0.93
local TURN = {
	-- clockwise: down becomes left
	LEFT = { L0, L1, L1, L1, L0, L0, L1, L0 },
	-- counter-clockwise: down becomes right
	RIGHT = { L1, L0, L0, L0, L1, L1, L0, L1 },
}

local function turnIcon(tex, side)
	local c = TURN[side]
	if c then
		tex:SetTexCoord(c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8])
	else
		tex:SetTexCoord(L0, L1, L0, L1)
	end
end

-- size and slot only change with the icon size option, not with every aura
local function placeIcon(f, b, i, size)
	b.size = size
	b:SetWidth(size)
	b:SetHeight(size)
	b.count:SetFont(FONT, math.max(10, math.floor(size * 0.3)), "OUTLINE")
	b.side:SetFont(FONT, math.max(8, math.floor(size * 0.16)), "THICKOUTLINE")
	b:ClearAllPoints()
	b:SetPoint("LEFT", f, "LEFT", GAP + (i - 1) * (size + GAP), 0)
end

local function setIcon(b, icon, count, duration, expires, side)
	b.tex:SetTexture(icon or PLACEHOLDER)
	if b.turned ~= side then
		b.turned = side
		turnIcon(b.tex, side)
	end
	b.count:SetText((count and count > 1) and count or "")
	b.side:SetText(side and sideText(side) or "")
	if duration and duration > 0 and expires then
		-- the same start and duration keep the spiral running undisturbed
		if b.cdStart ~= expires - duration or b.cdDuration ~= duration then
			b.cdStart, b.cdDuration = expires - duration, duration
			b.cd:SetCooldown(b.cdStart, duration)
		end
		b.cd:Show()
	else
		b.cdStart, b.cdDuration = nil, nil
		b.cd:Hide()
	end
	b:Show()
end

-- ---------------------------------------------------------------------------
-- frame
-- ---------------------------------------------------------------------------
function DDS:CreateDisplay()
	local f = CreateFrame("Frame", "DudeDontSlackFrame", UIParent)
	f:SetFrameStrata("HIGH")
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(false)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(s) if not DDS.db.locked then s:StartMoving() end end)
	f:SetScript("OnDragStop", function(s)
		s:StopMovingOrSizing()
		local p, _, rp, x, y = s:GetPoint()
		DDS.db.point = { p, rp, x, y }
	end)
	f:SetScript("OnMouseUp", function(_, button)
		if button == "RightButton" and DDS.panel then
			InterfaceOptionsFrame_OpenToCategory(DDS.panel)
			InterfaceOptionsFrame_OpenToCategory(DDS.panel)
		end
	end)
	f:SetBackdrop({ bgFile = FLAT, edgeFile = FLAT, edgeSize = 1 })

	local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	title:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 3)
	title:SetText(self.TITLE .. " - drag, right-click for options")
	f.title = title

	f.icons = {}
	self.frame = f
	self:ApplyLayout()
end

function DDS:ApplyLayout()
	local f, db = self.frame, self.db
	f:ClearAllPoints()
	f:SetPoint(db.point[1], UIParent, db.point[2], db.point[3], db.point[4])
	-- locked, the frame lets clicks through to the world
	f:EnableMouse(not db.locked)
	if db.locked then
		f.title:Hide()
		f:SetBackdropColor(0, 0, 0, 0)
		f:SetBackdropBorderColor(0, 0, 0, 0)
	else
		f.title:Show()
		f:SetBackdropColor(0.04, 0.04, 0.05, 0.5)
		f:SetBackdropBorderColor(1, 1, 1, 0.6)
	end

	-- a new icon size reaches the icons as UpdateDisplay draws them
	self:UpdateDisplay()
end

-- ---------------------------------------------------------------------------
-- update
-- ---------------------------------------------------------------------------
local shown = {}
local SAMPLE_IDS = { 70126, 71340, 72754 } -- Frost Beacon, Pact of the Darkfallen, Defile

local function sampleAuras()
	wipe(shown)
	local now = GetTime()
	for i, id in ipairs(SAMPLE_IDS) do
		shown[i] = { icon = select(3, GetSpellInfo(id)), count = (i == 2) and 3 or 0,
			duration = 30, expires = now + 30 - i * 7, side = (id == 70126) and "LEFT" or nil }
	end
	return shown
end

function DDS:UpdateDisplay()
	local f, db = self.frame, self.db
	if not f then return end

	local list
	if self.testMode then
		-- samples are rebuilt only on entry, or the spirals would restart on
		-- every aura change
		list = self.samples or sampleAuras()
		self.samples = list
	else
		self.samples = nil
		if db.locked and db.raidOnly and GetNumRaidMembers() == 0 then
			f:Hide()
			return
		end
		list = self:ScanAuras()
	end

	local n = #list
	if n == 0 and db.locked then
		f:Hide()
		return
	end

	local size = db.iconSize
	local count = math.max(n, 1) -- unlocked with nothing on you: the placeholder
	for i = 1, count do
		local b = f.icons[i]
		if not b then
			b = createIcon(f)
			f.icons[i] = b
		end
		if b.size ~= size then placeIcon(f, b, i, size) end
		local a = list[i]
		if a then
			setIcon(b, a.icon, a.count, a.duration, a.expires, a.side)
		else
			setIcon(b, nil)
		end
	end
	for i = count + 1, #f.icons do f.icons[i]:Hide() end

	if f.count ~= count or f.size ~= size then
		f.count, f.size = count, size
		f:SetWidth(GAP + count * (size + GAP))
		f:SetHeight(size + GAP * 2)
	end
	f:Show()
end
