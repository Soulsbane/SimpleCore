 local AddonName, Addon = ...
_G[AddonName] = Addon


local defaults = {
	pingMsg = "Ping from: ",
	coords = 0.0,
	zone = "None",
}

function Addon:OnInitialize()
	self:EnableDebug(true)
	self:InitializeDB(defaults)
	--self:RegisterEvent({"ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED_INDOORS" }, "OnZoneChanged")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("MINIMAP_PING", "OnMiniMapPing")
	self:StartTimer(60)
end

function Addon:OnFullyLoaded()
	self:RegisterSlashCommand("simplecore", "OnSimpleCoreSlashCommand")
end

function Addon:OnSlashCommand(...)
	local msg, nextMsg = ...

	if msg == "foo" then
		self:Print("Testing msg argument: %s %s %s", msg, "and another", nextMsg)
	elseif msg == "timer" and nextMsg == "stop" then
		self:Print("Stoping timer...")
		self:StopTimer()
	elseif msg == "timer" and nextMsg == "start" then
		self:Print("Starting timer...")
		self:StartTimer()
	elseif msg == "enable" and nextMsg then
		self:EnableModule(nextMsg)
	elseif msg == "disable" and nextMsg then
		self:DisableModule(nextMsg)
	else
		self:Print(msg)
	end
end

function Addon:OnSimpleCoreSlashCommand(...)
	local msg = ...
	self:Print("OnSimpleCoreSlashCommand: " .. msg)
end

function Addon:OnTimer(elapsed)
	self:DebugPrint("Addon:OnTimer -> " .. tostring(elapsed))
end

function Addon:OnZoneChanged(event)
	local db = Addon.db
	db["zone"] = GetZoneText()
	self:DebugPrint("%s: %s", event, db.zone)
end

function Addon:PLAYER_TARGET_CHANGED(event)
	self:DebugPrint(event)
	if UnitExists("target") then
	end
end

function Addon:OnMiniMapPing(event, unit, x, y)
	Addon.db.coords = x
	self:DebugPrint("%s %s X: %f Y: %f", Addon.db.pingMsg ,unit, x, y)
end
