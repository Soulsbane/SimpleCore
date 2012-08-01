local AddonName, Addon = ...
local AddonFrame = CreateFrame("Frame", AddonName .. "AddonFrame", UIParent)

local AddonObject = {}
local DebugEnabled = false
local SavedVariableDefaults
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
local function DispatchMethod(func, ...)
	if type(func) == "string" and Addon[func] then
		Addon[func](Addon, ...)
	end
end

function Addon:DispatchModuleMethod(func, ...)
	for k, v in pairs(Modules) do
		if v[func] then
			v[func](v, ...)		
		end
	end
end

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

---------------------------------------
-- SavedVariables(Database) Functions 
---------------------------------------
local function FlushDB()
	for k, v in pairs(SavedVariableDefaults) do
		if v == Addon.db[k] then
			Addon.db[k] = nil
		end
	end
end

function Addon:InitializeDB(defaults)
	local name = AddonName .. "DB"
	SavedVariableDefaults = defaults or {}

	_G[name] = setmetatable(_G[name] or {}, {__index = SavedVariableDefaults})
	self.db = {}
	self.db = _G[name]
end

---------------------------------------
-- Module System 
---------------------------------------
function Addon:NewModule(name)
end

function Addon:IsModuleEnabled(name)
end

function Addon:EnableModule(name)
end

function Addon:DisableModule(name)
end

---------------------------------------
-- Initialization Functions 
---------------------------------------
function Addon:PLAYER_LOGIN()
	if self["OnSlashCommand"] then
		self:RegisterSlashCommand(AddonName)	
	end

	DispatchMethod("OnReady")
	self:DispatchModuleMethod("OnReady")
end

function Addon:PLAYER_LOGOUT()
	FlushDB()
end

function Addon:ADDON_LOADED(event, ...)
	self:StopTimer()

	if ... == AddonName then
		self:UnregisterEvent("ADDON_LOADED")
		DispatchMethod("OnInitialize")
		self:DispatchModuleMethod("OnInitialize")	

		if IsLoggedIn() and Addon["OnReady"] then
			DispatchMethod("OnReady")
			self:DispatchModuleMethod("OnReady")
		end
	end
end