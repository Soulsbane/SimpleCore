local AddonName, Addon = ...
local Module = Addon:NewModule("Timer")

function Module:OnInitialize()
	self:StartTimer(30, "NonRepeatingTimer", "TimerModuleTimer")
end

function Module:NonRepeatingTimer(name)
	self:DebugPrint("NonRepeatingTimer..." .. name)
end
