--
-- SpectatorMode
--
-- @author TyKonKet
-- @date 23/12/2016
SpectatorMode = {}
SpectatorMode_mt = Class(SpectatorMode)

SpectatorMode.modDirectory = g_currentModDirectory

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
    self.spectated = false
    self.spectatedPlayer = nil
    self.spectatedPlayerIndex = 1
    self.spectatedVehicle = nil
    self.delayedCameraChangedDCB = DelayedCallBack:new(SpectatorMode.delayedCameraChanged, self)
    self.delayedCameraChangedDCB.skipOneFrame = true
    self.delayedStopSpectateDCB = DelayedCallBack:new(SpectatorMode.delayedStopSpectate, self)

    -- hud
    local uiScale = g_gameSettings:getValue("uiScale")
    self.spectatedOverlayWidth, self.spectatedOverlayHeight = getNormalizedScreenValues(24 * uiScale, 24 * uiScale)
    local _, margin = getNormalizedScreenValues(0, 1 * uiScale)
    self.spectatedOverlay = Overlay:new("spectatedOverlay", Utils.getFilename("huds/spectated.dds", SpectatorMode.modDirectory), 0 + margin, 1 - self.spectatedOverlayHeight - margin, self.spectatedOverlayWidth, self.spectatedOverlayHeight)

    self.spectateFadeEffectOffsetX, self.spectateFadeEffectOffsetY = getNormalizedScreenValues(3 * uiScale, -3 * uiScale)
    _, self.spectateFadeEffectSize = getNormalizedScreenValues(0, 24 * uiScale)
    self.spectateFadeEffect = FadeEffect:new({position = {x = 0.5, y = g_safeFrameOffsetY}, size = self.spectateFadeEffectSize, shadow = true, shadowPosition = {x = self.spectateFadeEffectOffsetX, y = self.spectateFadeEffectOffsetY}})

    self.lastPlayer = {}
    self.lastPlayer.mmState = 0
    self.lastPlayer.lightNode = 0
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
end

function SpectatorMode:deleteMap()
    self.spectatedOverlay:delete()
end

function SpectatorMode:update(dt)
    self.spectateFadeEffect:update(dt)
    self.delayedCameraChangedDCB:update(dt)
    self.delayedStopSpectateDCB:update(dt)
    if self.debug and self.lastCamera ~= getCamera() then
        self:print("updateCameraChanged(from:%s to:%s)", self.lastCamera, getCamera())
        self.lastCamera = getCamera()
    end
    if g_currentMission.controlledVehicle == nil then
        if self.spectating then
            g_currentMission:addHelpButtonText(g_i18n:getText("SM_STOP"), InputBinding.SM_TOGGLE)
            g_currentMission:addHelpButtonText(string.format(g_i18n:getText("SM_SWITCH_ACTOR_NEXT"), self:getSpectableUsers()[self:getNextPlayerIndex()]), InputBinding.SM_SWITCH_ACTOR_NEXT)
            g_currentMission:addHelpButtonText(string.format(g_i18n:getText("SM_SWITCH_ACTOR_PREVIOUS"), self:getSpectableUsers()[self:getPreviousPlayerIndex()]), InputBinding.SM_SWITCH_ACTOR_PREVIOUS)
            if g_gui.currentGui == nil then
                if InputBinding.hasEvent(InputBinding.SM_TOGGLE, true) then
                    self:stopSpectate()
                end
                if InputBinding.hasEvent(InputBinding.SM_SWITCH_ACTOR_NEXT, true) then
                    self:stopSpectate()
                    self:startSpectate(self:getNextPlayerIndex())
                end
                if InputBinding.hasEvent(InputBinding.SM_SWITCH_ACTOR_PREVIOUS, true) then
                    self:stopSpectate()
                    self:startSpectate(self:getPreviousPlayerIndex())
                end
                for i = 1, #self:getSpectableUsers() do
                    if InputBinding.hasEvent(InputBinding[string.format("SM_SWITCH_ACTOR_%s", i)], true) then
                        self:stopSpectate()
                        self:startSpectate(i)
                    end
                end
            end
        else
            g_currentMission:addHelpButtonText(g_i18n:getText("SM_START"), InputBinding.SM_TOGGLE)
            if g_gui.currentGui == nil and InputBinding.hasEvent(InputBinding.SM_TOGGLE, true) then
                self:showGui()
            end
        end
    end
end

