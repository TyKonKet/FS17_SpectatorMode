--
-- SpectatorMode script
--
--
-- @author TyKonKet
-- @date 04/01/2017

SpectatorModeRecorder = {}
SpectatorModeRecorder.dir = g_currentModDirectory;
SpectatorModeRecorder.name = "SpectatorModeRecorder";
SpectatorModeRecorder.debug = true;
SpectatorModeRecorder.fixedFPS = 30;
SpectatorModeRecorder.fixedDt = 1000 / SpectatorModeRecorder.fixedFPS;

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
    g_spectatorMode = SpectatorMode:new(g_server ~= nil, g_client ~= nil);
    self.spectatorMode = g_spectatorMode;
    self.spectatorMode.dir = self.dir;
    self.spectatorMode.guis = {};
    self.spectatorMode.guis["spectateGui"] = SpectateGui:new();
    g_gui:loadGui(self.dir .. "spectateGui.xml", "SpectateGui", self.spectatorMode.guis.spectateGui);
    self.fixedUpdateDt = 0;
    self.fixedUpdateRealDt = 0;
end
g_mpLoadingScreen.loadFunction = Utils.prependedFunction(g_mpLoadingScreen.loadFunction, SpectatorModeRecorder.initialize);

function SpectatorModeRecorder:load(missionInfo, missionDynamicInfo, loadingScreen)
    self = SpectatorModeRecorder;
    self:print("load()");
    g_currentMission.loadMapFinished = Utils.appendedFunction(g_currentMission.loadMapFinished, self.loadMapFinished);
    g_currentMission.onStartMission = Utils.appendedFunction(g_currentMission.onStartMission, self.afterLoad);
    g_currentMission.missionInfo.saveToXML = Utils.appendedFunction(g_currentMission.missionInfo.saveToXML, self.saveSavegame);
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
        self.fixedUpdateDt = self.fixedUpdateDt + dt;
        self.fixedUpdateRealDt = self.fixedUpdateRealDt +dt;
        if self.fixedUpdateDt >= self.fixedDt then
            self.spectatorMode:fixedUpdate(self.fixedUpdateRealDt);
            self.fixedUpdateDt = self.fixedUpdateDt - self.fixedDt;
            self.fixedUpdateRealDt = 0;
        end
    end
end

function SpectatorModeRecorder:draw()
    if self.spectatorMode ~= nil then
        self.spectatorMode:draw();
    end
end

addModEventListener(SpectatorModeRecorder);
