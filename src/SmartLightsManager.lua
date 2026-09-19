-- =============================================================
-- FS25_AISmartLights: SmartLightsManager.lua
-- Author: exekx
-- Description: Battery Saver for RMS with Courseplay & AutoDrive.
--              Instant 0ms response, zero console spam.
-- =============================================================

SmartLightsManager = {}
SmartLightsManager.isInitialized = false

--- Checks if motorized vehicle is actively controlled by Courseplay or AutoDrive
function SmartLightsManager.isCPorADActive(vehicle)
    if vehicle == nil or vehicle.spec_motorized == nil then
        return false
    end

    -- 1. Check Courseplay
    local cpWorker = vehicle.spec_cpAIWorker
    if cpWorker ~= nil and cpWorker.isActive then
        return true
    end

    if vehicle.getIsCourseplayDriving ~= nil and vehicle:getIsCourseplayDriving() then
        return true
    end

    local cp = vehicle.cp
    if cp ~= nil and (cp.isDriving or cp.isActive) then
        return true
    end

    -- 2. Check AutoDrive
    local ad = vehicle.ad
    if ad ~= nil and ad.stateModule ~= nil and ad.stateModule:isActive() then
        return true
    end

    -- 3. Check generic AI if active (AutoDrive hooks getIsAIActive)
    if vehicle.getIsAIActive ~= nil and vehicle:getIsAIActive() then
        return true
    end

    -- 4. Check cached AI ownership flag
    if vehicle._smartLightsAIOwned ~= nil then
        return true
    end

    return false
end

--- Checks if current in-game environment is night or dark
function SmartLightsManager.isNightOrDark()
    if g_currentMission == nil or g_currentMission.environment == nil then
        return false
    end

    local env = g_currentMission.environment
    if env.lighting ~= nil and env.lighting.getIsNight ~= nil then
        return env.lighting:getIsNight()
    end

    local dayTimeMs = env.dayTime or 0
    local hour = dayTimeMs / (1000 * 60 * 60)
    if hour < 6.5 or hour >= 20.5 then
        return true
    end

    return false
end

--- Turns OFF lights instantly and silently
function SmartLightsManager.turnOffLights(vehicle)
    if vehicle == nil or vehicle.spec_motorized == nil or vehicle.spec_lights == nil then
        return
    end

    local specLights = vehicle.spec_lights
    local lightsMask = (vehicle.getLightsTypesMask ~= nil and vehicle:getLightsTypesMask()) or 0
    local beaconActive = specLights.beaconLightsActive or false
    local turnLightState = specLights.turnLightState or 0

    if lightsMask > 0 or beaconActive or turnLightState > 0 then
        vehicle._smartLightsSavedState = {
            mask = lightsMask,
            beacons = beaconActive,
            turnLights = turnLightState
        }

        if vehicle.setLightsTypesMask ~= nil and lightsMask > 0 then
            vehicle:setLightsTypesMask(0, true)
        end
        if vehicle.setBeaconLightsVisibility ~= nil and beaconActive then
            vehicle:setBeaconLightsVisibility(false, true)
        end
        if vehicle.setTurnLightState ~= nil and turnLightState > 0 then
            vehicle:setTurnLightState(0, true)
        end
    end
end

--- Restores lights instantly and silently when engine starts
function SmartLightsManager.restoreLights(vehicle)
    if vehicle == nil or vehicle.spec_motorized == nil or vehicle.spec_lights == nil then
        return
    end

    local saved = vehicle._smartLightsSavedState
    if saved ~= nil then
        vehicle._smartLightsSavedState = nil
        vehicle._smartLightsRestoring = true

        if saved.mask ~= nil and saved.mask > 0 and vehicle.setLightsTypesMask ~= nil then
            vehicle:setLightsTypesMask(saved.mask, true)
        end
        if saved.beacons and vehicle.setBeaconLightsVisibility ~= nil then
            vehicle:setBeaconLightsVisibility(true, true)
        end
        if saved.turnLights ~= nil and saved.turnLights > 0 and vehicle.setTurnLightState ~= nil then
            vehicle:setTurnLightState(saved.turnLights, true)
        end

        vehicle._smartLightsRestoring = nil
        vehicle._smartLightsAIOwned = nil
    else
        if SmartLightsManager.isNightOrDark() then
            if vehicle.setLightsTypesMask ~= nil and vehicle:getLightsTypesMask() == 0 then
                vehicle._smartLightsRestoring = true
                vehicle:setLightsTypesMask(1, true)
                vehicle._smartLightsRestoring = nil
            end
        end
        vehicle._smartLightsAIOwned = nil
    end
end

