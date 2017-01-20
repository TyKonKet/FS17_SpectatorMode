--
-- SpectatorMode script
--
--
-- @author TyKonKet
-- @date 23/12/2016

SpectatorMode = {};
SpectatorMode_mt = Class(SpectatorMode);

function SpectatorMode:new(isServer, isClient, customMt)
    if SpectatorMode_mt == nil then
        SpectatorMode_mt = Class(SpectatorMode);
    end
    local mt = customMt;
    if mt == nil then
        mt = SpectatorMode_mt;
    end
    local self = {};
    setmetatable(self, mt);
    self.name = "SpectatorMode";
    self.debug = true;
    self.actors = {};
    --self.actors["Mattew"] = {};
    --self.actors["Mattew"].name = "Mattew";
    --self.actors["Mattew"].acting = true;
    --self.actors["Luke"] = {};
    --self.actors["Luke"].name = "Luke";
    --self.actors["Luke"].acting = true;
    self.acting = false;
    --self.actingQuality = self:setQuality("medium");
    self.alwaysActing = true;
    self.spectating = false;
    self.spectatedPlayer = nil;
    self.root = {};
    self.root.backup = {};
    self.root.backup.tx = 0;
    self.root.backup.ty = 0;
    self.root.backup.tz = 0;
    self.root.backup.rx = 0;
    self.root.backup.ry = 0;
    self.root.backup.rz = 0;
    self.root.backup.rw = 0;
    self.camera = {};
    self.camera.backup = {};
    self.camera.backup.tx = 0;
    self.camera.backup.ty = 0;
    self.camera.backup.tz = 0;
    self.camera.backup.rx = 0;
    self.camera.backup.ry = 0;
    self.camera.backup.rz = 0;
    self.camera.backup.rw = 0;
    self.camera.backup.fovy = 0;
    self.actorDataEvent = nil;
    self.FPS = {};
    self.FPS.show = true;
    self.FPS.dt = 0;
    self.FPS.count = 0;
    self.FPS.tempCount = 0;
    self.CPS = {};
    self.CPS.show = true;
    self.CPS.count = 0;
    self.CPS.tempCount = 0;
    self.ESPS = {};
    self.ESPS.show = true;
    self.ESPS.count = 0;
    self.ESPS.tempCount = 0;
    self.ERPS = {};
    self.ERPS.show = true;
    self.ERPS.count = 0;
    self.ERPS.tempCount = 0;
    --addConsoleCommand("AAAStartActing", "", "startActing", self);
    --addConsoleCommand("AAASetSpectatorModeQuality", "", "setQuality", self);
    addConsoleCommand("AAAPrint", "", "printer", self);
    self:print(string.format("new(isServer:%s, isClient:%s, customMt:%s)", isServer, isClient, customMt));
    return self;
end

function SpectatorMode:print(txt1, txt2, txt3, txt4, txt5, txt6, txt7, txt8, txt9)
    if self.debug then
        local args = {txt1, txt2, txt3, txt4, txt5, txt6, txt7, txt8, txt9};
        for i, v in ipairs(args) do
            if v then
                print("[" .. self.name .. "] -> " .. tostring(v));
            end
        end
    end
end

function SpectatorMode:printer()
    --if SpectatorModeRecorder.fixedFPS == 30 then
    --    SpectatorModeRecorder.fixedFPS = 45;
    --    SpectatorModeRecorder.fixedDt = 1000 / SpectatorModeRecorder.fixedFPS;
    --elseif SpectatorModeRecorder.fixedFPS == 45 then
    --    SpectatorModeRecorder.fixedFPS = 60;
    --    SpectatorModeRecorder.fixedDt = 1000 / SpectatorModeRecorder.fixedFPS;
    --else
    --    SpectatorModeRecorder.fixedFPS = 30;
    --    SpectatorModeRecorder.fixedDt = 1000 / SpectatorModeRecorder.fixedFPS;
    --end
end

function SpectatorMode:loadMap()
    self:print("loadMap()");
    self.guis.spectateGui:setSelectionCallback(self, self.startSpectate);
    self.actorDataEvent = ActorDataEvent:new(g_currentMission.missionInfo.playerName, 0, 0, 0, 0, 0, 0, 0, 0);
end

function SpectatorMode:deleteMap()
    self:print("deleteMap()");
