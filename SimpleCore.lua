local AddonName, Addon = ...
local AddonFrame = CreateFrame("Frame", AddonName .. "AddonFrame", UIParent)

local AddonObject = {}
local DebugEnabled = false
local EventHandlers = {}
local MessageHandlers = {}
local Timers = {}
local Modules = {}

local PRINTHEADER = "|cff33ff99" .. AddonName .. "|r: "
local DEBUGHEADER = "|cff33ff99" .. AddonName .. "|cfffffb00" .. "(DEBUG)" .. "|r: "

---------------------------------------
-- Utility Functions
---------------------------------------
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

local function Printf(header, ...)
	if select("#", ...) > 1 then
		local success, txt = pcall(string.format, ...)

	    if success then
	        print(header .. txt)
	    else
	    	if DebugEnabled then --INFO: We will only make it here if a nil value was passed so only show if debug mode is enabled　
	        	print(DEBUGHEADER .. string.gsub(txt, "'%?'", string.format("'%s'", "Printf")))
	        end
	    end
	else
		local txt = ...

		if txt then
			print(header .. txt)
		else
			print(DEBUGHEADER .. "Nil value was passed to Printf!")
		end
	end
end

function AddonObject:Print(...)
	--INFO: If this is a module calling Print use its header instead
	if self ~= Addon then
		Printf(self.printHeader, ...)
	else
		Printf(PRINTHEADER, ...)
	end
end

function Addon:SetHeaders(printHeader, debugHeader)
	if printHeader then
		PRINTHEADER = printHeader
	end

	if debugHeader then
		DEBUGHEADER = debugHeader
	end
end

---------------------------------------
-- Debug Functions
---------------------------------------
function AddonObject:DebugPrint(...)
	if DebugEnabled == true then
		if self.debugHeader then
			Printf(self.debugHeader, ...)
		else
			Printf(DEBUGHEADER, ...)
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
AddonFrame:SetScript("OnUpdate", function(self, elapsed)
	for _, timer in pairs(Timers) do
		timer.totalTimeElapsed = timer.totalTimeElapsed + elapsed

		if timer.totalTimeElapsed > timer.delay then
			timer.object[timer.func](timer.object, elapsed, timer.name)

			if timer.repeating then
				timer.totalTimeElapsed = 0
			else
				--INFO: If this is a non-repeating timer remove it from Timers
				timer.object:StopTimer(timer.name)
			end
		end
	end
end)

function AddonObject:StartTimer(delay, func, repeating, name)
	local timer = {}
	local name = name or tostring(timer) -- NOTE: If you are going to create more than one timer you should really name it

	timer.object = self
	timer.delay = delay or 60
	timer.repeating = true
	timer.totalTimeElapsed = 0
	timer.func = func or "OnTimer"
	timer.name = name

	if repeating == nil then
		timer.repeating = true
	else
		timer.repeating = repeating
	end

	Timers[name] = timer
	AddonFrame:Show()

	return name
end

function AddonObject:StopTimer(name)
	if Timers[name] then
		DispatchMethod("OnTimerStop", name)
		Timers[name] = nil
	end
end

function AddonObject:StopAllTimers()
	--TODO: Dispatch calls to stop functions
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
function Addon:NewModule(name, defaults)
	local obj
	local defaults = defaults or {
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
Addon:RegisterEvent("ADDON_LOADED")
