--
-- SpectatorMode
--
-- @author TyKonKet
-- @date 23/12/2016
SpectatorMode = {}
SpectatorMode_mt = Class(SpectatorMode)

function SpectatorMode:new(isServer, isClient, customMt)
    if SpectatorMode_mt == nil then
        SpectatorMode_mt = Class(SpectatorMode)
    end
    local mt = customMt
    if mt == nil then
        mt = SpectatorMode_mt
    end
    local self = {}
    setmetatable(self, mt)
    self.name = "SpectatorMode"
    self.spectating = false
    self.spectatedPlayer = nil
    self.spectatedVehicle = nil
    self.delayedCameraChangedDCB = DelayedCallBack:new(SpectatorMode.delayedCameraChanged, self)
    self.delayedCameraChangedDCB.skipOneFrame = true

    self.lastPlayer = {}
    self.lastPlayer.x = 0
    self.lastPlayer.y = 0
    self.lastPlayer.z = 0
    return self
end

function SpectatorMode:print(text, ...)
    if self.debug then
        local pre = "[A]"
        if self.spectating then
            pre = "[S]"
        end
        local start = string.format("%s[%s(%s)] -> ", self.name, getDate("%H:%M:%S"), pre)
        local ptext = string.format(text, ...)
        print(string.format("%s%s", start, ptext))
    end
end

function SpectatorMode:loadMap()
    self:print("loadMap()")
    self.guis.spectateGui:setSelectionCallback(self, self.startSpectate)
end

function SpectatorMode:update(dt)
    self.delayedCameraChangedDCB:update(dt)
    if self.lastCamera ~= getCamera() then
        self:print(("Camera setted to:%s"):format(getCamera()))
        self.lastCamera = getCamera()
    end
    if g_currentMission.controlledVehicle == nil then
        if self.spectating then
            g_currentMission:addHelpButtonText(g_i18n:getText("STOP_SPECTATOR_MODE"), InputBinding.TOGGLE_SPECTATOR_MODE)
            if InputBinding.hasEvent(InputBinding.TOGGLE_SPECTATOR_MODE, true) then
                self:stopSpectate()
            end
        else
            g_currentMission:addHelpButtonText(g_i18n:getText("START_SPECTATOR_MODE"), InputBinding.TOGGLE_SPECTATOR_MODE)
            if g_gui.currentGui == nil and InputBinding.hasEvent(InputBinding.TOGGLE_SPECTATOR_MODE, true) then
                self:showGui()
            end
        end
    end
end

function SpectatorMode:draw()
    if self.spectatedVehicle ~= nil then
        g_currentMission:drawVehicleHud(self.spectatedVehicle)
    end
end

function SpectatorMode:showGui()
    local spectableUsers = {}
    for k, p in pairs(g_currentMission.players) do
        if not p.isDedicatedServer and g_currentMission.player.controllerName ~= p.controllerName then
            table.insert(spectableUsers, p.controllerName)
        end
    end
    self.guis.spectateGui:setSpectableUsers(spectableUsers)
    g_gui:showGui("SpectateGui")
end

function SpectatorMode:startSpectate(playerName)
    g_currentMission.player.pickedUpObjectOverlay:setIsVisible(false)
    g_currentMission.isPlayerFrozen = true
    self.spectating = true
    self.spectatedPlayer = playerName
    self.spectatedPlayerObject = self:getPlayerByName(self.spectatedPlayer)
    self.spectatedPlayerObject:setWoodWorkVisibility(false, false)
    self.spectatedPlayerObject:setVisibility(false)
    g_currentMission.hasSpecialCamera = true
    Event.send(SpectateEvent:new(true, g_currentMission.player.controllerName, playerName))
end

function SpectatorMode:spectateRejected(reason)
    self:print(("spectateRejected(reason:%s)"):format(reason))
    self:stopSpectate()
    if reason == SpectateRejectedEvent.REASON_DEDICATED_SERVER then
        g_currentMission:showBlinkingWarning(g18n:getText("ERROR_SPCTATE_DEDICATED_SERVER"), 3000)
    elseif reason == SpectateRejectedEvent.REASON_YOURSELF then
        g_currentMission:showBlinkingWarning(g18n:getText("ERROR_SPCTATE_YOURSELF"), 3000)
    end
end

function SpectatorMode:stopSpectate()
    g_currentMission.hasSpecialCamera = false
    self:setVehicleActiveCamera(nil)
    self.spectatedVehicle = nil
    Event.send(SpectateEvent:new(false, g_currentMission.player.controllerName, self.spectatedPlayer))
    self.spectatedPlayerObject:setVisibility(true)
    self.spectatedPlayerObject:setWoodWorkVisibility(false, false)
    self.spectatedPlayerObject = nil
    self.spectatedPlayer = nil
    g_currentMission.player.pickedUpObjectOverlay:setIsVisible(true)
    g_currentMission.isPlayerFrozen = false
    self.spectating = false
end