function SpectatorMode:draw()
    self.spectateFadeEffect:draw()
    if self.spectatedVehicle ~= nil then
        if self.spectatedVehicle.isDrivable then
            g_currentMission:drawVehicleHud(self.spectatedVehicle)
            -- TODO: Not Working
            g_currentMission:drawHudIcon()
            g_currentMission:drawVehicleSchemaOverlay(self.spectatedVehicle)
        end
    end
    if self.spectated then
        self.spectatedOverlay:render()
    end
end

function SpectatorMode:showGui()
    self.guis.spectateGui:setSpectableUsers(self:getSpectableUsers())
    g_gui:showGui("SpectateGui")
end

function SpectatorMode:getSpectableUsers()
    local spectableUsers = {}
    for k, p in pairs(g_currentMission.players) do
        if not p.isDedicatedServer and g_currentMission.player.controllerName ~= p.controllerName then
            table.insert(spectableUsers, p.controllerName)
        end
    end
    return spectableUsers
end

function SpectatorMode:getNextPlayerIndex()
    if self.spectatedPlayerIndex == #self:getSpectableUsers() then
        return 1
    else
        return self.spectatedPlayerIndex + 1
    end
end

function SpectatorMode:getPreviousPlayerIndex()
    if self.spectatedPlayerIndex == 1 then
        return #self:getSpectableUsers()
    else
        return self.spectatedPlayerIndex - 1
    end
end

function SpectatorMode:startSpectate(playerIndex)
    g_currentMission.player.pickedUpObjectOverlay:setIsVisible(false)
    g_currentMission.isPlayerFrozen = true
    -- disable ability to toggle player light
    self.lastPlayer.lightNode = g_currentMission.player.lightNode
    g_currentMission.player.lightNode = nil
    self.spectating = true
    self.spectatedPlayer = self:getSpectableUsers()[playerIndex]
    self.spectatedPlayerIndex = playerIndex
    self.spectatedPlayerObject = g_currentMission:getPlayerByName(self.spectatedPlayer)
    self.spectatedPlayerObject:setWoodWorkVisibility(false, false)
    self.spectatedPlayerObject:setVisibility(false)
    g_currentMission.hasSpecialCamera = true
    self:print("Event.send(SpectateEvent:new(start:true, spectatorName:%s, actorName:%s))", g_currentMission.player.controllerName, self.spectatedPlayer)
    Event.sendToServer(SpectateEvent:new(true, g_currentMission.player.controllerName, self.spectatedPlayer))
    self.lastPlayer.mmState = g_currentMission.ingameMap.state
    self.spectateFadeEffect:play(self.spectatedPlayer)
end

function SpectatorMode:spectateRejected(reason)
    self:print(("spectateRejected(reason:%s)"):format(reason))
    self:stopSpectate()
    if reason == SpectateRejectedEvent.REASON_DEDICATED_SERVER then
        g_currentMission:showBlinkingWarning(g18n:getText("SM_ERROR_SPCTATE_DEDICATED_SERVER"), 3000)
    elseif reason == SpectateRejectedEvent.REASON_YOURSELF then
        g_currentMission:showBlinkingWarning(g18n:getText("SM_ERROR_SPCTATE_YOURSELF"), 3000)
    end
end

function SpectatorMode:stopSpectate(disconnect)
    g_currentMission.ingameMap:toggleSize(self.lastPlayer.mmState, true)
    g_currentMission.hasSpecialCamera = false
    self:setVehicleActiveCamera(nil)
    self:print("Event.send(SpectateEvent:new(start:false, spectatorName:%s, actorName:%s))", g_currentMission.player.controllerName, self.spectatedPlayer)
    Event.sendToServer(SpectateEvent:new(false, g_currentMission.player.controllerName, self.spectatedPlayer))
    if not disconnect then
        self.delayedStopSpectateDCB:call(100, self.spectatedPlayerObject, self.spectatedVehicle)
    end
    self.spectatedPlayerObject = nil
    self.spectatedPlayer = nil
    self.spectatedVehicle = nil
    g_currentMission.player.pickedUpObjectOverlay:setIsVisible(true)
    g_currentMission.isPlayerFrozen = false
    -- enable ability to toggle player light
    g_currentMission.player.lightNode = self.lastPlayer.lightNode
    self.spectating = false
end

