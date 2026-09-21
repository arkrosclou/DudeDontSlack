--[[ Dude, Don't Slack! - slash commands + Interface Options panel ]]

local DDS = DudeDontSlack

-- ---------------------------------------------------------------------------
-- aura list
-- ---------------------------------------------------------------------------
function DDS:AddAura(id)
	id = tonumber(id)
	local name = id and GetSpellInfo(id)
	if not name then return false end
	self.db.auras[id] = true
	self:RebuildNames()
	if self.RefreshPanel then self:RefreshPanel() end
	return true, name .. " (" .. id .. ")"
end

function DDS:RemoveAura(id)
	id = tonumber(id)
	if not id or not self.db.auras[id] then return false end
	self.db.auras[id] = nil
	self:RebuildNames()
	if self.RefreshPanel then self:RefreshPanel() end
	return true
end

function DDS:ResetAuras()
	self.db.auras = {}
	for id in pairs(self.defaults.auras) do self.db.auras[id] = true end
	self:RebuildNames()
	if self.RefreshPanel then self:RefreshPanel() end
end

-- sorted by name, so the variants of one mechanic sit together
function DDS:SortedAuras()
	local ids, names = {}, {}
	for id in pairs(self.db.auras) do
		ids[#ids + 1] = id
		names[id] = GetSpellInfo(id) or ""
	end
	table.sort(ids, function(a, b)
		local na, nb = names[a], names[b]
		if na ~= nb then return na < nb end
		return a < b
	end)
	return ids
end

function DDS:SetTest(on)
	self.testMode = on
	self:UpdateDisplay()
end

-- ---------------------------------------------------------------------------
-- slash
-- ---------------------------------------------------------------------------
SLASH_DUDEDONTSLACK1 = "/dds"
SLASH_DUDEDONTSLACK2 = "/dudedontslack"
SlashCmdList["DUDEDONTSLACK"] = function(msg)
	local cmd, arg1 = string.match(strtrim(msg or ""), "^(%S*)%s*(%S*)$")
	cmd = string.lower(cmd or "")

	if cmd == "add" then
		local ok, info = DDS:AddAura(arg1)
		DDS:Print(ok and ("watching " .. info) or "usage: /dds add <spellId> (a spell id the client knows)")
	elseif cmd == "remove" or cmd == "del" then
		DDS:Print(DDS:RemoveAura(arg1) and ("removed " .. arg1) or "not in the list: " .. tostring(arg1))
	elseif cmd == "list" then
		DDS:Print("watched auras:")
		for _, id in ipairs(DDS:SortedAuras()) do
			DDS:Print(string.format("  %d - %s", id, GetSpellInfo(id) or "? (unknown id)"))
		end
	elseif cmd == "defaults" then
		DDS:ResetAuras()
		DDS:Print("aura list reset to defaults")
	elseif cmd == "lock" then
		DDS.db.locked = not DDS.db.locked
		DDS:ApplyLayout()
		DDS:Print("frame " .. (DDS.db.locked and "locked" or "unlocked"))
	elseif cmd == "test" then
		DDS:SetTest(not DDS.testMode)
		DDS:Print("test mode " .. (DDS.testMode and "ON" or "OFF"))
	elseif cmd == "reset" then
		DDS.db.point = { "CENTER", "CENTER", 0, 180 }
		DDS:ApplyLayout()
		DDS:Print("position reset")
	elseif cmd == "config" or cmd == "" then
		InterfaceOptionsFrame_OpenToCategory(DDS.panel)
		InterfaceOptionsFrame_OpenToCategory(DDS.panel)
	else
		DDS:Print("commands: config | add <spellId> | remove <spellId> | list | defaults")
		DDS:Print("          lock | test | reset")
	end
end

-- ---------------------------------------------------------------------------
-- options panel
-- ---------------------------------------------------------------------------
-- One column in a scroll frame, every widget placed below the previous one by
-- a running y cursor. Built the first time it is shown: only then does it
-- have a size.

local PAD = 12
local ROW_GAP = 4

local widgetCount = 0
local function uniqueName(kind)
	widgetCount = widgetCount + 1
	return "DudeDontSlack" .. kind .. widgetCount
end

local Flow = {}
Flow.__index = Flow

local function newFlow(parent, width)
	return setmetatable({ parent = parent, width = width, y = -PAD }, Flow)
end

function Flow:space(h)
	self.y = self.y - h
end

function Flow:header(text)
	self:space(8)
	local fs = self.parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	fs:SetPoint("TOPLEFT", PAD, self.y)
	fs:SetText(text)
	self:space(18)
end

function Flow:note(text)
	local fs = self.parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	fs:SetPoint("TOPLEFT", PAD, self.y)
	fs:SetWidth(self.width - PAD * 2)
	fs:SetJustifyH("LEFT")
	fs:SetText(text)
	self:space(math.max(fs:GetStringHeight() or 0, 12) + 6)
end

function Flow:check(label, get, set)
	local cb = CreateFrame("CheckButton", uniqueName("Check"), self.parent, "InterfaceOptionsCheckButtonTemplate")
	cb:SetPoint("TOPLEFT", PAD - 4, self.y)
	_G[cb:GetName() .. "Text"]:SetText(label)
	cb:SetChecked(get())
	cb:SetScript("OnClick", function(s) set(s:GetChecked() and true or false) end)
	self:space(24 + ROW_GAP)
	return cb
end

function Flow:slider(label, minV, maxV, step, fmt, get, set)
	local s = CreateFrame("Slider", uniqueName("Slider"), self.parent, "OptionsSliderTemplate")
	local name = s:GetName()
	self:space(16) -- the label sits above the bar
	s:SetPoint("TOPLEFT", PAD + 4, self.y)
	s:SetWidth(math.min(self.width - PAD * 2 - 8, 280))
	s:SetMinMaxValues(minV, maxV)
	s:SetValueStep(step)
	s:SetValue(get())
	_G[name .. "Low"]:SetText(minV)
	_G[name .. "High"]:SetText(maxV)
	_G[name .. "Text"]:SetText(label .. ": " .. string.format(fmt, get()))
	s:SetScript("OnValueChanged", function(sl, v)
		v = math.floor(v / step + 0.5) * step
		_G[sl:GetName() .. "Text"]:SetText(label .. ": " .. string.format(fmt, v))
		set(v)
	end)
	self:space(34)
end

function DDS:BuildPanel(content, width)
	local db = self.db
	local function redraw() self:ApplyLayout() end
	local flow = newFlow(content, width)

	local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", PAD, flow.y)
	title:SetText(self.TITLE)
	flow:space(24)
	flow:note("A big icon for every aura from the list below that is on you right now. " ..
		"Spell ids are turned into names, so one id covers every difficulty of a mechanic.")

	-- 1. frame
	flow:header("Frame")
	flow:check("Lock frame", function() return db.locked end, function(v) db.locked = v redraw() end)
	flow:check("Only in a raid group", function() return db.raidOnly end,
		function(v) db.raidOnly = v redraw() end)
	local testCheck = flow:check("Test mode (sample icons)", function() return self.testMode end,
		function(v) self:SetTest(v) end)
	flow:slider("Icon size", 32, 200, 4, "%d px", function() return db.iconSize end,
		function(v) db.iconSize = v redraw() end)

	-- 2. auras
	flow:header("Watched auras")

	local idBox = CreateFrame("EditBox", uniqueName("Edit"), content, "InputBoxTemplate")
	idBox:SetPoint("TOPLEFT", PAD + 6, flow.y)
	idBox:SetWidth(70) idBox:SetHeight(20)
	idBox:SetAutoFocus(false)
	idBox:SetNumeric(true)

	local function add()
		local id = idBox:GetNumber()
		if id > 0 then
			local ok, info = self:AddAura(id)
			self:Print(ok and ("watching " .. info) or ("unknown spell id " .. id))
			idBox:SetText("")
			idBox:ClearFocus()
		end
	end
	idBox:SetScript("OnEnterPressed", add)

	local addBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
	addBtn:SetPoint("LEFT", idBox, "RIGHT", 8, 0)
	addBtn:SetWidth(50) addBtn:SetHeight(22)
	addBtn:SetText("Add")
	addBtn:SetScript("OnClick", add)

	local resetBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
	resetBtn:SetPoint("LEFT", addBtn, "RIGHT", 4, 0)
	resetBtn:SetWidth(110) resetBtn:SetHeight(22)
	resetBtn:SetText("Reset defaults")
	resetBtn:SetScript("OnClick", function() self:ResetAuras() end)

	flow:space(22)
	local hint = content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	hint:SetPoint("TOPLEFT", PAD + 2, flow.y)
	hint:SetText("spell id")
	flow:space(18)

	local listTop = flow.y
	local rows = {}

	function self:RefreshPanel()
		testCheck:SetChecked(self.testMode)
		local y = listTop
		for _, r in ipairs(rows) do r:Hide() end
		for i, id in ipairs(self:SortedAuras()) do
			local r = rows[i]
			if not r then
				r = CreateFrame("Frame", nil, content)
				r:SetHeight(20)
				r.icon = r:CreateTexture(nil, "ARTWORK")
				r.icon:SetWidth(16) r.icon:SetHeight(16)
				r.icon:SetPoint("LEFT")
				r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
				r.del = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
				r.del:SetPoint("RIGHT")
				r.del:SetWidth(44) r.del:SetHeight(18)
				r.del:SetText("Del")
				r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
				r.text:SetPoint("LEFT", r.icon, "RIGHT", 4, 0)
				r.text:SetPoint("RIGHT", r.del, "LEFT", -4, 0)
				r.text:SetHeight(14)
				r.text:SetJustifyH("LEFT")
				rows[i] = r
			end
			r:ClearAllPoints()
			r:SetPoint("TOPLEFT", PAD + 2, y)
			r:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
			local name, _, icon = GetSpellInfo(id)
			r.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
			r.text:SetText(string.format("%s |cff888888(%d)|r", name or "|cff888888unknown|r", id))
			r.del:SetScript("OnClick", function() self:RemoveAura(id) end)
			r:Show()
			y = y - 22
		end
		content:SetHeight(-y + PAD)
	end
	self:RefreshPanel()
end

function DDS:InitConfig()
	local panel = CreateFrame("Frame", "DudeDontSlackOptions", UIParent)
	panel.name = self.TITLE
	self.panel = panel

	local scroll = CreateFrame("ScrollFrame", "DudeDontSlackOptionsScroll", panel, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 4, -4)
	scroll:SetPoint("BOTTOMRIGHT", -26, 4)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetWidth(1)
	content:SetHeight(1)
	scroll:SetScrollChild(content)

	panel:SetScript("OnShow", function()
		if self.panelBuilt then
			if self.RefreshPanel then self:RefreshPanel() end
			return
		end
		-- built once, even if it fails: a retry would stack a second copy of
		-- every widget that did get created
		self.panelBuilt = true
		local width = scroll:GetWidth()
		if not width or width < 200 then
			local container = InterfaceOptionsFramePanelContainer
			width = container and container:GetWidth() - 40 or 0
		end
		if width < 200 then width = 380 end
		content:SetWidth(width)
		local ok, err = pcall(self.BuildPanel, self, content, width)
		if not ok then
			self:Print("|cffff5555options panel failed, please report:|r " .. tostring(err))
		end
	end)
	InterfaceOptions_AddCategory(panel)
end
