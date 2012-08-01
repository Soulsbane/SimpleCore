local AddonName, Addon = ...
local AddonFrame = CreateFrame("Frame", AddonName .. "AddonFrame", UIParent)

local AddonObject = {}
local DebugEnabled = false
local EventHandlers = {}
local TimerDelay, TotalTimeElapsed = 1, 0

local PRINTHEADER = "|cff33ff99" .. AddonName .. "|r: "
local DEBUGHEADER = "|cff33ff99" .. AddonName .. "|cfffffb00" .. "(DEBUG)" .. "|r: "

AddonFrame:RegisterEvent("PLAYER_LOGIN")
AddonFrame:RegisterEvent("PLAYER_LOGOUT")
AddonFrame:RegisterEvent("ADDON_LOADED")

---------------------------------------
-- Utility Functions 
---------------------------------------
function AddonObject:Print(...)
	print(PRINTHEADER, string.format(...))
end

---------------------------------------
-- Debug Functions 
---------------------------------------
function AddonObject:DebugPrint(...)
	if DebugEnabled == true then
		print(DEBUGHEADER, string.format(...))
	end
end

function AddonObject:IsDebugEnabled()
	return DebugEnabled
end

function AddonObject:EnableDebug(enable)
	DebugEnabled = enable
end

---------------------------------------
-- Event Registration Functions
---------------------------------------
local function OnEvent(frame, event, ...)

end

AddonFrame:SetScript("OnEvent", OnEvent)

function AddonObject:RegisterEvent(event, handler)
	if not handler then
		handler = event
	end

end

function AddonObject:UnregisterEvent(event)

end

setmetatable(Addon, { __index = AddonObject})

--------------------------------------
-- Timer Functions
---------------------------------------
AddonFrame:SetScript("OnUpdate", function(self, elapsed)
	TotalTimeElapsed = TotalTimeElapsed + elapsed
	
	if TotalTimeElapsed < TimerDelay then return end
	TotalTimeElapsed = 0

	DispatchMethod("OnTimer", elapsed)
end)

function Addon:StartTimer(delay)
	if delay then
		self:SetTimerDelay(delay)
	end
	AddonFrame:Show()
end

function Addon:StopTimer()
	AddonFrame:Hide()
end

function Addon:SetTimerDelay(delay)
	TimerDelay = delay
end