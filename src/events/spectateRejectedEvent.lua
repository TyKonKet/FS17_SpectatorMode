--
-- SpectatorMode
--
-- @author TyKonKet
-- @date 23/01/2017

SpectateRejectedEvent = {}
SpectateRejectedEvent.REASON_DEDICATED_SERVER = 1
SpectateRejectedEvent.REASON_YOURSELF = 2
SpectateRejectedEvent.REASONS = 2
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
    streamWriteInt8(streamId, self.reason)
end

function SpectateRejectedEvent:readStream(streamId, connection)
    self.reason = streamReadInt8(streamId)
    self:run(connection)
end

function SpectateRejectedEvent:run(connection)
    if connection:getIsServer() then
        if g_spectatorMode ~= nil then
            g_spectatorMode:spectateRejected(self.reason)
        end
    end
end
