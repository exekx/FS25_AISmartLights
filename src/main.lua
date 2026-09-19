-- =============================================================
-- FS25_AISmartLights: main.lua
-- Author: exekx
-- Description: Entry point for Smart Lights Addon (Battery Saver)
-- =============================================================

local modDirectory = g_currentModDirectory
local modName = g_currentModName

source(modDirectory .. "src/SmartLightsManager.lua")

local function onMissionLoaded(mission, node)
    if mission.cancelLoading then
        return
    end
    SmartLightsManager.init()
    print(string.format("FS25_AISmartLights: Loaded '%s' v1.0.0.0 (Author: exekx). Battery protection active.", modName))
end

local function onMissionUpdate(mission, dt)
    SmartLightsManager.onUpdateTick(dt)
end

-- Hook Mission Lifecycle
if Mission00 ~= nil then
    Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, onMissionLoaded)
    Mission00.update = Utils.appendedFunction(Mission00.update, onMissionUpdate)
elseif FSBaseMission ~= nil then
    FSBaseMission.onFinishedLoading = Utils.appendedFunction(FSBaseMission.onFinishedLoading, onMissionLoaded)
    FSBaseMission.update = Utils.appendedFunction(FSBaseMission.update, onMissionUpdate)
end