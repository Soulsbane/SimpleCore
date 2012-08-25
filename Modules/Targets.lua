local AddonName, Addon = ...
local Module = Addon:NewModule("Targets")

function Module:OnInitialize()
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
end

function Module:PLAYER_TARGET_CHANGED()
	self:DebugPrint("PLAYER_TARGET_CHANGED")
	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
end
