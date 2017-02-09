--
-- SpectatorMode
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

function Utils.getLocalTransaltion(parentId, childId)
    local px, py, pz = getTranslation(parentId);
    local cx, cy, cz = getTranslation(childId);
    if g_spectatorMode.printWUS then
        print(string.format("t parent: x:%s, y:%s, z:%s", px, py, pz));
        print(string.format("t child : x:%s, y:%s, z:%s", cx, cy, cz));
    end
    return cx - px, cy - py, cz - pz;
end

function Utils.getLocalQuaternion(parentId, childId)
    local px, py, pz, pw = getQuaternion(parentId);
    local cx, cy, cz, cw = getQuaternion(childId);
    if g_spectatorMode.printWUS then
        print(string.format("r parent: x:%s, y:%s, z:%s, w:%s", px, py, pz, pw));
        print(string.format("r child : x:%s, y:%s, z:%s, w:%s", cx, cy, cz, cw));
    end
    return cx - px, cy - py, cz - pz, (pw + cw) / 2;
end

function Utils.getLocalRotation(parentId, childId)
    local px, py, pz = getRotation(parentId);
    local cx, cy, cz = getRotation(childId);
    if g_spectatorMode.printWUS then
        print(string.format("r parent: x:%s, y:%s, z:%s", px, py, pz));
        print(string.format("r child : x:%s, y:%s, z:%s", cx, cy, cz));
    end
    return cx - px, cy - py, cz - pz;
end