--
-- SpectatorMode
--
-- @author TyKonKet
-- @date 04/01/2017
SpectatorModeRecorder = {}
SpectatorModeRecorder.dir = g_currentModDirectory;
SpectatorModeRecorder.name = "SpectatorModeRecorder";
SpectatorModeRecorder.debug = false;

function SpectatorModeRecorder:print(txt1, txt2, txt3, txt4, txt5, txt6, txt7, txt8, txt9)
    if self.debug then
        local args = {txt1, txt2, txt3, txt4, txt5, txt6, txt7, txt8, txt9};
        for i, v in ipairs(args) do
            if v then
                print("[" .. self.name .. "] -> " .. tostring(v));
            end
        end
    end
end

function SpectatorModeRecorder:initialize(missionInfo, missionDynamicInfo, loadingScreen)
    self = SpectatorModeRecorder;
    self:print("initialize()");
    SpectatorMode.debug = self.debug;
    SpectatorModeServer.debug = self.debug;
    g_spectatorMode = SpectatorMode:new(g_server ~= nil, g_client ~= nil);
    self.spectatorMode = g_spectatorMode;
    self.spectatorMode.debug = self.debug;
    if g_server ~= nil then
        self.spectatorMode.server = SpectatorModeServer:new(g_server ~= nil, g_client ~= nil);
        self.spectatorMode.server.debug = self.debug;
    end
    self.spectatorMode.dir = self.dir;
    self.spectatorMode.guis = {};
    self.spectatorMode.guis["spectateGui"] = SpectateGui:new();
    g_gui:loadGui(self.dir .. "spectateGui.xml", "SpectateGui", self.spectatorMode.guis.spectateGui);
    self.fixedUpdateDt = 0;
    self.fixedUpdateRealDt = 0;
    -- extending player functions
    Player.writeStream = Utils.appendedFunction(Player.writeStream, PlayerExtensions.writeStream);
    Player.readStream = Utils.appendedFunction(Player.readStream, PlayerExtensions.readStream);
    Player.writeUpdateStream = Utils.appendedFunction(Player.writeUpdateStream, PlayerExtensions.writeUpdateStream);
    Player.readUpdateStream = Utils.appendedFunction(Player.readUpdateStream, PlayerExtensions.readUpdateStream);
    Player.update = Utils.appendedFunction(Player.update, PlayerExtensions.update);
    Player.onEnter = Utils.appendedFunction(Player.onEnter, PlayerExtensions.onEnter);
    -- extending steerable functions
    Steerable.postLoad = Utils.appendedFunction(Steerable.postLoad, SteerableExtensions.postLoad);
    Steerable.setActiveCameraIndex = Utils.appendedFunction(Steerable.setActiveCameraIndex, SteerableExtensions.setActiveCameraIndex);
    Steerable.writeUpdateStream = Utils.appendedFunction(Steerable.writeUpdateStream, SteerableExtensions.writeUpdateStream);
    Steerable.readUpdateStream = Utils.appendedFunction(Steerable.readUpdateStream, SteerableExtensions.readUpdateStream);
    Steerable.update = Utils.appendedFunction(Steerable.update, SteerableExtensions.update);
    Steerable.drawUIInfo = SteerableExtensions.drawUIInfo;
    -- extending vehicle
    Vehicle.isSpectated = VehicleExtensions.isSpectated;
end
g_mpLoadingScreen.loadFunction = Utils.prependedFunction(g_mpLoadingScreen.loadFunction, SpectatorModeRecorder.initialize);

function SpectatorModeRecorder:load(missionInfo, missionDynamicInfo, loadingScreen)
    self = SpectatorModeRecorder;
    self:print("load()");
    g_currentMission.loadMapFinished = Utils.appendedFunction(g_currentMission.loadMapFinished, self.loadMapFinished);
    g_currentMission.onStartMission = Utils.appendedFunction(g_currentMission.onStartMission, self.afterLoad);
    g_currentMission.missionInfo.saveToXML = Utils.appendedFunction(g_currentMission.missionInfo.saveToXML, self.saveSavegame);
    g_currentMission.ingameMap.updatePlayerPosition = self.spectatorMode.updatePlayerPosition;
end
g_mpLoadingScreen.loadFunction = Utils.appendedFunction(g_mpLoadingScreen.loadFunction, SpectatorModeRecorder.load);

function SpectatorModeRecorder:loadMap(name)
    self:print(("loadMap(name:%s)"):format(name));
    if self.debug then
        end
    if self.spectatorMode ~= nil then
        self.spectatorMode:loadMap();
    end
    self:loadSavegame();
end

function SpectatorModeRecorder:loadMapFinished()
    self = SpectatorModeRecorder;
    self:print("loadMapFinished()");
end

function SpectatorModeRecorder:afterLoad()
    self = SpectatorModeRecorder;
    self:print("afterLoad");
    if self.spectatorMode ~= nil then
        self.spectatorMode:afterLoad();
    end
end

function SpectatorModeRecorder:loadSavegame()
    self:print("loadSavegame()");
end

function SpectatorModeRecorder:saveSavegame()
    self = SpectatorModeRecorder;
    self:print("saveSavegame()");
end

function SpectatorModeRecorder:deleteMap()
    self:print("deleteMap()");
    if self.spectatorMode ~= nil then
        self.spectatorMode:deleteMap();
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
    if self.spectatorMode ~= nil then
        self.spectatorMode:draw();
    end
end

addModEventListener(SpectatorModeRecorder);