--- Hook vehicle methods for INSTANT 0ms reaction on motor start/stop
function SmartLightsManager.hookVehicle(vehicle)
    -- STRICT FILTER: Only hook motorized vehicles! NEVER touch trailers or implements!
    if vehicle == nil or vehicle.spec_motorized == nil or vehicle._smartLightsHooked then
        return
    end
    vehicle._smartLightsHooked = true

    -- 1. INSTANT Stop Motor Hook
    if vehicle.stopMotor ~= nil then
        vehicle.stopMotor = Utils.prependedFunction(vehicle.stopMotor, function(self, noEventSend)
            if SmartLightsManager.isCPorADActive(self) then
                self._smartLightsAIOwned = true
                SmartLightsManager.turnOffLights(self)
            end
        end)
    end

    -- 2. INSTANT Start Motor Hook
    if vehicle.startMotor ~= nil then
        vehicle.startMotor = Utils.appendedFunction(vehicle.startMotor, function(self, noEventSend)
            if SmartLightsManager.isCPorADActive(self) or self._smartLightsSavedState ~= nil then
                SmartLightsManager.restoreLights(self)
            end
        end)
    end

    -- 3. Intercept setLightsTypesMask: prevent game from turning on lights while engine is off
    if vehicle.setLightsTypesMask ~= nil then
        vehicle.setLightsTypesMask = Utils.overwrittenFunction(vehicle.setLightsTypesMask, function(self, superFunc, lightsTypesMask, force, noEventSend)
            -- If our own restoreLights is running, allow it through immediately!
            if self._smartLightsRestoring then
                return superFunc(self, lightsTypesMask, force, noEventSend)
            end

            local isAI = SmartLightsManager.isCPorADActive(self)
            local isStarted = self.getIsMotorStarted ~= nil and self:getIsMotorStarted()

            if isAI and not isStarted then
                if lightsTypesMask ~= nil and lightsTypesMask > 0 then
                    self._smartLightsSavedState = self._smartLightsSavedState or {}
                    self._smartLightsSavedState.mask = lightsTypesMask
                    return superFunc(self, 0, force, noEventSend)
                end
            end

            return superFunc(self, lightsTypesMask, force, noEventSend)
        end)
    end

    -- 4. Intercept setBeaconLightsVisibility
    if vehicle.setBeaconLightsVisibility ~= nil then
        vehicle.setBeaconLightsVisibility = Utils.overwrittenFunction(vehicle.setBeaconLightsVisibility, function(self, superFunc, visibility, force, noEventSend)
            if self._smartLightsRestoring then
                return superFunc(self, visibility, force, noEventSend)
            end

            local isAI = SmartLightsManager.isCPorADActive(self)
            local isStarted = self.getIsMotorStarted ~= nil and self:getIsMotorStarted()

            if isAI and not isStarted and visibility then
                if self._smartLightsSavedState then
                    self._smartLightsSavedState.beacons = true
                end
                return superFunc(self, false, force, noEventSend)
            end

            return superFunc(self, visibility, force, noEventSend)
        end)
    end
end

--- Frame-level instant detection loop (0ms latency, zero spam)
function SmartLightsManager.onUpdateTick(dt)
    if g_currentMission == nil then
        return
    end

    local isServer = g_server ~= nil or (g_currentMission.isServer ~= nil and g_currentMission.isServer)
    if not isServer then
        return
    end

    local vehicleList = nil
    if g_currentMission.vehicleSystem ~= nil and g_currentMission.vehicleSystem.vehicles ~= nil then
        vehicleList = g_currentMission.vehicleSystem.vehicles
    elseif g_currentMission.vehicles ~= nil then
        vehicleList = g_currentMission.vehicles
    end

    if vehicleList == nil then
        return
    end

    for _, vehicle in pairs(vehicleList) do
        -- Strictly process ONLY motorized vehicles!
        if vehicle ~= nil and vehicle.spec_motorized ~= nil and vehicle.getIsMotorStarted ~= nil and vehicle.spec_lights ~= nil then
            SmartLightsManager.hookVehicle(vehicle)

            local isAI = SmartLightsManager.isCPorADActive(vehicle)
            local isMotorStarted = vehicle:getIsMotorStarted()

            if isAI then
                vehicle._smartLightsAIOwned = true

                if not isMotorStarted then
                    local lightsMask = (vehicle.getLightsTypesMask ~= nil and vehicle:getLightsTypesMask()) or 0
                    local beaconActive = vehicle.spec_lights.beaconLightsActive or false
                    if lightsMask > 0 or beaconActive then
                        SmartLightsManager.turnOffLights(vehicle)
                    end
                else
                    if vehicle._smartLightsSavedState ~= nil then
                        SmartLightsManager.restoreLights(vehicle)
                    end
                end
            end
        end
    end
end

function SmartLightsManager.init()
    if SmartLightsManager.isInitialized then
        return
    end
    SmartLightsManager.isInitialized = true
end