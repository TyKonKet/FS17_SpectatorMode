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
    self.debug = false;
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
    self.spectatedPlayer = "";
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
    self.actorDataEvent = nil;
    --addConsoleCommand("AAAStartActing", "", "startActing", self);
    --addConsoleCommand("AAASetSpectatorModeQuality", "", "setQuality", self);
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

function SpectatorMode:load()
    self:print("load()");
    self.guis.spectateGui:setSelectionCallback(self, self.startSpectate);
    self.actorDataEvent = ActorDataEvent:new(g_currentMission.missionInfo.playerName, 0, 0, 0, 0, 0, 0, 0);
end

function SpectatorMode:delete()
    self:print("delete()");
end

function SpectatorMode:update(dt)
    if self.acting or self.alwaysActing then
        local tx, ty, tz = 0;
        local rx, ry, rz, rw = 0;
        if g_currentMission.controlledVehicle == nil then
            tx, ty, tz = Utils.localToWorldTranslation(g_currentMission.player.cameraNode);
            rx, ry, rz, rw = getWorldQuaternion(g_currentMission.player.cameraNode);
        else
            tx, ty, tz = Utils.localToWorldTranslation(g_currentMission.controlledVehicle.activeCamera.cameraNode);
            rx, ry, rz, rw = getWorldQuaternion(g_currentMission.controlledVehicle.activeCamera.cameraNode);
        end
        --tx = math.roundDecimals(tx, self.actingQuality);
        --ty = math.roundDecimals(ty, self.actingQuality);
        --tz = math.roundDecimals(tz, self.actingQuality);
        --rx = math.roundDecimals(rx, self.actingQuality + 1);
        --ry = math.roundDecimals(ry, self.actingQuality + 1);
        --rz = math.roundDecimals(rz, self.actingQuality + 1);
        if self.actorDataEvent.tx ~= tx or self.actorDataEvent.rx ~= rx or self.actorDataEvent.ty ~= ty or self.actorDataEvent.ry ~= ry or self.actorDataEvent.tz ~= tz or self.actorDataEvent.rz ~= rz or self.actorDataEvent.rw ~= rw then           
            self.actorDataEvent.tx = tx;
            self.actorDataEvent.ty = ty;
            self.actorDataEvent.tz = tz;
            self.actorDataEvent.rx = rx;
            self.actorDataEvent.ry = ry;
            self.actorDataEvent.rz = rz;
            self.actorDataEvent.rw = rw;
            Event.sendLight(self.actorDataEvent, true);
            --self:print(string.format("%s -> %s %s %s %s %s %s %s",self.actorDataEvent.actorName, tx, ty, tz, rx, ry, rz, rw));
        end
    end
    if self.spectating then
        local tx, ty, tz = Utils.worldToLocalTranslation(g_currentMission.player.cameraNode, self.actors[self.spectatedPlayer].tx, self.actors[self.spectatedPlayer].ty, self.actors[self.spectatedPlayer].tz);
        local rx, ry, rz , rw = self.actors[self.spectatedPlayer].rx, self.actors[self.spectatedPlayer].ry, self.actors[self.spectatedPlayer].rz, self.actors[self.spectatedPlayer].rw;
        setTranslation(g_currentMission.player.cameraNode, tx, ty, tz);
        setQuaternion(g_currentMission.player.cameraNode, rx, ry, rz, rw);
    end
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

function SpectatorMode:showGui()
    local spectableUsers = {};
    for k,v in pairs(self.actors) do
        if v.acting then
        table.insert(spectableUsers, v.name);
        end
    end
    self.guis.spectateGui:setSpectableUsers(spectableUsers);
    g_gui:showGui("SpectateGui");
end

function SpectatorMode:setQuality(quality)
    local factor = nil;
    if quality ~= nil then
        if quality:lower() == "low" then
            factor = 0;
        elseif quality:lower() == "medium" then
            factor = 1;
        elseif quality:lower() == "high" then
            factor = 2;
        end        
        Event.send(SetQualityEvent:new(factor));
    end
    if factor == nil then
        self:print("Invalid command parameters");
        self:print("Usage: AAASetSpectatorModeQuality low | medium | high");
        return;
    end
    return factor;
end

