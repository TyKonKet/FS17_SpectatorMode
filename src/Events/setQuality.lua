--
-- SpectatorMode script
--
--
-- @author TyKonKet
-- @date 06/01/2017

SetQualityEvent = {};
SetQualityEvent_mt = Class(SetQualityEvent, Event);

InitEventClass(SetQualityEvent, "SetQualityEvent");

function SetQualityEvent:emptyNew()
    local self = Event:new(SetQualityEvent_mt);
    return self;
end

function SetQualityEvent:new(quality)
    local self = SetQualityEvent:emptyNew();
    self.quality = quality;
    return self;
end

function SetQualityEvent:readStream(streamId, connection)
    self.quality = streamReadFloat32(streamId);
    self:run(connection);
end

function SetQualityEvent:writeStream(streamId, connection)
	streamWriteFloat32(streamId, self.quality)
end

function SetQualityEvent:run(connection)
	if not connection:getIsServer(connection) then
        Event.send(self, true);
	end
    if g_spectatorMode ~= nil then
        g_spectatorMode:setQualityEvent(self.quality);
    end
end
