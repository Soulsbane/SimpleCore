local AddonName, Addon = ...
local AddonFrame = CreateFrame("Frame", AddonName .. "AddonFrame", UIParent)

local EventHandlers = {}

local PRINTHEADER = "|cff33ff99" .. AddonName .. "|r: "

AddonFrame:RegisterEvent("PLAYER_LOGIN")
AddonFrame:RegisterEvent("PLAYER_LOGOUT")
AddonFrame:RegisterEvent("ADDON_LOADED")

---------------------------------------
-- Utility Functions 
---------------------------------------
function Addon:Print(...)
	print(PRINTHEADER, string.format(...))
end

---------------------------------------
-- Event Registration Functions
---------------------------------------
local function OnEvent(frame, event, ...)

end

AddonFrame:SetScript("OnEvent", OnEvent)

function Addon:RegisterEvent(event, handler)

end

function Addon:UnregisterEvent(event)

end