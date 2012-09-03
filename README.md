# SimpleCore

SimpleCore is a framework for creating addons. Similar to Ace but with less features.

## Feature Overview

- Slash commands
- A simple timer
- Modules
- Saved variable support(though no profile management)
- Event Registration
- Print and DebugPrint as well

## A Few Examples

### Hello World:

```lua
local AddonName, Addon = ...

function Addon:OnSlashCommand(...)
	local msg = ...
	
	self:Print(msg)
end
```

Once you define OnSlashCommand SimpleCore will automatically create a slash command based on your addon's name. So by executing /myaddonname Hello World! your addon will print:
> Hello World!

### A Simple Timer:

```lua
local AddonName, Addon = ...

function Addon:OnInitialize()
	self:StartTimer(60)
end

function Addon:OnTimer()
	self:DebugPrint("Hello again from OnTimer")
end
```

### Events:

```lua
local AddonName, Addon = ...

function Addon:OnInitialize()
	self:RegisterEvent({"ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED_INDOORS" }, "OnZoneChanged")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("MINIMAP_PING", "OnMiniMapPing")
end

function Addon:OnZoneChanged(event)
	self:DebugPrint("Changed zone to: %s", GetZoneText())
end

function Addon:PLAYER_TARGET_CHANGED(event)
	self:DebugPrint(event)
end

function Addon:OnMiniMapPing(event, unit, x, y)
	self:DebugPrint("Your coordinates sir: Unit: %s X: %f Y: %f", unit, x, y)
end

```

More examples code can be found in Tests.lua.
