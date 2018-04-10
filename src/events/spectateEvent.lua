--
-- SpectatorMode
--
-- @author TyKonKet
-- @date 23/01/2017

SpectateEvent = {}
SpectateEvent_mt = Class(SpectateEvent, Event)

InitEventClass(SpectateEvent, "SpectateEvent")

function SpectateEvent:emptyNew()
    local self = Event:new(SpectateEvent_mt)
    return self
end

function SpectateEvent:new(start, spectatorName, actorName)
    local self = SpectateEvent:emptyNew()
    self.start = start
    self.actorName = actorName
    self.spectatorName = spectatorName
    return self
end

function SpectateEvent:writeStream(streamId, connection)
    streamWriteBool(streamId, self.start)
    streamWriteString(streamId, self.actorName)
    streamWriteString(streamId, self.spectatorName)
end

function SpectateEvent:readStream(streamId, connection)
    self.start = streamReadBool(streamId)
    self.actorName = streamReadString(streamId)
    self.spectatorName = streamReadString(streamId)
    self:run(connection)
end

function SpectateEvent:run(connection)
    if (not connection:getIsServer() or connection:getIsLocal()) then
        if g_spectatorMode ~= nil and g_spectatorMode.server ~= nil then
            if self.start then
                g_spectatorMode.server:addSubscriber(self.spectatorName, connection, self.actorName)
            else
                g_spectatorMode.server:removeSubscriber(self.spectatorName, self.actorName)
            end
        end
    end
end