end

function SpectatorMode:afterLoad()
    self:print("afterLoad()");
    self.oldPickedUpObjectWidth = g_currentMission.player.pickedUpObjectWidth;
    self.oldPickedUpObjectHeight = g_currentMission.player.pickedUpObjectHeight;
end

function SpectatorMode:update(dt)
    --self.FPS.dt = self.FPS.dt + dt;
    --if self.FPS.dt > 1000 then
    --    self.FPS.dt = self.FPS.dt - 1000;
    --    self.FPS.count = self.FPS.tempCount;
    --    self.FPS.tempCount = 0;
    --    self.CPS.count = self.CPS.tempCount;
    --    self.CPS.tempCount = 0;
    --    self.ESPS.count = self.ESPS.tempCount;
    --    self.ESPS.tempCount = 0;
    --    self.ERPS.count = self.ERPS.tempCount;
    --    self.ERPS.tempCount = 0;
    --end
    --if self.FPS.show then
    --    self.FPS.tempCount = self.FPS.tempCount + 1;
    --end
    --if self.spectating then
    --    local tx, ty, tz = Utils.worldToLocalTranslation(g_currentMission.player.cameraNode, self.actors[self.spectatedPlayer].tx, self.actors[self.spectatedPlayer].ty, self.actors[self.spectatedPlayer].tz);
    --    local rx, ry, rz , rw = self.actors[self.spectatedPlayer].rx, self.actors[self.spectatedPlayer].ry, self.actors[self.spectatedPlayer].rz, self.actors[self.spectatedPlayer].rw;
    --    setTranslation(g_currentMission.player.cameraNode, tx, ty, tz);
    --    setQuaternion(g_currentMission.player.cameraNode, rx, ry, rz, rw);
    --    setFovy(g_currentMission.player.cameraNode, self.actors[self.spectatedPlayer].fovy);
    --end
    if g_currentMission.controlledVehicle == nil then
        if self.spectating then
            g_currentMission:addHelpButtonText(g_i18n:getText("STOP_SPECTATOR_MODE"), InputBinding.TOGGLE_SPECTATOR_MODE);
	        if InputBinding.hasEvent(InputBinding.TOGGLE_SPECTATOR_MODE, true) then
	            self:stopSpectate();
            end
        else
            g_currentMission:addHelpButtonText(g_i18n:getText("START_SPECTATOR_MODE"), InputBinding.TOGGLE_SPECTATOR_MODE);
	        if g_gui.currentGui == nil and InputBinding.hasEvent(InputBinding.TOGGLE_SPECTATOR_MODE, true) then
	            self:showGui();
            end
	    end
	end
end

function SpectatorMode:fixedUpdate(dt)
    --if self.CPS.show then
    --    self.CPS.tempCount = self.CPS.tempCount + 1;
    --end
    --if self.acting or self.alwaysActing then
    --    local tx, ty, tz = 0;
    --    local rx, ry, rz, rw = 0;
    --    local fovy = 0;
    --    if g_currentMission.controlledVehicle == nil then
    --        tx, ty, tz = Utils.localToWorldTranslation(g_currentMission.player.cameraNode);
    --        rx, ry, rz, rw = getWorldQuaternion(g_currentMission.player.cameraNode);
    --        fovy = getFovy(g_currentMission.player.cameraNode);
    --    else
    --        tx, ty, tz = Utils.localToWorldTranslation(g_currentMission.controlledVehicle.activeCamera.cameraNode);
    --        rx, ry, rz, rw = getWorldQuaternion(g_currentMission.controlledVehicle.activeCamera.cameraNode);
    --        fovy = getFovy(g_currentMission.controlledVehicle.activeCamera.cameraNode);
    --    end
    --    tx = math.roundDecimals(tx, 1);
    --    ty = math.roundDecimals(ty, 1);
    --    tz = math.roundDecimals(tz, 1);
    --    rx = math.roundDecimals(rx, 2);
    --    ry = math.roundDecimals(ry, 2);
    --    rz = math.roundDecimals(rz, 2);
    --    rw = math.roundDecimals(rw, 2);
    --    if self.actorDataEvent.tx ~= tx or self.actorDataEvent.rx ~= rx or self.actorDataEvent.ty ~= ty or self.actorDataEvent.ry ~= ry or self.actorDataEvent.tz ~= tz or self.actorDataEvent.rz ~= rz or self.actorDataEvent.rw ~= rw then           
    --        self.actorDataEvent.tx = tx;
    --        self.actorDataEvent.ty = ty;
    --        self.actorDataEvent.tz = tz;
    --        self.actorDataEvent.rx = rx;
    --        self.actorDataEvent.ry = ry;
    --        self.actorDataEvent.rz = rz;
    --        self.actorDataEvent.rw = rw;
    --        self.actorDataEvent.fovy = fovy;
    --        Event.sendLight(self.actorDataEvent, true);
    --        --self:print(string.format("%s -> %s %s %s %s %s %s %s",self.actorDataEvent.actorName, tx, ty, tz, rx, ry, rz, rw));
    --        if self.ESPS.show then
    --            self.ESPS.tempCount = self.ESPS.tempCount + 1;
    --        end
    --    end
    --end
