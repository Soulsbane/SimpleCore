local AddonName, Addon = ...
local Module = Addon:NewModule("CombatStatus")

function Module:OnInitialize()
	self:RegisterEvent({"PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED"}, "OnCombatStatusUpdate")
end

function Module:OnCombatStatusUpdate()
end
