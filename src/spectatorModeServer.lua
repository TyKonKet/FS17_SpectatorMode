--
-- SpectatorMode
--
-- @author TyKonKet
-- @date 23/01/2017
SpectatorModeServer = {}
SpectatorModeServer_mt = Class(SpectatorModeServer)

function SpectatorModeServer:new(isServer, isClient, customMt)
    if SpectatorModeServer_mt == nil then
        SpectatorModeServer_mt = Class(SpectatorModeServer)
    end
    local mt = customMt
    if mt == nil then
        mt = SpectatorModeServer_mt
    end
    local self = {}
    setmetatable(self, mt)
    self.name = "SpectatorModeServer"
    self.clients = {}
    return self
end

function SpectatorModeServer:print(text, ...)
    if self.debug then
        local start = string.format("[%s(%s)] -> ", self.name, getDate("%H:%M:%S"))
        local ptext = string.format(text, ...)
        print(string.format("%s%s", start, ptext))
    end
end

function SpectatorModeServer:addSubscriber(sName, connection, aName)
    self:print(("addSubscriber(sName:%s, connection:%s, aName:%s)"):format(sName, connection, aName))
    if g_dedicatedServerInfo ~= nil and g_currentMission.player.controllerName == aName then
        connection:sendEvent(SpectateRejectedEvent:new(SpectateRejectedEvent.REASON_DEDICATED_SERVER))
        return
    end
    if sName == aName then
        connection:sendEvent(SpectateRejectedEvent:new(SpectateRejectedEvent.REASON_YOURSELF))
        return
    end
    if self.clients[aName] == nil then
        self.clients[aName] = {}
    end
    if self.clients[aName].subscribers == nil then
        self.clients[aName].subscribers = {}
    end
    self.clients[aName].subscribers[sName] = {}
    self.clients[aName].subscribers[sName].connection = connection
    --send event to new subscriber
    connection:sendEvent(CameraChangeEvent:new(aName, self.clients[aName].cameraId, self.clients[aName].cameraIndex, self.clients[aName].cameraType))
end

function SpectatorModeServer:removeSubscriber(sName, aName)
    self:print(("removeSubscriber(sName:%s, aName:%s)"):format(sName, aName))
    if self.clients[aName] ~= nil and self.clients[aName].subscribers ~= nil and self.clients[aName].subscribers[sName] ~= nil then
        self.clients[aName].subscribers[sName] = nil
    end
end

function SpectatorModeServer:cameraChange(aName, cameraId, cameraIndex, cameraType)
    self:print(string.format("SpectatorMode:cameraChanged(aName:%s, cameraId:%s, cameraIndex:%s, cameraType:%s)", aName, cameraId, cameraIndex, cameraType))
    if self.clients[aName] == nil then
        self.clients[aName] = {}
    end
    if self.clients[aName].subscribers == nil then
        self.clients[aName].subscribers = {}
    end
    self.clients[aName].cameraId = cameraId
    self.clients[aName].cameraIndex = cameraIndex
    self.clients[aName].cameraType = cameraType
    local event = CameraChangeEvent:new(aName, cameraId, cameraIndex, cameraType)
    self:print(string.format("CameraChangeEvent:new(aName:%s, cameraId:%s, cameraIndex:%s, cameraType:%s)", aName, cameraId, cameraIndex, cameraType))
    for k, v in pairs(self.clients[aName].subscribers) do
        --send evet to subscribers
        v.connection:sendEvent(event)
    end
end
