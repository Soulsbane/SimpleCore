local AddonName, Addon = ...
local AddonFrame = CreateFrame("Frame", AddonName .. "AddonFrame", UIParent)

local AddonObject = {}
local DebugEnabled = false
local SavedVariableDefaults
local EventHandlers = {}
local TimerDelay, TotalTimeElapsed = 1, 0

local Modules = {}
local DisabledModules = {}

local PRINTHEADER = "|cff33ff99" .. AddonName .. "|r: "
local DEBUGHEADER = "|cff33ff99" .. AddonName .. "|cfffffb00" .. "(DEBUG)" .. "|r: "

---------------------------------------
-- Utility Functions
---------------------------------------
local function DispatchMethod(func, ...)
	if type(func) == "string" and Addon[func] then
		Addon[func](Addon, ...)
	end
end

function Addon:DispatchModuleMethod(func, ...)
	--FIXME: Update to new EventHandler code
	for k, v in pairs(Modules) do
		if v[func] then
			v[func](v, ...)
		end
	end
end

function AddonObject:Print(...)
	--INFO: This is a module calling print so use it's header instead
	if self.printHeader then
		print(self.printHeader, string.format(...))
	else
		print(PRINTHEADER, string.format(...))
	end
end

---------------------------------------
-- Debug Functions
---------------------------------------
function AddonObject:DebugPrint(...)
	--TODO: Maybe add support for using the modules name in the print statement also
	if DebugEnabled == true then
		print(DEBUGHEADER, string.format(...))
	end
end

function Addon:IsDebugEnabled()
	return DebugEnabled
end

function Addon:EnableDebug(enable)
	DebugEnabled = enable
end

---------------------------------------
-- Event Registration Functions
---------------------------------------
local function OnEvent(frame, event, ...)
	local handlers = EventHandlers[event]

	if handlers then
		for obj, func in pairs(handlers) do
				if type(func) == "string" then
					if type(obj[func]) == "function" then
						obj[func](obj, event, ...)
					end
				else
					func(event, ...)
				end
			end
	end
end

AddonFrame:SetScript("OnEvent", OnEvent)

function AddonObject:RegisterEvent(event, handler)
	if not handler then
		handler = event
	end

	if type(event) == "table" then
		for _,e in pairs(event) do
			if not EventHandlers[event] then
				EventHandlers[event] = {}
				AddonFrame:RegisterEvent(event)
			end
		end
	else
		if not EventHandlers[event] then
				EventHandlers[event] = {}
				AddonFrame:RegisterEvent(event)
		end
	end

	EventHandlers[event][self] = handler
end

function AddonObject:UnregisterEvent(event)

end

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
-- Slash Command Functions
---------------------------------------
function Addon:RegisterSlashCommand(name, func)
	if SlashCmdList[name] then
		self:DebugPrint("Error: Slash command " .. command .. " already exists!")
	else
		_G["SLASH_".. name:upper().."1"] = "/" .. name

		if type(func) == "string" then
			--NOTE: Register a custom function to handle slash commands
			SlashCmdList[name:upper()] = function(msg)
				DispatchMethod(func, strsplit(" ", msg))
			end
		else
			SlashCmdList[name:upper()] = function(msg)
				DispatchMethod("OnSlashCommand", strsplit(" ", msg))
			end
		end
	end
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
	local obj
	local defaults = {
		name = name,
		printHeader = "|cff33ff99" .. AddonName .. "(" .. name .. ")".. "|r: ",
		enabled = true,
	}

	obj = setmetatable(defaults, { __index = AddonObject })
	Modules[name] = obj

	return obj
end

function Addon:IsModuleEnabled(name)
	return Modules[name].enabled
end

function Addon:EnableModule(name)
	if DisabledModules[name] then
		local obj

		Modules[name] = DisabledModules[name]
		obj = Modules[name]

		if obj["OnEnable"] then
			obj:OnEnable()
		end
	else
		self:DebugPrint("Module, %s, is already enabled or not loaded!", name)
	end
end

function Addon:DisableModule(name)
	if Modules[name] then
		local obj

		DisabledModules[name] = Modules[name]
		obj = Modules[name]

		if obj["OnDisable"] then
			obj:OnDisable()
		end

		Modules[name] = nil
	else
		self:DebugPrint("Module, %s, is already disabled or not loaded!", name)
	end
end

---------------------------------------
-- Initialization Functions
---------------------------------------
function Addon:PLAYER_LOGIN()
	if self["OnSlashCommand"] then
		self:RegisterSlashCommand(AddonName)
	end

	DispatchMethod("OnFullyLoaded")
	self:DispatchModuleMethod("OnFullyLoaded")
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

		if IsLoggedIn() then
			DispatchMethod("OnFullyLoaded")
			self:DispatchModuleMethod("OnFullyLoaded")
		end
	end
end

setmetatable(Addon, { __index = AddonObject})
Addon:RegisterEvent("PLAYER_LOGIN")
Addon:RegisterEvent("PLAYER_LOGOUT")
Addon:RegisterEvent("ADDON_LOADED")
