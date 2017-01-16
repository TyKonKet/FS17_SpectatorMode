--
-- SpectatorMode script
--
--
-- @author TyKonKet
-- @date 03/01/2017

ActorStartEvent = {};
ActorStartEvent_mt = Class(ActorStartEvent, Event);

InitEventClass(ActorStartEvent, "ActorStartEvent");

function ActorStartEvent:emptyNew()
    local self = Event:new(ActorStartEvent_mt);
    return self;
end

function ActorStartEvent:new(actorName)
    local self = ActorStartEvent:emptyNew();
    self.actorName = actorName;
    return self;
end

function ActorStartEvent:readStream(streamId, connection)
    self.actorName = streamReadString(streamId);
    self:run(connection);
end

function ActorStartEvent:writeStream(streamId, connection)
	streamWriteString(streamId, self.actorName);
end

function ActorStartEvent:run(connection)
	if not connection:getIsServer(connection) then
        Event.send(ActorStartEvent:new(self.actorName), true);
	end
    if g_spectatorMode ~= nil then
        g_spectatorMode:actorStartStopEvent(true, self.actorName);
    end
end
