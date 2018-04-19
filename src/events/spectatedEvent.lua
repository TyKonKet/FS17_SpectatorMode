--
-- SpectatorMode
--
-- @author TyKonKet
-- @date 19/04/2018

SpectatedEvent = {}
SpectatedEvent_mt = Class(SpectatedEvent, Event)

InitEventClass(SpectatedEvent, "SpectatedEvent")

function SpectatedEvent:emptyNew()
    local self = Event:new(SpectatedEvent_mt)
    return self
end

function SpectatedEvent:new(spectated)
    local self = SpectatedEvent:emptyNew()
    self.spectated = spectated
    return self
end

function SpectatedEvent:writeStream(streamId, connection)
    streamWriteBool(streamId, self.spectated)
end

function SpectatedEvent:readStream(streamId, connection)
    self.spectated = streamReadBool(streamId)
    self:run(connection)
end

function SpectatedEvent:run(connection)
    if g_spectatorMode ~= nil then
        g_spectatorMode.spectated = self.spectated
    end
end
