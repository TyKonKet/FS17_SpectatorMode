--
-- SpectatorMode
--
-- @author TyKonKet
-- @date 09/04/2018

MinimapChangeEvent = {}
MinimapChangeEvent.STATE_MINIMAP = IngameMap.STATE_MINIMAP
MinimapChangeEvent.STATE_MAP = IngameMap.STATE_MAP
MinimapChangeEvent.STATE_OFF = IngameMap.STATE_OFF
MinimapChangeEvent.STATES = 3
MinimapChangeEvent.sendNumBits = Utils.getNumBits(MinimapChangeEvent.STATES)
MinimapChangeEvent_mt = Class(MinimapChangeEvent, Event)

InitEventClass(MinimapChangeEvent, "MinimapChangeEvent")

function MinimapChangeEvent:emptyNew()
    local self = Event:new(MinimapChangeEvent_mt)
    return self
end

function MinimapChangeEvent:new(actorName, mmState, toServer)
    local self = MinimapChangeEvent:emptyNew()
    self.actorName = actorName
    self.mmState = mmState
    self.toServer = toServer == true
    return self
end

function MinimapChangeEvent:writeStream(streamId, connection)
    streamWriteUIntN(streamId, self.mmState, MinimapChangeEvent.sendNumBits)
    streamWriteString(streamId, self.actorName)
    streamWriteBool(streamId, self.toServer)
end

function MinimapChangeEvent:readStream(streamId, connection)
    self.mmState = streamReadUIntN(streamId, MinimapChangeEvent.sendNumBits)
    self.actorName = streamReadString(streamId)
    self.toServer = streamReadBool(streamId)
    self:run(connection)
end

function MinimapChangeEvent:run(connection)
    if self.toServer then
        if g_spectatorMode ~= nil and g_spectatorMode.server ~= nil then
            g_spectatorMode.server:minimapChange(self.actorName, self.mmState)
        end
    else
        if g_spectatorMode ~= nil then
            g_spectatorMode:minimapChange(self.actorName, self.mmState)
        end
    end
end
