--
-- SpectatorMode
--
-- @author TyKonKet
-- @date 04/01/2017
SpectatorModeRecorder = {}
SpectatorModeRecorder.dir = g_currentModDirectory
SpectatorModeRecorder.name = "SpectatorModeRecorder"
SpectatorModeRecorder.debug = false

function SpectatorModeRecorder:print(text, ...)
    if self.debug then
        local start = string.format("[%s(%s)] -> ", self.name, getDate("%H:%M:%S"))
        local ptext = string.format(text, ...)
        print(string.format("%s%s", start, ptext))
    end
end

function SpectatorModeRecorder:initialize(missionInfo, missionDynamicInfo, loadingScreen)
    self = SpectatorModeRecorder
    self.isMultiplayer = missionDynamicInfo.missionDynamicInfo.isMultiplayer
    if not self.isMultiplayer then
        return
    end
    margeI18N()
    SpectatorMode.debug = self.debug
    SpectatorModeServer.debug = self.debug
    g_spectatorMode = SpectatorMode:new(g_server ~= nil, g_client ~= nil)
    self.spectatorMode = g_spectatorMode
    self.spectatorMode.debug = self.debug
    if g_server ~= nil then
        self.spectatorMode.server = SpectatorModeServer:new(g_server ~= nil, g_client ~= nil)
        self.spectatorMode.server.debug = self.debug
    end
    self.spectatorMode.dir = self.dir
    self.spectatorMode.guis = {}
    self.spectatorMode.guis["spectateGui"] = SpectateGui:new()
    g_gui:loadGui(self.dir .. "guis/spectateGui.xml", "SpectateGui", self.spectatorMode.guis.spectateGui)
    -- FocusManager restore
    FocusManager:setGui("MPLoadingScreen")
    self.fixedUpdateDt = 0
    self.fixedUpdateRealDt = 0
    -- extending player functions
    Player.writeStream = Utils.appendedFunction(Player.writeStream, PlayerExtensions.writeStream)
    Player.readStream = Utils.appendedFunction(Player.readStream, PlayerExtensions.readStream)
    Player.writeUpdateStream = Utils.appendedFunction(Player.writeUpdateStream, PlayerExtensions.writeUpdateStream)
    Player.readUpdateStream = Utils.appendedFunction(Player.readUpdateStream, PlayerExtensions.readUpdateStream)
    Player.update = Utils.appendedFunction(Player.update, PlayerExtensions.update)
    Player.onEnter = Utils.appendedFunction(Player.onEnter, PlayerExtensions.onEnter)
    Player.isSpectated = PlayerExtensions.isSpectated
    Player.drawUIInfo = PlayerExtensions.drawUIInfo
    -- extending steerable functions
    Steerable.postLoad = Utils.appendedFunction(Steerable.postLoad, SteerableExtensions.postLoad)
    Steerable.addToolCameras = Utils.appendedFunction(Steerable.addToolCameras, SteerableExtensions.addToolCameras)
    Steerable.removeToolCameras = Utils.appendedFunction(Steerable.removeToolCameras, SteerableExtensions.removeToolCameras)
    Steerable.setActiveCameraIndex = Utils.appendedFunction(Steerable.setActiveCameraIndex, SteerableExtensions.setActiveCameraIndex)
    Steerable.writeUpdateStream = Utils.appendedFunction(Steerable.writeUpdateStream, SteerableExtensions.writeUpdateStream)
    Steerable.readUpdateStream = Utils.appendedFunction(Steerable.readUpdateStream, SteerableExtensions.readUpdateStream)
    Steerable.update = Utils.appendedFunction(Steerable.update, SteerableExtensions.update)
    Steerable.drawUIInfo = SteerableExtensions.drawUIInfo
    -- extending vehicle
    Vehicle.isSpectated = VehicleExtensions.isSpectated
    -- extending ai vehicle
    AIVehicle.onStartAiVehicle = Utils.appendedFunction(AIVehicle.onStartAiVehicle, AIVehicleExtensions.onStartAiVehicle)
    AIVehicle.onStopAiVehicle = Utils.appendedFunction(AIVehicle.onStopAiVehicle, AIVehicleExtensions.onStopAiVehicle)
end
g_mpLoadingScreen.loadFunction = Utils.prependedFunction(g_mpLoadingScreen.loadFunction, SpectatorModeRecorder.initialize)

function SpectatorModeRecorder:load(missionInfo, missionDynamicInfo, loadingScreen)
    self = SpectatorModeRecorder
    if not self.isMultiplayer then
        return
    end
    g_currentMission.loadMapFinished = Utils.appendedFunction(g_currentMission.loadMapFinished, self.loadMapFinished)
    g_currentMission.onStartMission = Utils.appendedFunction(g_currentMission.onStartMission, self.afterLoad)
    g_currentMission.onUserEvent = Utils.prependedFunction(g_currentMission.onUserEvent, self.spectatorMode.onUserEvent)
    g_currentMission.missionInfo.saveToXML = Utils.appendedFunction(g_currentMission.missionInfo.saveToXML, self.saveSavegame)
    g_currentMission.requestToEnterVehicle = Utils.overwrittenFunction(g_currentMission.requestToEnterVehicle, self.spectatorMode.requestToEnterVehicle)
    g_currentMission.ingameMap.toggleSize = Utils.overwrittenFunction(g_currentMission.ingameMap.toggleSize, self.spectatorMode.toggleSize)
    g_currentMission.ingameMap.updatePlayerPosition = self.spectatorMode.updatePlayerPosition
end
g_mpLoadingScreen.loadFunction = Utils.appendedFunction(g_mpLoadingScreen.loadFunction, SpectatorModeRecorder.load)

function SpectatorModeRecorder:loadMap(name)
    if not self.isMultiplayer then
        return
    end
    if self.spectatorMode ~= nil then
        self.spectatorMode:loadMap()
    end
    self:loadSavegame()
end

function SpectatorModeRecorder:loadMapFinished()
    self = SpectatorModeRecorder
end

function SpectatorModeRecorder:afterLoad()
    self = SpectatorModeRecorder
    if not self.isMultiplayer then
        return
    end
    --if self.spectatorMode ~= nil then
    --    self.spectatorMode:afterLoad();
    --end
end

function SpectatorModeRecorder:loadSavegame()
end

function SpectatorModeRecorder:saveSavegame()
    self = SpectatorModeRecorder
end

function SpectatorModeRecorder:deleteMap()
    if not self.isMultiplayer then
        return
    end
    if self.spectatorMode ~= nil then
        self.spectatorMode:deleteMap()
    end
    g_spectatorMode = nil
end

function SpectatorModeRecorder:keyEvent(unicode, sym, modifier, isDown)
end

function SpectatorModeRecorder:mouseEvent(posX, posY, isDown, isUp, button)
end

function SpectatorModeRecorder:update(dt)
    if not self.isMultiplayer then
        return
    end
    if self.spectatorMode ~= nil then
        self.spectatorMode:update(dt)
    end
end

function SpectatorModeRecorder:draw()
    if not self.isMultiplayer then
        return
    end
    if self.spectatorMode ~= nil then
        self.spectatorMode:draw()
    end
end

addModEventListener(SpectatorModeRecorder)
