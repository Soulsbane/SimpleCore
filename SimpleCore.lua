local AddonName, Addon = ...
local AddonFrame = CreateFrame("Frame", AddonName .. "AddonFrame", UIParent)

local AddonObject = {}
local EventHandlers = {}

local PRINTHEADER = "|cff33ff99" .. AddonName .. "|r: "

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