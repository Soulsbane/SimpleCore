local AddonName, Addon = ...
local Module = Addon:NewModule("Timer")

function Module:OnInitialize()
	self:StartTimer(30, "NonRepeatingTimer", false)
end

function Module:NonRepeatingTimer(elapsed)
	self:DebugPrint("NonRepeatingTimer test....")
end
