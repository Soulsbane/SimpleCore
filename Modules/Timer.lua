local AddonName, Addon = ...
local Module = Addon:NewModule("Timer")

function Module:OnInitialize()
	self:StartTimer(30, "NonRepeatingTimer", false, "TimerModuleTimer")
end

function Module:NonRepeatingTimer(elapsed, name)
	self:DebugPrint("NonRepeatingTimer..." .. name)
end
