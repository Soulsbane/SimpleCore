local AddonName, Addon = ...
local AddonFrame = CreateFrame("Frame", AddonName .. "AddonFrame", UIParent)

local AddonObject = {}
local DebugEnabled = false
local EventHandlers = {}
local MessageHandlers = {}
local Timers = {}
local Modules = {}

---------------------------------------
-- Utility Functions
---------------------------------------
local function CreateAddonObject(name, base)
	local name = name
	local base = base or {}

	if name then
		name = "(" .. name .. ")"
	else
		name = ""
	end

	base.name = name
	base.enabled = true
	base.printHeader = "|cff33ff99" .. AddonName .. name .. "|r: "
	base.debugHeader = "|cff33ff99" .. AddonName .. name .. "|cfffffb00" .. "(DEBUG)" .. "|r: "

	return setmetatable(base, { __index = AddonObject })
end

local function DispatchMethod(func, ...)
	if type(func) == "string" and Addon[func] then
		Addon[func](Addon, ...)
	elseif type(func) == "function" then
		func(...)
	end
end

function Addon:DispatchModuleMethod(func, ...)
	for name, obj in pairs(Modules) do
		if obj[func] and obj.enabled then
			obj[func](obj, ...)
		end
	end
end

function AddonObject:GetFormattedString(header, ...)
	if select("#", ...) > 1 then
		local success, txt = pcall(string.format, ...)

		if success then
			return (header .. txt)
		else
			if DebugEnabled then --INFO: We will only make it here if a nil value was passed so only show if debug mode is enabled
				return (self.debugHeader .. string.gsub(txt, "'%?'", string.format("'%s'", "GetFormattedString")))
			end
		end
	else
		local txt = ...

		if txt then
			return (header .. txt)
		else
			return (self.debugHeader .. "Nil value was passed to GetFormattedString!")
		end
	end
end

function AddonObject:Print(...)
		print(self:GetFormattedString(self.printHeader, ...))
end

---------------------------------------
-- Debug Functions
---------------------------------------
local function DebugPrint(msg) --INFO: If AdiDebug is enabled this function will be overridden with AdiDebug's function
	print(msg)
end

function AddonObject:DebugPrint(...)
	if DebugEnabled then
			DebugPrint(self:GetFormattedString(self.debugHeader, ...))
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
			AddonFrame:UnregisterEvent(eventName)
		end
	end
end

--------------------------------------
-- Message Event Functions
---------------------------------------
function AddonObject:DispatchMessage(messageName, ...)
	local handlers = MessageHandlers[messageName]

	if handlers then
		for obj, func in pairs(handlers) do
				if type(func) == "string" then
					if type(obj[func]) == "function" then
						obj[func](obj, messageName, ...)
					end
				else
					func(messageName, ...)
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
local function StartTimer(object, delay, func, repeating, name)
	local timer = {}
	local name = name or tostring(timer) -- NOTE: If you are going to create more than one timer you should really name it

	if delay < 0.01 then
		delay = 0.01 -- INFO: The lowest time C_Timer API allows.
	end

	timer.object = object
	timer.delay = delay or 60
	timer.repeating = repeating
	timer.func = func or "OnTimer"
	timer.name = name

	Timers[name] = timer

	timer.callback = function()
		if not timer.stopped then
			timer.object[timer.func](timer.object, timer.name)

			if timer.repeating and not timer.stopped then
				C_Timer.After(timer.delay, timer.callback)
			else
				Timers[name] = nil
			end
		end
	end

	C_Timer.After(delay, timer.callback)
	return name
end

function AddonObject:StartTimer(delay, func, name)
	return StartTimer(self, delay, func, false, name)
end

function AddonObject:StartRepeatingTimer(delay, func, name)
	return StartTimer(self, delay, func, true, name)
end

function AddonObject:StopTimer(name)
	local timer = Timers[name]

	if timer then
		timer.stopped = true
		Timers[name] = nil
		DispatchMethod("OnTimerStop", name)
	end
end

function AddonObject:StopAllTimers()
	for name, _ in pairs(Timers) do
		self:StopTimer(name)
	end

	wipe(Timers)
	DispatchMethod("OnStopAllTimers")
