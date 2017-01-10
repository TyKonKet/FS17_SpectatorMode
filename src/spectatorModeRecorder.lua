--
-- SpectatorMode script
--
--
-- @author TyKonKet
-- @date 04/01/2017

SpectatorModeRecorder = {}
SpectatorModeRecorder.dir = g_currentModDirectory;
--NetworkNode.PACKET_SPECTATOR_MODE = 6;

addModEventListener(SpectatorModeRecorder);

function SpectatorModeRecorder:loadMap(savegame)
    g_spectatorMode = SpectatorMode:new(g_server ~= nil, g_client ~= nil);
    self.spectatorMode = g_spectatorMode;
    self.spectatorMode.dir = self.dir;
    self.spectatorMode.guis = {};
    self.spectatorMode.guis["spectateGui"] = SpectateGui:new();
    g_gui:loadGui(self.dir .. "spectateGui.xml", "SpectateGui", self.spectatorMode.guis.spectateGui);    
    --if g_server ~= nil then
    --    g_server.graphColors[NetworkNode.PACKET_SPECTATOR_MODE] = { 1, 1, 1, 1 };
    --    g_server.packetGraphs[NetworkNode.PACKET_SPECTATOR_MODE] = Graph:new(80, 0.2, 0.2, 0.6, 0.6, 0, 500, false, "bytes");
	--	g_server.packetGraphs[NetworkNode.PACKET_SPECTATOR_MODE]:setColor(g_server.graphColors[NetworkNode.PACKET_SPECTATOR_MODE][1], g_server.graphColors[NetworkNode.PACKET_SPECTATOR_MODE][2], g_server.graphColors[NetworkNode.PACKET_SPECTATOR_MODE][3], g_server.graphColors[NetworkNode.PACKET_SPECTATOR_MODE][4]);
    --    g_server.packetBytes[NetworkNode.PACKET_SPECTATOR_MODE] = 0;
    --end
    --if g_client ~= nil then
    --    g_client.graphColors[NetworkNode.PACKET_SPECTATOR_MODE] = { 1, 1, 1, 1 };
    --    g_client.packetGraphs[NetworkNode.PACKET_SPECTATOR_MODE] = Graph:new(80, 0.2, 0.2, 0.6, 0.6, 0, 500, false, "bytes");
	--	g_client.packetGraphs[NetworkNode.PACKET_SPECTATOR_MODE]:setColor(g_client.graphColors[NetworkNode.PACKET_SPECTATOR_MODE][1], g_client.graphColors[NetworkNode.PACKET_SPECTATOR_MODE][2], g_client.graphColors[NetworkNode.PACKET_SPECTATOR_MODE][3], g_client.graphColors[NetworkNode.PACKET_SPECTATOR_MODE][4]);
    --    g_client.packetBytes[NetworkNode.PACKET_SPECTATOR_MODE] = 0;
    --end
    NetworkNode.NUM_PACKETS = 6;
    if self.spectatorMode ~= nil then
        self.spectatorMode:load();
    end
end

function SpectatorModeRecorder:deleteMap()
    if self.spectatorMode ~= nil then
        self.spectatorMode:delete();
    end
    g_spectatorMode = nil;
end

function SpectatorModeRecorder:keyEvent(unicode, sym, modifier, isDown)
end

function SpectatorModeRecorder:mouseEvent(posX, posY, isDown, isUp, button)
end

function SpectatorModeRecorder:update(dt)
    if self.spectatorMode ~= nil then
        self.spectatorMode:update(dt);
    end
end

function SpectatorModeRecorder:draw()
end
