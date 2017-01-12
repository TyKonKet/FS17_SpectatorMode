--
-- SpectatorMode script
--
--
-- @author TyKonKet
-- @date 04/01/2017

ActorDataEvent = {};
ActorDataEvent_mt = Class(ActorDataEvent, Event);

InitEventClass(ActorDataEvent, "ActorDataEvent");

function ActorDataEvent:emptyNew()
    local self = Event:new(ActorDataEvent_mt);
    return self;
end

function ActorDataEvent:new(actorName, tx, ty, tz, rx, ry, rz, rw, fovy)
    local self = ActorDataEvent:emptyNew();
    self.actorName = actorName;
    self.tx = tx;
    self.ty = ty;
    self.tz = tz;
    self.rx = rx;
    self.ry = ry;
    self.rz = rz;
    self.rw = rw;
    self.fovy = fovy;
    return self;
end

function ActorDataEvent:readStream(streamId, connection)
    self.actorName = streamReadString(streamId);
    self.tx = streamReadFloat32(streamId);
    self.ty = streamReadFloat32(streamId);
    self.tz = streamReadFloat32(streamId);
    self.rx = streamReadFloat32(streamId);
    self.ry = streamReadFloat32(streamId);
    self.rz = streamReadFloat32(streamId);
    self.rw = streamReadFloat32(streamId);
    self.fovy = streamReadFloat32(streamId);
    self:run(connection);
end

function ActorDataEvent:writeStream(streamId, connection)
	streamWriteString(streamId, self.actorName);
    streamWriteFloat32(streamId, self.tx);
    streamWriteFloat32(streamId, self.ty);
    streamWriteFloat32(streamId, self.tz);
    streamWriteFloat32(streamId, self.rx);
    streamWriteFloat32(streamId, self.ry);
    streamWriteFloat32(streamId, self.rz);
    streamWriteFloat32(streamId, self.rw);
     streamWriteFloat32(streamId, self.fovy);
end

function ActorDataEvent:run(connection)
	if not connection:getIsServer(connection) then
        Event.send(self, true, connection);
	end
    if g_spectatorMode ~= nil then
        g_spectatorMode:actorDataEventF(self.actorName, self.tx, self.ty, self.tz, self.rx, self.ry, self.rz, self.rw, self.fovy);
    end
end
