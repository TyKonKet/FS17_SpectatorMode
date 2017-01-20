--
-- SpectatorMode script
--
--
-- @author TyKonKet
-- @date 20/01/2017

PlayerExtensions = {};

function PlayerExtensions:playerWriteStream(streamId, connection)
    --local sm = g_spectatorMode;
    if self.isOwner or (not connection:getIsServer() and connection ~= self.creatorConnection) then
        local x, y, z, w = getQuaternion(self.cameraNode);
        --sm:print(("playerWriteStream(streamId:%s, connection:%s)[%s]"):format(streamId, connection, self.controllerName));
        --sm:print(("x:%s, y:%s"):format(x, y));
        streamWriteFloat32(streamId, x);
        streamWriteFloat32(streamId, y);
        streamWriteFloat32(streamId, z);
        streamWriteFloat32(streamId, w);
    end
end

function PlayerExtensions:playerReadStream(streamId, connection)
    --local sm = g_spectatorMode;
    if not self.isOwner then
        local x = streamReadFloat32(streamId);
        local y = streamReadFloat32(streamId);
        local z = streamReadFloat32(streamId);
        local w = streamReadFloat32(streamId);
        --sm:print(("playerReadStream(streamId:%s, connection:%s)[%s]"):format(streamId, connection, self.controllerName));
        --sm:print(("x:%s, y:%s"):format(x, y));
        setQuaternion(self.cameraNode, x, y, z, w);
    end
end

function PlayerExtensions:playerWriteUpdateStream(streamId, connection, dirtyMask)
    --local sm = g_spectatorMode;
    if self.isOwner or (not connection:getIsServer() and connection ~= self.creatorConnection) then
        local x, y, z, w = getQuaternion(self.cameraNode);
        --sm:print(("playerWriteUpdateStream(streamId:%s, connection:%s, dirtyMask:%s)[%s]"):format(streamId, connection, dirtyMask, self.controllerName));
        --sm:print(("x:%s, y:%s"):format(x, y));
        streamWriteFloat32(streamId, x);
        streamWriteFloat32(streamId, y);
        streamWriteFloat32(streamId, z);
        streamWriteFloat32(streamId, w);    
    end
end

function PlayerExtensions:playerReadUpdateStream(streamId, timestamp, connection)
    --local sm = g_spectatorMode;
    if not self.isOwner then
        local x = streamReadFloat32(streamId);
        local y = streamReadFloat32(streamId);
        local z = streamReadFloat32(streamId);
        local w = streamReadFloat32(streamId);
        --sm:print(("playerReadUpdateStream(streamId:%s, timestamp:%s, connection:%s)[%s]"):format(streamId, timestamp, connection, self.controllerName));
        --sm:print(("x:%s, y:%s"):format(x, y));
        setQuaternion(self.cameraNode, x, y, z, w);
    end
end