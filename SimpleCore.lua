local AddonName, Addon = ...
local AddonFrame = CreateFrame("Frame", AddonName .. "AddonFrame", UIParent)

local AddonObject = {}
local DebugEnabled = false
local SavedVariableDefaults
local EventHandlers = {}
local MessageHandlers = {}
local TimerDelay, TotalTimeElapsed = 1, 0
local Modules = {}

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
	for name, obj in pairs(Modules) do
		if obj[func] and obj.enabled then
			obj[func](obj, ...)
		end
	end
end

function AddonObject:Print(...)
	--INFO: If this is a module calling Print use its header instead
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
	if DebugEnabled == true then
		if self.debugHeader then
			print(self.debugHeader, string.format(...))
		else
			print(DEBUGHEADER, string.format(...))
		end
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

function AddonObject:RegisterEvent(eventName, handler)
	if not handler then
		handler = eventName
	end

	if type(eventName) == "table" then
		for _, name in pairs(eventName) do
			if not EventHandlers[name] then
				EventHandlers[name] = {}
			end
			AddonFrame:RegisterEvent(name)
			EventHandlers[name][self] = handler
		end
	else
		if not EventHandlers[eventName] then
			EventHandlers[eventName] = {}
		end
		AddonFrame:RegisterEvent(eventName)
		EventHandlers[eventName][self] = handler
	end
end

function AddonObject:UnregisterEvent(eventName)
	local obj = EventHandlers[eventName]

	if obj then
		obj[self] = nil
		if not next(obj) then
			EventHandlers[eventName] = nil
			AddonFrame:UnregisterEvent(eventName)
		end
	end
end

function AddonObject:UnregisterAllEvents()
	for eventName, obj in pairs(EventHandlers) do
		obj[self] = nil

		if not next(obj) then
			EventHandlers[eventName] = nil
			frame:UnregisterEvent(eventName)
		end
	end
end

--------------------------------------
-- Timer Functions
---------------------------------------
function AddonObject:DispatchMessage(messageName)
	local handlers = MessageHandlers[event]

	if handlers then
		for obj, func in pairs(handlers) do
				if type(func) == "string" then
					if type(obj[func]) == "function" then
						obj[func](obj, ...)
					end
				else
					func(...)
				end
			end
	end
end

function AddonObject:RegisterMessage(messageName, handler)
	if not handler then
		handler = messageName
	end

	if type(messageName) == "table" then
		for _, name in pairs(messageName) do
			if not MessageHandlers[name] then
				MessageHandlers[name] = {}
			end
			MessageHandlers[name][self] = handler
		end
	else
		if not MessageHandlers[messageName] then
			MessageHandlers[messageName] = {}
		end
		MessageHandlers[messageName][self] = handler
	end
end

function AddonObject:UnregisterMessage(messageName)
	local obj = MessageHandlers[messageName]

	if obj then
		obj[self] = nil
		if not next(obj) then
			MessageHandlers[messageName] = nil
		end
	end
end

function AddonObject:UnregisterAllMessages()
	for messageName, obj in pairs(MessageHandlers) do
		obj[self] = nil

		if not next(obj) then
			MessageHandlers[messageName] = nil
		end
	end
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
			--INFO: Register a custom function to handle slash commands
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

	return self.db
end

---------------------------------------
-- Module System
---------------------------------------
function Addon:NewModule(name)
	local obj
	local defaults = {
		name = name,
		printHeader = "|cff33ff99" .. AddonName .. "(" .. name .. ")" .. "|r: ",
		debugHeader = "|cff33ff99" .. AddonName .. "(" .. name .. ")" .. "|cfffffb00" .. "(DEBUG)" .. "|r: ",
		enabled = true,
	}

	obj = setmetatable(defaults, { __index = AddonObject })
	Modules[name] = obj

	return obj
end

function Addon:IsModuleEnabled(name)
	if Modules[name] then
		return Modules[name].enabled
	end

	return false
end

function Addon:EnableModule(name)
	local obj = Modules[name]

	if obj then
		if obj["OnEnable"] then
			obj:OnEnable()
		end
		obj.enabled = true
	else
		self:DebugPrint("Module, %s, is already enabled or not loaded!", name)
	end
end

function Addon:DisableModule(name)
	local obj = Modules[name]

	if obj then
		if obj["OnDisable"] then
			obj:OnDisable()
		end
		obj:UnregisterAllEvents()
		obj.enabled = false
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
	self:DispatchModuleMethod("OnEnable")
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
			self:PLAYER_LOGIN()
		end
	end
end

setmetatable(Addon, { __index = AddonObject})
Addon:RegisterEvent("PLAYER_LOGIN")
Addon:RegisterEvent("PLAYER_LOGOUT")
Addon:RegisterEvent("ADDON_LOADED")
