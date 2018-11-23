 local AddonName, Addon = ...
_G[AddonName] = Addon

local Defaults = {
	pingMsg = "Ping from: ",
	coords = 0.0,
	zone = "The Jade Forest",
	zonesLogged = {},
}

function Addon:OnInitialize()
	self:EnableDebug(true)
	self:InitializeDB(Defaults)

	--self:StartRepeatingTimer(10, nil, "RepeatingTimer") --NOTE: We don't need a variable here if you don't plan on ever calling StopTimer
	self:StartRepeatingTimer(10, "OnRepeatingPauseTimer", "RepeatingPauseTimer") --NOTE: We don't need a variable here if you don't plan on ever calling StopTimer
	--self:StartTimer(60, "OnNonRepeatingTimer")

	self:RegisterEvent({"ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED_INDOORS" }, "OnZoneChanged")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("MINIMAP_PING", "OnMiniMapPing")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
end

function Addon:OnEnable()
	--self:RegisterSlashCommand("sc", "OnSimpleCoreTests")
	self:RegisterSlashCommand("sc")
end

function Addon:OnAddonLoaded(name)
end

function Addon:OnSlashCommand(...)
	local msg, nextMsg = ...

	if msg == "unregisterallevents" then
		self:UnregisterAllEvents()
	elseif msg == "timer" and nextMsg == "stop" then
		self:DebugPrint("Stopping timer...")
		self:StopTimer("RepeatingTimer")
	elseif msg == "timer" and nextMsg == "stopall" then
		self:DebugPrint("Stopping timers...")
		self:StopAllTimers()
	elseif msg == "timer" and nextMsg == "start" then
		self:DebugPrint("Starting timer...")
		self:StartTimer(20, nil, "slash")
	elseif msg == "enable" and nextMsg then
		self:DebugPrint("Enabling module %s", nextMsg)
		self:EnableModule(nextMsg)
	elseif msg == "disable" and nextMsg then
		self:DebugPrint("Disabling module %s", nextMsg)
		self:DisableModule(nextMsg)
	elseif msg == "pingmsg" and nextMsg then
		self.db.pingMsg = nextMsg
	elseif msg == "pause" then
		--self:DebugPrint("Pausing...")
		self:PauseTimer("RepeatingPauseTimer")
	elseif msg == "resume" then
		--self:DebugPrint("Resuming...")
		self:ResumeTimer("RepeatingPauseTimer")
	else
		self:DebugPrint("DEFAULT SLASH COMMAND HANDLER: " .. msg)
	end
end

function Addon:OnSimpleCoreTests(...)
	local msg = ...
	self:DebugPrint("OnSimpleCoreTests: " .. msg)
end

function Addon:OnTimer(name)
	self:DebugPrint("Addon:OnTimer -> " .. name)
end

function Addon:OnNonRepeatingTimer(name)
	self:DebugPrint("Stopping NON-Repeating timer.")
end

function Addon:OnRepeatingPauseTimer(name)
	self:DebugPrint("OnRepeatingPauseTimer tick -> " .. name)
end

function Addon:OnTimerPause(name)
	self:DebugPrint("Pausing: " .. name)
end

function Addon:OnTimerResume(name)
	self:DebugPrint("Resuming: " .. name)
end

function Addon:OnTimerStop(name)
	self:DebugPrint("Stopping timer: " .. name)
end

function Addon:OnStopAllTimers()
	self:DebugPrint("Stoping all timers!")
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