function SpectatorMode:delayedStopSpectate(spectatedPlayerObject, spectatedVehicle)
    if spectatedPlayerObject ~= self.spectatedPlayerObject then
        spectatedPlayerObject:setVisibility(true)
        spectatedPlayerObject:setWoodWorkVisibility(false, false)
    end
    if spectatedVehicle ~= nil and spectatedVehicle ~= self.spectatedVehicle then
        spectatedVehicle.vehicleCharacter:setCharacterVisibility(true)
    end
end

function SpectatorMode:cameraChanged(actorName, cameraId, cameraIndex, cameraType)
    self:print(string.format("cameraChanged(actorName:%s, cameraId:%s, cameraIndex:%s, cameraType:%s)", actorName, cameraId, cameraIndex, cameraType))
    if cameraType == CameraChangeEvent.CAMERA_TYPE_PLAYER then
        self.delayedCameraChangedDCB:call(20, actorName, cameraId, cameraIndex, cameraType)
    else
        self:delayedCameraChanged(actorName, cameraId, cameraIndex, cameraType)
    end
end

function SpectatorMode:delayedCameraChanged(actorName, cameraId, cameraIndex, cameraType)
    self:print(string.format("delayedCameraChanged(actorName:%s, cameraId:%s, cameraIndex:%s, cameraType:%s)", actorName, cameraId, cameraIndex, cameraType))
    if cameraType == CameraChangeEvent.CAMERA_TYPE_PLAYER then
        setCamera(self.spectatedPlayerObject.cameraNode)
        self:setVehicleActiveCamera(nil)
        self.spectatedVehicle = nil
        self.spectatedPlayerObject.skipNextInterpolationAlpha = true
        self.spectatedPlayerObject.interpolationAlpha = 1
    elseif cameraType == CameraChangeEvent.CAMERA_TYPE_VEHICLE then
        for _, v in pairs(g_currentMission.controlledVehicles) do
            if v.controllerName == actorName then
                setCamera(v.cameras[cameraIndex].cameraNode)
                v.vehicleCharacter:setCharacterVisibility(true)
                self.spectatedVehicle = v
                self:setVehicleActiveCamera(cameraIndex)
                v.camerasLerp[v.cameras[cameraIndex].cameraNode].skipNextInterpolationAlpha = true
                v.camerasLerp[v.cameras[cameraIndex].cameraNode].interpolationAlpha = 1
            end
        end
    elseif cameraType == CameraChangeEvent.CAMERA_TYPE_VEHICLE_INDOOR then
        for _, v in pairs(g_currentMission.controlledVehicles) do
            if v.controllerName == actorName then
                setCamera(v.cameras[cameraIndex].cameraNode)
                v.vehicleCharacter:setCharacterVisibility(false)
                self.spectatedVehicle = v
                self:setVehicleActiveCamera(cameraIndex)
                v.camerasLerp[v.cameras[cameraIndex].cameraNode].skipNextInterpolationAlpha = true
                v.camerasLerp[v.cameras[cameraIndex].cameraNode].interpolationAlpha = 1
            end
        end
    end
end

function SpectatorMode:setVehicleActiveCamera(cameraIndex)
    --self:print(string.format("setVehicleActiveCamera(cameraIndex:%s)", cameraIndex))
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

function SpectatorMode:toggleSize(superFunc, state, force, noEventSend)
    --g_spectatorMode:print("toggleSize(state:%s, force:%s, noEventSend:%s)", state, force, noEventSend)
    if superFunc ~= nil then
        superFunc(self, state, force)
    end
    if not noEventSend then
        g_spectatorMode:print("Event.send(MinimapChangeEvent:new(controllerName:%s, state:%s, toServer:true))", g_currentMission.player.controllerName, self.state)
        Event.sendToServer(MinimapChangeEvent:new(g_currentMission.player.controllerName, self.state, true))
    end
end

function SpectatorMode:minimapChange(aName, mmState)
    self:print("minimapChange(aName:%s, state:%s)", aName, mmState)
    g_currentMission.ingameMap:toggleSize(mmState, true, true)
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
            superFunc(self, vehicle)
        end
    end
end

function SpectatorMode:onUserEvent()
    -- check left user
    for _, oldUser in pairs(self.usersOld) do
        local found = false
        for _, user in pairs(self.users) do
            if oldUser.userId == user.userId then
                found = true
                break
            end
        end
        if not found and oldUser.userId ~= self:getServerUserId() and oldUser.userId ~= self.playerUserId then
            if g_spectatorMode.spectating and oldUser.nickname == g_spectatorMode.spectatedPlayer then
                g_spectatorMode:stopSpectate(true)
            end
        end
    end
end
