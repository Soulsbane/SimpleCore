local AddonName, Addon = ...
local Module = Addon:NewModule("Zones")

function Module:OnInitialize()
	self:RegisterEvent({"ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED_INDOORS" }, "OnZoneChanged")
end

function Module:OnZoneChanged(event)
	self:Print("OnZoneChanged: %s", event)
end
