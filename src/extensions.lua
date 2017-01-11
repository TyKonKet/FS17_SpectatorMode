--
-- SpectatorMode script
--
--
-- @author TyKonKet
-- @date 03/01/2017


-- Event methods extension
function Event.send(event, dontSendLocal, ignoreConnection)
    --print(string.format("Event.send(event:%s, dontSendLocal:%s)", event, dontSendLocal));
    if g_server ~= nil then
        g_server:broadcastEvent(event, (not dontSendLocal), ignoreConnection);
    else
        g_client:getServerConnection():sendEvent(event);
    end
end

function Event.sendLight(event, dontSendLocal, ignoreConnection)
    --print(string.format("Event.sendLight(event:%s, dontSendLocal:%s)", event, dontSendLocal));
    if g_server ~= nil then
        Event.broadcastEvent(event, dontSendLocal, ignoreConnection);
    else
        Event.sendEvent(event, g_client:getServerConnection());
    end
end

function Event.broadcastEvent(event, sendLocal, ignoreConnection)
    for k, v in pairs(g_server.clientConnections) do
		if (k ~= NetworkNode.LOCAL_STREAM_ID or sendLocal) and (ignoreConnection == nil or v ~= ignoreConnection) then
			Event.sendEvent(event, v);
		end
	end
end

function Event.sendEvent(event, connection)
    connection.dataSent = 0;
    if not connection.isConnected then
        return;
    end
    if connection.streamId == NetworkNode.LOCAL_STREAM_ID then
        event.run(event, connection.localConnection);
    elseif connection.isReadyForEvents then
        if event.eventId == nil then
            print("Error: Invalid event id");
        else
            local channel = event.networkChannel;
            if channel == nil then
                channel = NetworkNode.CHANNEL_MAIN;
            end
            streamWriteUIntN(connection.streamId, MessageIds.EVENT, MessageIds.SEND_NUM_BITS);
            streamWriteUIntN(connection.streamId, event.eventId, EventIds.SEND_NUM_BITS);
            event.writeStream(event, connection.streamId, connection);
            connection.dataSent = streamGetWriteOffset(connection.streamId);
            netSendStream(connection.streamId, "medium", "unreliable_sequenced", channel, true);
            if g_server ~= nil then
                g_server:addPacketSize(NetworkNode.PACKET_EVENT, connection.dataSent / 8);
            else
                g_client:addPacketSize(NetworkNode.PACKET_EVENT, connection.dataSent / 8);
            end
        end
    end
end

-- Utils methods extension
function Utils.worldToLocalTranslation(id, x, y, z)
    local parentId = getParent(id);
    if parentId ~= 0 then
        local px, py, pz = Utils.localToWorldTranslation(parentId);
        return x - px, y - py, z - pz;
    else
        return x, y, z;
    end
end

function Utils.localToWorldTranslation(id)
    local x, y, z = getTranslation(id);
    local parentId = getParent(id);
    if parentId ~= 0 then
        local px, py, pz = Utils.localToWorldTranslation(parentId);
        return x + px, y + py, z + pz;
    else
        return x, y, z;
    end
end

function Utils.worldToLocalRotation(id, x, y, z)
    local parentId = getParent(id);
    if parentId ~= 0 then
        local px, py, pz = Utils.localToWorldRotation(parentId);
        return x - px, y - py, z - pz;
    else
        return x, y, z;
    end
end

function Utils.localToWorldRotation(id)
    local x, y, z = getRotation(id);
    local parentId = getParent(id);
    if parentId ~= 0 then
        local px, py, pz = Utils.localToWorldRotation(parentId);
        return x + px, y + py, z + pz;
    else
        return x, y, z;
    end
end

function math.roundDecimals(floatNumber, digits)
    local shift = 10 ^ digits;
    return math.floor(floatNumber * shift) / shift;
end

function Steerable:enterVehicle(isControlling, playerIndex, playerColorIndex)
    --print(string.format("Steerable:enterVehicle(isControlling:%s, playerIndex:%s, playerColorIndex:%s)", isControlling, playerIndex, playerColorIndex));
    self.isControlled = true;
    if isControlling then
        self.isEntered = true;

        -- if head tracking is available we want to use the first indoor camera
        if g_gameSettings:getValue("isHeadTrackingEnabled") and isHeadTrackingAvailable() then
            for i,camera in pairs(self.cameras) do
                if camera.isInside then
                    self.camIndex = i;
                    break;
                end
            end
        end
        if g_gameSettings:getValue("resetCamera") then
            self.camIndex = 1;
        end
        self:setActiveCameraIndex(self.camIndex);
    end

    if self.vehicleCharacter ~= nil and not self:getIsHired() and (not g_spectatorMode.spectating or self.controllerName ~= g_spectatorMode.spectatedPlayer) then
        self.vehicleCharacter:loadCharacter(PlayerUtil.playerIndexToDesc[playerIndex].xmlFilename, playerColorIndex);
    end

    if self.enterAnimation ~= nil and self.playAnimation ~= nil then
        self:playAnimation(self.enterAnimation, 1, nil, true);
    end

    self.playerIndex = playerIndex;
    self.playerColorIndex = playerColorIndex;

    g_currentMission.controlledVehicles[self] = self;
    self:onEnter(isControlling);

    if self.isServer and not isControlling and g_currentMission.trafficSystem ~= nil and g_currentMission.trafficSystem.trafficSystemId ~= 0 then
        addTrafficSystemPlayer(g_currentMission.trafficSystem.trafficSystemId, self.components[1].node);
    end
end
