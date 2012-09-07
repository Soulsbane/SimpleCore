# SimpleCore

SimpleCore is a framework for creating World of Warcraft addons.

## Feature Overview

- Slash commands
- Timer creation made easy
- Modules
- Saved variable support(though no profile management)
- Event Registration
- Print and DebugPrint as well

## Getting Started

1. Add SimpleCore.lua to your addon's toc file making sure it is at the top of the list.

```lua
## Interface: 50001
## Title: MyAddon
## Notes: This is my addon
## Author: Me
## Version: 1.0
## SavedVariables: SimpleCoreDB
SimpleCore.lua
MyAddon.lua
```
2. Now we need to pull Addon object so we can access all of SimpleCore's features. We'll do this by adding the following to MyAddon.lua:

```lua
local AddonName, Addon = ...
```
3. It's time for "Hello World!":

```lua
local AddonName, Addon = ...

function Addon:OnSlashCommand(...)
    local msg = ...

	self:Print(msg)
end
```
4. Once you've added the above code SimpleCore will automatically create a slash command based on your addon's name. Once you execute /myaddonname Hello World! your addon will print:

> Hello World!

## A Few Examples

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

More examples code can be found in [Tests.lua](https://github.com/Soulsbane/SimpleCore/blob/master/Tests.lua).
