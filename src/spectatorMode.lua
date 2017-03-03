--
-- SpectatorMode
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
    self.spectating = false;
    self.spectatedPlayer = nil;
    self.spectatedVehicle = nil;
    addConsoleCommand("AAAPrint", "", "printer", self);
    return self;
end

function SpectatorMode:print(txt1, txt2, txt3, txt4, txt5, txt6, txt7, txt8, txt9)
    if self.debug then
        local suf = "[A]";
        if self.spectating then
            suf = "[S]";
        end
        local args = {txt1, txt2, txt3, txt4, txt5, txt6, txt7, txt8, txt9};
        for i, v in ipairs(args) do
            if v then
                print("[" .. self.name .. "] " .. suf .. " -> " .. tostring(v));
            end
        end
    end
end

function SpectatorMode:printer()
end

function SpectatorMode:loadMap()
    self:print("loadMap()");
    self.guis.spectateGui:setSelectionCallback(self, self.startSpectate);
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
    if self.lastCamera ~= getCamera() then
        self:print(("Camera setted to:%s"):format(getCamera()));
        self.lastCamera = getCamera();
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

function SpectatorMode:draw()
    if self.spectatedVehicle ~= nil then
        g_currentMission:drawVehicleHud(self.spectatedVehicle);
    end
end

function SpectatorMode:showGui()
    local spectableUsers = {};
    for k, p in pairs(g_currentMission.players) do
        table.insert(spectableUsers, p.controllerName);
    end
    self.guis.spectateGui:setSpectableUsers(spectableUsers);
    g_gui:showGui("SpectateGui");
end

function SpectatorMode:startSpectate(playerName)
    self:showCrosshair(false);
    self.spectating = true;
    self.spectatedPlayer = playerName;
    self:getPlayerByName(self.spectatedPlayer):setVisibility(false);
    g_currentMission.hasSpecialCamera = true;
    Event.send(SpectateEvent:new(true, g_currentMission.player.controllerName, playerName));
end

function SpectatorMode:stopSpectate()
    g_currentMission.hasSpecialCamera = false;
    self:setVehicleActiveCamera(nil);
    self.spectatedVehicle = nil;
    Event.send(SpectateEvent:new(false, g_currentMission.player.controllerName, self.spectatedPlayer));
    self:getPlayerByName(self.spectatedPlayer):setVisibility(true);
    self.spectatedPlayer = nil;
    self:showCrosshair(true);
    self.spectating = false;
end

function SpectatorMode:showCrosshair(sc)
    if not sc then
        g_currentMission.player.pickedUpObjectWidth = 0;
        g_currentMission.player.pickedUpObjectHeight = 0;
    else
        g_currentMission.player.pickedUpObjectWidth = self.oldPickedUpObjectWidth;
        g_currentMission.player.pickedUpObjectHeight = self.oldPickedUpObjectHeight;
    end
end

function SpectatorMode:getPlayerByName(name)
    for _, v in pairs(g_currentMission.players) do
        if v.controllerName == name then
            return v;
        end
    end
    return nil;
end

function SpectatorMode:cameraChanged(actorName, cameraId, cameraIndex, cameraType)
    self:print(string.format("SpectatorMode:cameraChanged(actorName:%s, cameraId:%s, cameraIndex:%s, cameraType:%s)", actorName, cameraId, cameraIndex, cameraType));
    if cameraType == CameraChangeEvent.CAMERA_TYPE_PLAYER then
        local p = self:getPlayerByName(actorName);
        setCamera(p.cameraNode);
        self:setVehicleActiveCamera(nil);
        self.spectatedVehicle = nil;
    elseif cameraType == CameraChangeEvent.CAMERA_TYPE_VEHICLE then
        for _, v in pairs(g_currentMission.controlledVehicles) do
            if v.controllerName == actorName then
                setCamera(v.cameras[cameraIndex].cameraNode);
                self:print(string.format("setCamera(v.cameras[cameraIndex].cameraNode:%s))", v.cameras[cameraIndex].cameraNode));
                v.vehicleCharacter:setCharacterVisibility(true);
                self.spectatedVehicle = v;
                self:setVehicleActiveCamera(cameraIndex);
            end
        end
    elseif cameraType == CameraChangeEvent.CAMERA_TYPE_VEHICLE_INDOOR then
        for _, v in pairs(g_currentMission.controlledVehicles) do
            if v.controllerName == actorName then
                setCamera(v.cameras[cameraIndex].cameraNode);
                self:print(string.format("setCamera(v.cameras[cameraIndex].cameraNode:%s))", v.cameras[cameraIndex].cameraNode));
                v.vehicleCharacter:setCharacterVisibility(false);
                self.spectatedVehicle = v;
                self:setVehicleActiveCamera(cameraIndex);
            end
        end
    end
end

function SpectatorMode:spectateRejected(reason)
    self:print(("spectateRejected(reason:%s)"):format(reason));
    self.spectating = false;
    --TODO: Add warning message via g18n
    if reason == SpectateRejectedEvent.REASON_DEDICATED_SERVER then
        g_currentMission:showBlinkingWarning("You can't spectate a dedicated server's player", 3000);
    elseif reason == SpectateRejectedEvent.REASON_YOURSELF then
        g_currentMission:showBlinkingWarning("You can't spectate yourself", 3000);
    end
end

function SpectatorMode:setVehicleActiveCamera(cameraIndex)
    self:print(string.format("SpectatorMode:setVehicleActiveCamera(cameraIndex:%s)", cameraIndex));
    if self.spectatedVehicle ~= nil then
        local useMirror = false;
        if cameraIndex ~= nil then
            self.spectatedVehicle:setActiveCameraIndex(cameraIndex);
            useMirror = self.spectatedVehicle.activeCamera.useMirror;
        end
        if self.spectatedVehicle.setMirrorVisible ~= nil then
            self.spectatedVehicle:setMirrorVisible(useMirror);
        end
    end
end
