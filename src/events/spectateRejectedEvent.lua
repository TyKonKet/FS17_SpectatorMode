--
-- SpectatorMode
--
-- @author TyKonKet
-- @date 23/01/2017

SpectateRejectedEvent = {}
SpectateRejectedEvent.REASON_DEDICATED_SERVER = 0
SpectateRejectedEvent.REASON_YOURSELF = 1
SpectateRejectedEvent.REASONS = 2
SpectateRejectedEvent.sendNumBits = Utils.getNumBits(SpectateRejectedEvent.REASONS)
SpectateRejectedEvent_mt = Class(SpectateRejectedEvent, Event)

InitEventClass(SpectateRejectedEvent, "SpectateRejectedEvent")

function SpectateRejectedEvent:emptyNew()
    local self = Event:new(SpectateRejectedEvent_mt)
    return self
end

function SpectateRejectedEvent:new(reason)
    local self = SpectateRejectedEvent:emptyNew()
    self.reason = reason
    return self
end

function SpectateRejectedEvent:writeStream(streamId, connection)
    streamWriteUIntN(streamId, self.reason, SpectateRejectedEvent.sendNumBits)
end

function SpectateRejectedEvent:readStream(streamId, connection)
    self.reason = streamReadUIntN(streamId, SpectateRejectedEvent.sendNumBits)
    self:run(connection)
end

function SpectateRejectedEvent:run(connection)
    if g_spectatorMode ~= nil then
        g_spectatorMode:spectateRejected(self.reason)
    end
end
