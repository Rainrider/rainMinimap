local TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]
local BACKDROP = {
	bgFile = TEXTURE,
	insets = {top = -1, bottom = -1, left = -1, right = -1}
}
local FONT = rainDB and rainDB.font2 or GameFontNormal:GetFont()

local GetPlayerMapPosition = GetPlayerMapPosition

local addon = CreateFrame('Frame', nil, Minimap)
addon:SetScript('OnEvent', function(self, event, ...) self[event](self, ...) end)
addon:RegisterEvent('PLAYER_LOGIN')

function addon:PLAYER_LOGIN()
	MinimapCluster:ClearAllPoints()
	MinimapCluster:SetPoint('TOPRIGHT', -10, -10)
	Minimap:SetBackdrop(BACKDROP)
	Minimap:SetBackdropColor(0, 0, 0)
	Minimap:SetMaskTexture(TEXTURE)
	Minimap:SetArchBlobRingScalar(0)
	Minimap:SetQuestBlobRingScalar(0)

	Minimap:SetScript('OnMouseUp', function(self, button)
		if(button == 'RightButton') then
			ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, 'cursor')
		elseif(button == 'MiddleButton') then
			ToggleCalendar()
		else
			Minimap_OnClick(self)
		end
	end)

	Minimap:SetScript('OnMouseWheel', function(self, direction)
		self:SetZoom(self:GetZoom() + (self:GetZoom() == 0 and direction < 0 and 0 or direction))
	end)

	local coordsText = Minimap:CreateFontString(nil, "OVERLAY")
	coordsText:SetPoint("BOTTOM", Minimap, "TOP", 0, 5)
	coordsText:SetFont(FONT, 12)
	coordsText:SetShadowColor(0, 0, 0)
	coordsText:SetShadowOffset(0.75, -0.75)

	local function UpdatePlayerCoords()
		local x, y = GetPlayerMapPosition("player")
		if (x and y) then
			coordsText:SetFormattedText("%.1f / %.1f", x * 100, y * 100)
		end
	end

	local ticker

	MinimapZoneText:SetJustifyH("CENTER")
	MinimapZoneText:SetFont(FONT, 12)
	MinimapZoneText:SetShadowColor(0, 0, 0)
	MinimapZoneText:SetShadowOffset(0.75, -0.75)
	MinimapZoneTextButton:SetParent(Minimap)
	MinimapZoneTextButton:SetPoint("TOP", 5, -5)
	MinimapZoneTextButton:SetScript("OnEnter", function()
		ticker = C_Timer.NewTicker(1, UpdatePlayerCoords)
		coordsText:Show()
	end)
	MinimapZoneTextButton:SetScript("OnLeave", function()
		ticker:Cancel()
		coordsText:Hide()
	end)

	TimeManagerClockButton:SetPoint("BOTTOM", 0, -1)
	local ClockFrame, ClockTime = TimeManagerClockButton:GetRegions()
	ClockFrame:Hide()
	ClockTime:SetFont(FONT, 12)
	ClockTime:SetShadowColor(0, 0, 0)
	ClockTime:SetShadowOffset(0.75, -0.75)

	GarrisonLandingPageMinimapButton:ClearAllPoints()
	GarrisonLandingPageMinimapButton:SetParent(Minimap)
	GarrisonLandingPageMinimapButton:SetPoint('BOTTOMLEFT')
	GarrisonLandingPageMinimapButton:SetSize(32, 32)

	QueueStatusMinimapButton:ClearAllPoints()
	QueueStatusMinimapButton:SetParent(Minimap)
	QueueStatusMinimapButton:SetPoint('BOTTOMRIGHT')
	QueueStatusMinimapButton:SetHighlightTexture(nil)

	MiniMapMailFrame:ClearAllPoints()
	MiniMapMailFrame:SetParent(Minimap)
	MiniMapMailFrame:SetPoint('TOPLEFT')
	MiniMapMailIcon:SetTexture([[Interface\Minimap\Tracking\Mailbox]])

	MiniMapInstanceDifficulty:Hide()
	MiniMapInstanceDifficulty:UnregisterAllEvents()
	MinimapCluster:EnableMouse(false)
	DurabilityFrame:SetAlpha(0)

	for _, name in next, {
		'GameTimeFrame',
		'MinimapBorder',
		'MinimapBorderTop',
		'MinimapNorthTag',
		'MinimapZoomIn',
		'MinimapZoomOut',
		'MiniMapMailBorder',
		'MiniMapTracking',
		'MiniMapWorldMapButton',
		'QueueStatusMinimapButtonBorder',
		'QueueStatusMinimapButtonGroupSize',
	} do
		local object = _G[name]
		if(object:GetObjectType() == 'Texture') then
			object:SetTexture(nil)
		else
			object.Show = object.Hide
			object:Hide()
		end
	end

	SetCVar('rotateMinimap', 0)

	self:UPDATE_INVENTORY_DURABILITY()
	self:RegisterEvent('UPDATE_INVENTORY_DURABILITY')
	self:RegisterEvent('UPDATE_PENDING_MAIL')
end

function addon:UPDATE_INVENTORY_DURABILITY()
	local alert = 0
	for index in next, INVENTORY_ALERT_STATUS_SLOTS do
		local status = GetInventoryAlertStatus(index)
		if(status > alert) then
			alert = status
		end
	end

	local color = INVENTORY_ALERT_COLORS[alert]
	if(color) then
		Minimap:SetBackdropColor(color.r * 2/3 , color.g * 2/3 , color.b * 2/3 )
	else
		Minimap:SetBackdropColor(0, 0, 0)
	end

	for index = 1, GetNumTrackingTypes() do
		local name, _, active = GetTrackingInfo(index)
		if(name == MINIMAP_TRACKING_REPAIR) then
			return SetTracking(index, alert > 0)
		end
	end
end

function addon:UPDATE_PENDING_MAIL()
	if(GetRestrictedAccountData() > 0) then
		return MiniMapMailFrame:Hide()
	end

	for index = 1, GetNumTrackingTypes() do
		local name, _, active = GetTrackingInfo(index)
		if(name == MINIMAP_TRACKING_MAILBOX) then
			return SetTracking(index, MiniMapMailFrame:IsShown() and not active)
		end
	end
end

function addon:MAIL_CLOSED()
	local _, numInboxItems = GetInboxNumItems()
	if(HasNewMail() and numInboxItems == 0) then
		MiniMapMailFrame:Hide()
		self:UPDATE_PENDING_MAIL()
	end
end

function GetMinimapShape()
	return 'SQUARE'
end
