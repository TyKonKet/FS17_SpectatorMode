--
-- SpectatorMode
--
-- @author TyKonKet
-- @date 20/01/2017

PlayerExtensions = {};

function PlayerExtensions:writeStream(streamId, connection)
    --local sm = g_spectatorMode;
    --if self.isOwner or (not connection:getIsServer() and connection ~= self.creatorConnection) then
    --    local x, y, z, w = getQuaternion(self.cameraNode);
    --    --sm:print(("playerWriteStream(streamId:%s, connection:%s)[%s]"):format(streamId, connection, self.controllerName));
    --    --sm:print(("x:%s, y:%s"):format(x, y));
    --    streamWriteFloat32(streamId, x);
    --    streamWriteFloat32(streamId, y);
    --    streamWriteFloat32(streamId, z);
    --    streamWriteFloat32(streamId, w);
    --end
    if not connection:getIsServer() and connection ~= self.creatorConnection then
        local x, y, z, w = getQuaternion(self.cameraNode);
        streamWriteFloat32(streamId, x);
        streamWriteFloat32(streamId, y);
        streamWriteFloat32(streamId, z);
        streamWriteFloat32(streamId, w);
    end
end

function PlayerExtensions:readStream(streamId, connection)
    --local sm = g_spectatorMode;
    --if not self.isOwner then
    --    local x = streamReadFloat32(streamId);
    --    local y = streamReadFloat32(streamId);
    --    local z = streamReadFloat32(streamId);
    --    local w = streamReadFloat32(streamId);
    --    --sm:print(("playerReadStream(streamId:%s, connection:%s)[%s]"):format(streamId, connection, self.controllerName));
    --    --sm:print(("x:%s, y:%s"):format(x, y));
    --    setQuaternion(self.cameraNode, x, y, z, w);
    --end
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
    --local sm = g_spectatorMode;
    if not connection:getIsServer() and connection ~= self.creatorConnection then
        local x, y, z, w = getQuaternion(self.cameraNode);
        --sm:print(("playerWriteUpdateStream(streamId:%s, connection:%s, dirtyMask:%s)[%s]"):format(streamId, connection, dirtyMask, self.controllerName));
        --sm:print(("x:%s, y:%s"):format(x, y));
        streamWriteFloat32(streamId, x);
        streamWriteFloat32(streamId, y);
        streamWriteFloat32(streamId, z);
        streamWriteFloat32(streamId, w);    
    end
end

function PlayerExtensions:readUpdateStream(streamId, timestamp, connection)
    --local sm = g_spectatorMode;
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
    --local sm = g_spectatorMode;
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
    elseif g_spectatorMode ~= nil then
        if self.controllerName == g_spectatorMode.spectatedPlayer then
            self:setVisibility(false);
        end
    end
end
