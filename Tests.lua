 local AddonName, Addon = ...
_G[AddonName] = Addon

local defaults = {
	pingMsg = "Ping from: ",
	coords = 0.0,
	zone = "The Jade Forest",
	zonesLogged = {},
}

function Addon:OnInitialize()
	self:EnableDebug(true)
	self:InitializeDB(defaults)
	self:StartTimer(60)

	self:RegisterEvent({"ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED_INDOORS" }, "OnZoneChanged")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("MINIMAP_PING", "OnMiniMapPing")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
end

function Addon:OnFullyLoaded()
	self:RegisterSlashCommand("sctests", "OnSimpleCoreTests")
end

function Addon:OnSlashCommand(...)
	local msg, nextMsg = ...

	if msg == "unregisterallevents" then
		self:UnregisterAllEvents()
	elseif msg == "timer" and nextMsg == "stop" then
		self:DebugPrint("Stoping timer...")
		self:StopTimer()
	elseif msg == "timer" and nextMsg == "start" then
		self:DebugPrint("Starting timer...")
		self:StartTimer()
	elseif msg == "enable" and nextMsg then
		self:DebugPrint("Enabling module %s", nextMsg)
		self:EnableModule(nextMsg)
	elseif msg == "disable" and nextMsg then
		self:DebugPrint("Disabling module %s", nextMsg)
		self:DisableModule(nextMsg)
	elseif msg == "pingmsg" and nextMsg then
		self.db.pingMsg = nextMsg
	else
		self:DebugPrint(msg)
	end
end

function Addon:OnSimpleCoreTests(...)
	local msg = ...
	self:DebugPrint("OnSimpleCoreTests: " .. msg)
end

function Addon:OnTimer(elapsed)
	self:DebugPrint("Addon:OnTimer -> " .. tostring(elapsed))
end

function Addon:OnZoneChanged(event)
	local db = self.db
	local zone = GetSubZoneText()

	db["zone"] = zone
	db.zonesLogged[zone] = zone

	self:DebugPrint("%s: %s", event, db.zone)
end

function Addon:PLAYER_TARGET_CHANGED(event)
	self:DebugPrint(event)
end

function Addon:OnMiniMapPing(event, unit, x, y)
	self.db.coords = x
	self:DebugPrint("%s %s X: %f Y: %f", self.db.pingMsg ,unit, x, y)
end

function Addon:PLAYER_REGEN_ENABLED()
	self:DispatchMessage("OnLeavingCombat")
end

function Addon:PLAYER_REGEN_DISABLED()
	self:DispatchMessage("OnEnteringCombat")
end
