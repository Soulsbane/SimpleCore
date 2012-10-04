local AddonName, Addon = ...
local Module = Addon:NewModule("CombatStatus")

function Module:OnInitialize()
	self:RegisterMessage({"OnEnteringCombat", "OnLeavingCombat"}, "OnCombatStatusUpdate")
end

function Module:OnCombatStatusUpdate(message)
	self:Print("OnCombatStatusUpdate: %s", message)
end
