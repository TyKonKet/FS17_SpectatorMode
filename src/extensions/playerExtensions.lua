--
-- SpectatorMode
--
-- @author TyKonKet
-- @date 20/01/2017
PlayerExtensions = {}

function PlayerExtensions:writeStream(streamId, connection)
    if not connection:getIsServer() and connection ~= self.creatorConnection then
        local x, y, z, w = getQuaternion(self.cameraNode)
        streamWriteFloat32(streamId, x)
        streamWriteFloat32(streamId, y)
        streamWriteFloat32(streamId, z)
        streamWriteFloat32(streamId, w)
        streamWriteFloat32(streamId, self.camY)
        streamWriteUInt8(streamId, getFovy(self.cameraNode))
        streamWriteBool(streamId, g_dedicatedServerInfo and g_currentMission.player.controllerName == self.controllerName)
    end
end

function PlayerExtensions:readStream(streamId, connection)
    if not self.isOwner and connection:getIsServer() then
        self.lastQuaternion = {
            getQuaternion(self.cameraNode)
        }
        self.targetQuaternion = {
            streamReadFloat32(streamId),
            streamReadFloat32(streamId),
            streamReadFloat32(streamId),
            streamReadFloat32(streamId)
        }
        self.interpolationAlphaRot = 0
        self.camY = streamReadFloat32(streamId)
        setFovy(self.cameraNode, streamReadUInt8(streamId))
        self.isDedicatedServer = streamReadBool(streamId)
    end
end

function PlayerExtensions:writeUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() and connection ~= self.creatorConnection then
        local x, y, z, w = getQuaternion(self.cameraNode)
        streamWriteFloat32(streamId, x)
        streamWriteFloat32(streamId, y)
        streamWriteFloat32(streamId, z)
        streamWriteFloat32(streamId, w)
        streamWriteFloat32(streamId, self.camY)
        streamWriteUInt8(streamId, getFovy(self.cameraNode))
    elseif self.isOwner and connection:getIsServer() then
        streamWriteFloat32(streamId, self.camY)
        streamWriteUInt8(streamId, getFovy(self.cameraNode))
    end
end

function PlayerExtensions:readUpdateStream(streamId, timestamp, connection)
    if not self.isOwner and connection:getIsServer() then
        self.lastQuaternion = {
            getQuaternion(self.cameraNode)
        }
        self.targetQuaternion = {
            streamReadFloat32(streamId),
            streamReadFloat32(streamId),
            streamReadFloat32(streamId),
            streamReadFloat32(streamId)
        }
        self.interpolationAlphaRot = 0
        local cx, _, cz = getTranslation(self.cameraNode)
        setTranslation(self.cameraNode, cx, streamReadFloat32(streamId), cz)
        setFovy(self.cameraNode, streamReadUInt8(streamId))
    elseif not self.isOwner and not connection:getIsServer() then
        self.camY = streamReadFloat32(streamId)
        setFovy(self.cameraNode, streamReadUInt8(streamId))
    end
end

function PlayerExtensions:update(dt)
    if not self.isServer and self.isControlled and not self.isEntered then
        self.interpolationAlphaRot = self.interpolationAlphaRot + g_physicsDtUnclamped / 75
        if self.interpolationAlphaRot > 1 then
            self.interpolationAlphaRot = 1
        end
        local x, y, z, w = Utils.nlerpQuaternionShortestPath(self.lastQuaternion[1], self.lastQuaternion[2], self.lastQuaternion[3], self.lastQuaternion[4], self.targetQuaternion[1], self.targetQuaternion[2], self.targetQuaternion[3], self.targetQuaternion[4], self.interpolationAlphaRot)
        setQuaternion(self.cameraNode, x, y, z, w)
    end
end

function PlayerExtensions:onEnter(isOwner)
    if isOwner then
        if not g_spectatorMode.spectating then
            Event.sendToServer(CameraChangeEvent:new(g_currentMission.player.controllerName, self.cameraNode, 0, CameraChangeEvent.CAMERA_TYPE_PLAYER))
            g_spectatorMode:print("Event.sendToServer(CameraChangeEvent:new(controllerName:%s, cameraNode:%s, camIndex:%s, cameraType:%s))", g_currentMission.player.controllerName, self.cameraNode, 0, CameraChangeEvent.CAMERA_TYPE_PLAYER)
        end
    elseif g_spectatorMode ~= nil then
        if self.controllerName == g_spectatorMode.spectatedPlayer then
            self:setVisibility(false)
        end
    end
end

function PlayerExtensions:drawUIInfo()
    local spectated = self.isSpectated ~= nil
    if spectated then
        spectated = self:isSpectated()
    end
    if not spectated then
        if self.isClient and self.isControlled and not self.isEntered then
            if not g_gui:getIsGuiVisible() and g_currentMission.showHudEnv then
                local x, y, z = getTranslation(self.graphicsRootNode)
                local x1, y1, z1 = getWorldTranslation(getCamera())
                local diffX = x - x1
                local diffY = y - y1
                local diffZ = z - z1
                local dist = Utils.vector3LengthSq(diffX, diffY, diffZ)
                if dist <= 100 * 100 then
                    y = y + self.playerTagYOffset
                    Utils.renderTextAtWorldPosition(x, y, z, self.controllerName, getCorrectTextSize(0.02), 0)
                end
            end
        end
    end
end

function PlayerExtensions:isSpectated()
    if g_spectatorMode ~= nil then
        if g_spectatorMode.spectating and self.controllerName == g_spectatorMode.spectatedPlayer then
            return true
        end
    end
    return false
end