end

function AddonObject:SetTimerDelay(name, delay)
	Timers[name].delay = delay
end

---------------------------------------
-- Slash Command Functions
---------------------------------------
local function HandleDebugToggle(msg)
	local command, enable = strsplit(" ", msg)

	if command == "debug" then
		if enable == "enable" then
			Addon:EnableDebug(true)
			Addon:DispatchModuleMethod("EnableDebug", true)
			Addon:DebugPrint("Enabling debug mode!")
		else
			Addon:DebugPrint("Disabling debug mode!")
			Addon:EnableDebug(false)
			Addon:DispatchModuleMethod("EnableDebug", false)
		end
	end
end

function Addon:RegisterSlashCommand(name, func)
	if SlashCmdList[name] then
		self:DebugPrint("Error: Slash command " .. command .. " already exists!")
	else
		_G["SLASH_".. name:upper().."1"] = "/" .. name

		if type(func) == "string" then
			--INFO: Register a custom function to handle slash commands
			SlashCmdList[name:upper()] = function(msg)
				HandleDebugToggle(msg)
				DispatchMethod(func, strsplit(" ", msg))
			end
		else
			SlashCmdList[name:upper()] = function(msg)
				HandleDebugToggle(msg)
				DispatchMethod("OnSlashCommand", strsplit(" ", msg))
			end
		end
	end
end

---------------------------------------
-- SavedVariables(Database) Functions
---------------------------------------
local function CopyDefaults(src, dest)
	for k, v in pairs(src) do
		if type(v) == "table" then
			if not rawget(dest, k) then rawset(dest, k, {}) end
			if type(dest[k]) == "table" then
				CopyDefaults(dest[k], v)
			end
		else
			if rawget(dest, k) == nil then
				rawset(dest, k, v)
			end
		end
	end
end

function Addon:InitializeDB(defaults)
	local name = AddonName .. "DB"
	local db = {}

	if defaults then
		CopyDefaults(defaults, db)
	end

	_G[name] = db
	self.db = _G[name]

	return self.db
end


---------------------------------------
-- Defer Function Calls
---------------------------------------
local DeferFrame = CreateFrame("Frame", AddonName .. "DeferFrame", UIParent)
DeferFrame.Queue = {}

function AddonObject:DeferFunctionCall(func, ...)
	local args = { ... }

	if InCombatLockdown() then
		DeferFrame.Queue[func] = { ... }
		return true
	else
		DispatchMethod(func, ...)
		return false
	end
end

DeferFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
DeferFrame:SetScript("OnEvent", function(self, event, ...)
    for func, args in pairs(DeferFrame.Queue) do
        DispatchMethod(func, unpack(args))
    end
    table.wipe(DeferFrame.Queue)
end)

---------------------------------------
-- Module System
---------------------------------------
function Addon:NewModule(name)
	local obj = CreateAddonObject(name, nil)

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
		--FIXME: Timers might keep going after disabling.
		obj:UnregisterAllEvents()
		obj.enabled = false
	else
		self:DebugPrint("Module, %s, is already disabled or not loaded!", name)
	end
end

function Addon:IterateModules()
	return Modules
end

---------------------------------------
-- Initialization Functions
---------------------------------------
function Addon:PLAYER_LOGIN()
	if self["OnSlashCommand"] then
		self:RegisterSlashCommand(AddonName)
	end

	DispatchMethod("OnEnable")
	self:DispatchModuleMethod("OnEnable")
end

function Addon:ADDON_LOADED(event, ...)
	if AdiDebug then
		DebugPrint = AdiDebug:GetSink(AddonName)
	end

	if ... == AddonName then
		DispatchMethod("OnInitialize")
		self:DispatchModuleMethod("OnInitialize")

		if IsLoggedIn() then
			self:PLAYER_LOGIN()
		end
	else
		DispatchMethod("OnAddonLoaded", ...)
	end
end

Addon = CreateAddonObject(nil, Addon)
Addon:RegisterEvent("PLAYER_LOGIN")
Addon:RegisterEvent("ADDON_LOADED")