function SpectatorMode:getPlayerByName(name)
    for _, v in pairs(g_currentMission.players) do
        if v.controllerName == name then
            return v
        end
    end
    return nil
end

function SpectatorMode:cameraChanged(actorName, cameraId, cameraIndex, cameraType)
    self:print(string.format("SpectatorMode:cameraChanged(actorName:%s, cameraId:%s, cameraIndex:%s, cameraType:%s)", actorName, cameraId, cameraIndex, cameraType))
    self.delayedCameraChangedDCB:call(1, actorName, cameraId, cameraIndex, cameraType)
end

function SpectatorMode:delayedCameraChanged(actorName, cameraId, cameraIndex, cameraType)
    self:print(string.format("SpectatorMode:cameraChanged(actorName:%s, cameraId:%s, cameraIndex:%s, cameraType:%s)", actorName, cameraId, cameraIndex, cameraType))
    if cameraType == CameraChangeEvent.CAMERA_TYPE_PLAYER then
        setCamera(self.spectatedPlayerObject.cameraNode)
        self:setVehicleActiveCamera(nil)
        self.spectatedVehicle = nil
    elseif cameraType == CameraChangeEvent.CAMERA_TYPE_VEHICLE then
        for _, v in pairs(g_currentMission.controlledVehicles) do
            if v.controllerName == actorName then
                setCamera(v.cameras[cameraIndex].cameraNode)
                self:print(string.format("setCamera(v.cameras[cameraIndex].cameraNode:%s))", v.cameras[cameraIndex].cameraNode))
                v.vehicleCharacter:setCharacterVisibility(true)
                self.spectatedVehicle = v
                self:setVehicleActiveCamera(cameraIndex)
            end
        end
    elseif cameraType == CameraChangeEvent.CAMERA_TYPE_VEHICLE_INDOOR then
        for _, v in pairs(g_currentMission.controlledVehicles) do
            if v.controllerName == actorName then
                setCamera(v.cameras[cameraIndex].cameraNode)
                self:print(string.format("setCamera(v.cameras[cameraIndex].cameraNode:%s))", v.cameras[cameraIndex].cameraNode))
                v.vehicleCharacter:setCharacterVisibility(false)
                self.spectatedVehicle = v
                self:setVehicleActiveCamera(cameraIndex)
            end
        end
    end
end

function SpectatorMode:setVehicleActiveCamera(cameraIndex)
    self:print(string.format("SpectatorMode:setVehicleActiveCamera(cameraIndex:%s)", cameraIndex))
    if self.spectatedVehicle ~= nil then
        local useMirror = false
        if cameraIndex ~= nil then
            self.spectatedVehicle:setActiveCameraIndex(cameraIndex)
            useMirror = self.spectatedVehicle.activeCamera.useMirror
        end
        if self.spectatedVehicle.setMirrorVisible ~= nil then
            self.spectatedVehicle:setMirrorVisible(useMirror)
        end
    end
end

function SpectatorMode:determinePlayerPosition(player)
    if not g_spectatorMode.spectating or player ~= g_currentMission.player then
        return player:getPositionData()
    else
        return g_spectatorMode.spectatedPlayerObject:getPositionData()
    end
end

function SpectatorMode:updatePlayerPosition()
    local playerPosX, playerPosY, playerPosZ
    if not g_spectatorMode.spectating then
        if g_gui.currentGuiName == "PlacementScreen" then
            playerPosX, playerPosY, playerPosZ, self.playerRotation = g_placementScreen:determineCameraPosition()
        elseif g_currentMission.controlPlayer then
            if g_currentMission.player ~= nil then
                playerPosX, playerPosY, playerPosZ, self.playerRotation = self:determinePlayerPosition(g_currentMission.player)
            end
        elseif g_currentMission.controlledVehicle ~= nil then
            playerPosX, playerPosY, playerPosZ, self.playerRotation = self:determineVehiclePosition(g_currentMission.controlledVehicle)
        end
    else
        if g_gui.currentGuiName == "PlacementScreen" then
            playerPosX, playerPosY, playerPosZ, self.playerRotation = g_placementScreen:determineCameraPosition()
        elseif g_spectatorMode.spectatedVehicle ~= nil then
            playerPosX, playerPosY, playerPosZ, self.playerRotation = self:determineVehiclePosition(g_spectatorMode.spectatedVehicle)
        else
            playerPosX, playerPosY, playerPosZ, self.playerRotation = self:determinePlayerPosition(g_spectatorMode.spectatedPlayerObject)
        end
    end
    self.normalizedPlayerPosX = Utils.clamp((math.floor(playerPosX) + self.worldCenterOffsetX) / self.worldSizeX, 0, 1)
    self.normalizedPlayerPosZ = Utils.clamp((math.floor(playerPosZ) + self.worldCenterOffsetZ) / self.worldSizeZ, 0, 1)
end

function SpectatorMode:requestToEnterVehicle(superFunc, vehicle)
    if not g_spectatorMode.spectating then
        if superFunc ~= nil then
            superFunc()
        end
    end
end
