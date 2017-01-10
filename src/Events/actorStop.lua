--
-- SpectatorMode script
--
--
-- @author TyKonKet
-- @date 03/01/2017

ActorStopEvent = {};
ActorStopEvent_mt = Class(ActorStopEvent, Event);

InitEventClass(ActorStopEvent, "ActorStopEvent");

function ActorStopEvent:emptyNew()
    local self = Event:new(ActorStopEvent_mt);
    return self;
end

function ActorStopEvent:new(actorName)
    local self = ActorStopEvent:emptyNew();
    self.actorName = actorName;
    return self;
end

function ActorStopEvent:readStream(streamId, connection)
    self.actorName = streamReadString(streamId);
    self:run(connection);
end

function ActorStopEvent:writeStream(streamId, connection)
	streamWriteString(streamId, self.actorName);
end

function ActorStopEvent:run(connection)
	if not connection:getIsServer(connection) then
        Event.send(ActorStopEvent:new(self.actorName), true);
	end
	if g_spectatorMode ~= nil then
        g_spectatorMode:actorStartStopEvent(false, self.actorName);
    end
end
