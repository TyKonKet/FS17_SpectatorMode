--
-- SpectatorMode
--
-- @author TyKonKet
-- @date 20/01/2017
PlayerExtensions = {};

function PlayerExtensions:writeStream(streamId, connection)
    if not connection:getIsServer() and connection ~= self.creatorConnection then
        local x, y, z, w = getQuaternion(self.cameraNode);
        streamWriteFloat32(streamId, x);
        streamWriteFloat32(streamId, y);
        streamWriteFloat32(streamId, z);
        streamWriteFloat32(streamId, w);
    end
end

function PlayerExtensions:readStream(streamId, connection)
    if not self.isOwner and connection:getIsServer() then
        self.lastQuaternion = {
            getQuaternion(self.cameraNode)
        };
        self.targetQuaternion = {
            streamReadFloat32(streamId),
            streamReadFloat32(streamId),
            streamReadFloat32(streamId),
            streamReadFloat32(streamId)
        };
        self.interpolationAlphaRot = 0;
    end
end

function PlayerExtensions:writeUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() and connection ~= self.creatorConnection then
        local x, y, z, w = getQuaternion(self.cameraNode);
        streamWriteFloat32(streamId, x);
        streamWriteFloat32(streamId, y);
        streamWriteFloat32(streamId, z);
        streamWriteFloat32(streamId, w);
    end
end

function PlayerExtensions:readUpdateStream(streamId, timestamp, connection)
    if not self.isOwner and connection:getIsServer() then
        self.lastQuaternion = {
            getQuaternion(self.cameraNode)
        };
        self.targetQuaternion = {
            streamReadFloat32(streamId),
            streamReadFloat32(streamId),
            streamReadFloat32(streamId),
            streamReadFloat32(streamId)
        };
        self.interpolationAlphaRot = 0;
    end
end

function PlayerExtensions:update(dt)
    if not self.isServer and self.isControlled and not self.isEntered then
        self.interpolationAlphaRot = self.interpolationAlphaRot + g_physicsDtUnclamped / 75;
        if self.interpolationAlphaRot > 1 then
            self.interpolationAlphaRot = 1;
        end
        local x, y, z, w = Utils.nlerpQuaternionShortestPath(self.lastQuaternion[1], self.lastQuaternion[2], self.lastQuaternion[3], self.lastQuaternion[4], self.targetQuaternion[1], self.targetQuaternion[2], self.targetQuaternion[3], self.targetQuaternion[4], self.interpolationAlphaRot);
        setQuaternion(self.cameraNode, x, y, z, w);
    end
end

function PlayerExtensions:onEnter(isOwner)
    if isOwner then
        Event.send(CameraChangeEvent:new(g_currentMission.player.controllerName, self.cameraNode, 0, CameraChangeEvent.CAMERA_TYPE_PLAYER));
        g_spectatorMode:print(string.format("Event.send(CameraChangeEvent:new(controllerName:%s, cameraNode:%s, camIndex:%s, cameraType:%s))", g_currentMission.player.controllerName, self.cameraNode, 0, CameraChangeEvent.CAMERA_TYPE_PLAYER));
    elseif g_spectatorMode ~= nil then
        if self.controllerName == g_spectatorMode.spectatedPlayer then
            self:setVisibility(false);
        end
    end
end
