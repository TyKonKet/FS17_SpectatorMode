--
-- SpectatorMode
--
-- @author TyKonKet
-- @date 20/01/2017
-- TODO: rewrite this, improve smoothing following Player.lua
PlayerExtensions = {}

function PlayerExtensions:writeStream(streamId, connection)
    if not connection:getIsServer() and connection ~= self.creatorConnection then
        --local x, y, z, w = getQuaternion(self.cameraNode)
        --streamWriteFloat32(streamId, x)
        --streamWriteFloat32(streamId, y)
        --streamWriteFloat32(streamId, z)
        --streamWriteFloat32(streamId, w)
        --streamWriteFloat32(streamId, self.camY)
        --streamWriteUInt8(streamId, getFovy(self.cameraNode))
        local isDedicatedServer = g_dedicatedServerInfo and g_currentMission.player.controllerName == self.controllerName
        streamWriteBool(streamId, isDedicatedServer == true)
    end
end

function PlayerExtensions:readStream(streamId, connection)
    if not self.isOwner and connection:getIsServer() then
        --self.lastQuaternion = {
        --    getQuaternion(self.cameraNode)
        --}
        --self.targetQuaternion = {
        --    streamReadFloat32(streamId),
        --    streamReadFloat32(streamId),
        --    streamReadFloat32(streamId),
        --    streamReadFloat32(streamId)
        --}
        --self.interpolationAlpha = 0
        --self.camY = streamReadFloat32(streamId)
        --setFovy(self.cameraNode, streamReadUInt8(streamId))
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
        self.interpolationAlpha = 0
        if self.skipNextInterpolationAlpha then
            self.interpolationAlpha = 1
            self.skipNextInterpolationAlpha = false
        end
        local cx, _, cz = getTranslation(self.cameraNode)
        setTranslation(self.cameraNode, cx, streamReadFloat32(streamId), cz)
        setFovy(self.cameraNode, streamReadUInt8(streamId))
    elseif not self.isOwner and not connection:getIsServer() then
        self.camY = streamReadFloat32(streamId)
        setFovy(self.cameraNode, streamReadUInt8(streamId))
    end
end

function PlayerExtensions:update(dt)
    if not self.isServer and not self.isEntered then
        self.interpolationAlpha = self.interpolationAlpha + g_physicsDtUnclamped / 75
        if self.interpolationAlpha > 1.2 then
            self.interpolationAlpha = 1.2
        end
        local x, y, z, w = Utils.nlerpQuaternionShortestPath(self.lastQuaternion[1], self.lastQuaternion[2], self.lastQuaternion[3], self.lastQuaternion[4], self.targetQuaternion[1], self.targetQuaternion[2], self.targetQuaternion[3], self.targetQuaternion[4], self.interpolationAlpha)
        setQuaternion(self.cameraNode, x, y, z, w)
    end
end

function PlayerExtensions:onEnter(isOwner)
    if isOwner then
        if not g_spectatorMode.spectating then
            g_spectatorMode:print("Player.send(CameraChangeEvent:new(controllerName:%s, cameraNode:%s, camIndex:%s, cameraType:%s, toServer:true))", g_currentMission.player.controllerName, self.cameraNode, 0, CameraChangeEvent.CAMERA_TYPE_PLAYER)
            Event.sendToServer(CameraChangeEvent:new(g_currentMission.player.controllerName, self.cameraNode, 0, CameraChangeEvent.CAMERA_TYPE_PLAYER, true))
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