end

function SpectatorMode:draw()
    --if self.FPS.show then
    --    renderText(0.001, 0.63, 0.01, ("FPS:%s"):format(self.FPS.count));
    --end
    --if self.CPS.show then
    --    renderText(0.001, 0.62, 0.01, ("CPS:%s"):format(self.CPS.count));
    --end
    --if self.ESPS.show then
    --    renderText(0.001, 0.61, 0.01, ("ESPS:%s"):format(self.ESPS.count));
    --end
    --if self.ERPS.show then
    --    renderText(0.001, 0.6, 0.01, ("ERPS:%s"):format(self.ERPS.count));
    --end
end

function SpectatorMode:showGui()
    local spectableUsers = {};
    for k,p in pairs(g_currentMission.players) do
        table.insert(spectableUsers, p.controllerName);
    end
    self.guis.spectateGui:setSpectableUsers(spectableUsers);
    g_gui:showGui("SpectateGui");
end

function SpectatorMode:setQuality(quality)
    --local factor = nil;
    --if quality ~= nil then
    --    if quality:lower() == "low" then
    --        factor = 0;
    --    elseif quality:lower() == "medium" then
    --        factor = 1;
    --    elseif quality:lower() == "high" then
    --        factor = 2;
    --    end        
    --    Event.send(SetQualityEvent:new(factor));
    --end
    --if factor == nil then
    --    self:print("Invalid command parameters");
    --    self:print("Usage: AAASetSpectatorModeQuality low | medium | high");
    --    return;
    --end
    --return factor;
end

function SpectatorMode:startSpectate(playerName)
    --self:print(string.format("startSpectate(playerName:%s)", playerName));
    --self.root.backup.tx, self.root.backup.ty, self.root.backup.tz = getTranslation(g_currentMission.player.rootNode);
    --self.root.backup.rx, self.root.backup.ry, self.root.backup.rz, self.root.backup.rw = getQuaternion(g_currentMission.player.rootNode);
    --self.camera.backup.tx, self.camera.backup.ty, self.camera.backup.tz = getTranslation(g_currentMission.player.cameraNode);
    --self.camera.backup.rx, self.camera.backup.ry, self.camera.backup.rz, self.camera.backup.rw = getQuaternion(g_currentMission.player.cameraNode);
    --self.camera.backup.fovy = getFovy(g_currentMission.player.cameraNode);
    --for k,v in pairs(g_currentMission.players) do
    --    if v.controllerName == playerName then
    --        self:print("Hided player " .. v.controllerName);
    --        setVisibility(v.graphicsRootNode, false);
    --        setVisibility(v.meshThirdPerson, false);
    --    end
    --end
    --for k,v in paris(g_currentMission.steerables) then
    --    setVisibility(v.vehicleCharacter.graphicsRootNode, false);
    --    setVisibility(v.vehicleCharacter.meshThirdPerson, false);
    --end
    --self:showCrosshair(false);
    --setTranslation(g_currentMission.player.rootNode, 0, -200, 0);
    --self.spectatedPlayer = playerName;
    g_currentMission.hasSpecialCamera = true;
    self.spectatedPlayer = self:getPlayerByName(playerName);
    setCamera(self.spectatedPlayer.cameraNode);
    self.spectatedPlayer:setVisibility(false);
end