function SpectatorMode:startSpectate(playerName)
    self:print(string.format("startSpectate(playerName:%s)", playerName));
    self.root.backup.tx, self.root.backup.ty, self.root.backup.tz = getTranslation(g_currentMission.player.rootNode);
    self.root.backup.rx, self.root.backup.ry, self.root.backup.rz, self.root.backup.rw = getQuaternion(g_currentMission.player.rootNode);
    self.camera.backup.tx, self.camera.backup.ty, self.camera.backup.tz = getTranslation(g_currentMission.player.cameraNode);
    self.camera.backup.rx, self.camera.backup.ry, self.camera.backup.rz, self.camera.backup.rw = getQuaternion(g_currentMission.player.cameraNode);
    for k,v in pairs(g_currentMission.players) do
        if v.controllerName == playerName then
            setVisibility(v.graphicsRootNode, false);
            setVisibility(v.meshThirdPerson, false);
        end
    end
    --for k,v in paris(g_currentMission.steerables) then
    --    setVisibility(v.vehicleCharacter.graphicsRootNode, false);
    --    setVisibility(v.vehicleCharacter.meshThirdPerson, false);
    --end
    self:showCrosshair(false);
    setTranslation(g_currentMission.player.rootNode, 0, -200, 0);
    self.spectatedPlayer = playerName;
    self.spectating = true;
end

function SpectatorMode:stopSpectate()
    self.spectating = false;
    for k,v in pairs(g_currentMission.players) do
        if v.controllerName == playerName then
            setVisibility(v.graphicsRootNode, true);
            setVisibility(v.meshThirdPerson, true);
        end
    end
    --for k,v in paris(g_currentMission.steerables) then
    --    setVisibility(v.vehicleCharacter.graphicsRootNode, true);
    --    setVisibility(v.vehicleCharacter.meshThirdPerson, true);
    --end
    self:showCrosshair(true);
    self.spectatedPlayer = "";
    setTranslation(g_currentMission.player.rootNode, self.root.backup.tx, self.root.backup.ty, self.root.backup.tz);
    setQuaternion(g_currentMission.player.rootNode, self.camera.backup.rx, self.camera.backup.ry, self.camera.backup.rz, self.camera.backup.rw);
    setTranslation(g_currentMission.player.cameraNode, self.camera.backup.tx, self.camera.backup.ty, self.camera.backup.tz);
    setQuaternion(g_currentMission.player.cameraNode, self.camera.backup.rx, self.camera.backup.ry, self.camera.backup.rz, self.camera.backup.rw);
end

function SpectatorMode:showCrosshair(sc)
    if not sc then
        self.oldPickedUpObjectWidth = g_currentMission.player.pickedUpObjectWidth;
        self.oldPickedUpObjectHeight = g_currentMission.player.pickedUpObjectHeight;
        g_currentMission.player.pickedUpObjectWidth = 0;
        g_currentMission.player.pickedUpObjectHeight = 0;
    else
        g_currentMission.player.pickedUpObjectWidth = self.oldPickedUpObjectWidth;
        g_currentMission.player.pickedUpObjectHeight = self.oldPickedUpObjectHeight;
    end
end

function SpectatorMode:actorStartStopEvent(start, actorName)
    self:print(string.format("actorStartStopEvent(start:%s, actorName:%s)", start, actorName));
    if self.actors[actorName] == nil then
        self.actors[actorName] = {};
        self.actors[actorName].name = actorName;
    end
    if start then
        self:print(string.format("Actor %s started", actorName));
        self.actors[actorName].acting = true;
    else
        self:print(string.format("Actor %s stopped", actorName));
        self.actors[actorName].acting = false;
    end
end

function SpectatorMode:actorDataEventF(actorName, tx, ty, tz, rx, ry, rz, rw)
    --self:print(string.format("actorDataEvent(actorName:%s, tx:%s, ty:%s, tz:%s, rx:%s, ry:%s, rz:%s)", actorName, tx, ty, tz, rx, ry, rz));
    if self.actors[actorName] == nil then
        self.actors[actorName] = {};
        self.actors[actorName].name = actorName;
        self.actors[actorName].acting = true;
    end
    self.actors[actorName].tx = tx;
    self.actors[actorName].ty = ty;
    self.actors[actorName].tz = tz;
    self.actors[actorName].rx = rx;
    self.actors[actorName].ry = ry;
    self.actors[actorName].rz = rz;
    self.actors[actorName].rw = rw;
end

function SpectatorMode:setQualityEvent(quality)
    self:print(string.format("setQualityEvent(quality:%s)", quality));
    self.actingQuality = quality;
end