function SpectatorMode:stopSpectate()
    --self:print("stopSpectate()");
    --for k,v in pairs(g_currentMission.players) do
    --    if v.controllerName == playerName then
    --        setVisibility(v.graphicsRootNode, true);
    --        setVisibility(v.meshThirdPerson, true);
    --    end
    --end
    ----for k,v in paris(g_currentMission.steerables) then
    ----    setVisibility(v.vehicleCharacter.graphicsRootNode, true);
    ----    setVisibility(v.vehicleCharacter.meshThirdPerson, true);
    ----end
    --self:showCrosshair(true);
    --self.spectatedPlayer = "";
    --setTranslation(g_currentMission.player.rootNode, self.root.backup.tx, self.root.backup.ty, self.root.backup.tz);
    --setQuaternion(g_currentMission.player.rootNode, self.camera.backup.rx, self.camera.backup.ry, self.camera.backup.rz, self.camera.backup.rw);
    --setTranslation(g_currentMission.player.cameraNode, self.camera.backup.tx, self.camera.backup.ty, self.camera.backup.tz);
    --setQuaternion(g_currentMission.player.cameraNode, self.camera.backup.rx, self.camera.backup.ry, self.camera.backup.rz, self.camera.backup.rw);
    --setFovy(g_currentMission.player.cameraNode, self.camera.backup.fovy);
    self.spectatedPlayer:setVisibility(true);
    self.spectatedPlayer = nil;
    setCamera(g_currentMission.player.cameraNode);
    g_currentMission.hasSpecialCamera = false;
end

function SpectatorMode:showCrosshair(sc)
    --self:print(("showCrosshair(sc:%s)"):format(sc));
    --if not sc then
    --    self.oldPickedUpObjectWidth = g_currentMission.player.pickedUpObjectWidth;
    --    self.oldPickedUpObjectHeight = g_currentMission.player.pickedUpObjectHeight;
    --    g_currentMission.player.pickedUpObjectWidth = 0;
    --    g_currentMission.player.pickedUpObjectHeight = 0;
    --else
    --    g_currentMission.player.pickedUpObjectWidth = self.oldPickedUpObjectWidth;
    --    g_currentMission.player.pickedUpObjectHeight = self.oldPickedUpObjectHeight;
    --end
end

function SpectatorMode:actorStartStopEvent(start, actorName)
    --self:print(string.format("actorStartStopEvent(start:%s, actorName:%s)", start, actorName));
    --if self.actors[actorName] == nil then
    --    self.actors[actorName] = {};
    --    self.actors[actorName].name = actorName;
    --end
    --if start then
    --    self:print(string.format("Actor %s started", actorName));
    --    self.actors[actorName].acting = true;
    --else
    --    self:print(string.format("Actor %s stopped", actorName));
    --    self.actors[actorName].acting = false;
    --end
end

function SpectatorMode:actorDataEventF(actorName, tx, ty, tz, rx, ry, rz, rw, fovy)
    --self:print(string.format("actorDataEvent(actorName:%s, tx:%s, ty:%s, tz:%s, rx:%s, ry:%s, rz:%s, fovy:%s)", actorName, tx, ty, tz, rx, ry, rz, fovy));
    --if self.actors[actorName] == nil then
    --    self.actors[actorName] = {};
    --    self.actors[actorName].name = actorName;
    --    self.actors[actorName].acting = true;
    --end
    --self.actors[actorName].tx = tx;
    --self.actors[actorName].ty = ty;
    --self.actors[actorName].tz = tz;
    --self.actors[actorName].rx = rx;
    --self.actors[actorName].ry = ry;
    --self.actors[actorName].rz = rz;
    --self.actors[actorName].rw = rw;
    --self.actors[actorName].fovy = fovy;
    --local dt = self.actorDataEventDt;
    --self.actorDataEventDt = 0;
    --if self.ERPS.show then
    --    self.ERPS.tempCount = self.ERPS.tempCount + 1;
    --end
end

function SpectatorMode:setQualityEvent(quality)
    --self:print(string.format("setQualityEvent(quality:%s)", quality));
    --self.actingQuality = quality;
end--

function SpectatorMode:getPlayerByName(name)
    for k,v in pairs(g_currentMission.players) do
        if v.controllerName == name then
            return v;
        end
    end
    return nil;
end