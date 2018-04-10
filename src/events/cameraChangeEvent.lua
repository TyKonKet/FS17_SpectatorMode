--
-- SpectatorMode
--
-- @author TyKonKet
-- @date 23/01/2017

CameraChangeEvent = {}
CameraChangeEvent.CAMERA_TYPE_PLAYER = 0
CameraChangeEvent.CAMERA_TYPE_VEHICLE = 1
CameraChangeEvent.CAMERA_TYPE_VEHICLE_INDOOR = 2
CameraChangeEvent.CAMERA_TYPES = 3
CameraChangeEvent.cameraTypeSendNumBits = Utils.getNumBits(CameraChangeEvent.CAMERA_TYPES)
CameraChangeEvent.cameraIndexSendNumBits = Utils.getNumBits(8)
CameraChangeEvent_mt = Class(CameraChangeEvent, Event)

InitEventClass(CameraChangeEvent, "CameraChangeEvent")

function CameraChangeEvent:emptyNew()
    local self = Event:new(CameraChangeEvent_mt)
    return self
end

function CameraChangeEvent:new(actorName, cameraId, cameraIndex, cameraType)
    local self = CameraChangeEvent:emptyNew()
    self.actorName = actorName
    self.cameraId = cameraId
    self.cameraIndex = cameraIndex
    self.cameraType = cameraType
    return self
end

function CameraChangeEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, self.cameraId)
    streamWriteUIntN(streamId, self.cameraIndex, CameraChangeEvent.cameraIndexSendNumBits)
    streamWriteUIntN(streamId, self.cameraType, CameraChangeEvent.cameraTypeSendNumBits)
    streamWriteString(streamId, self.actorName)
end

function CameraChangeEvent:readStream(streamId, connection)
    self.cameraId = streamReadInt32(streamId)
    self.cameraIndex = streamReadUIntN(streamId, CameraChangeEvent.cameraIndexSendNumBits)
    self.cameraType = streamReadUIntN(streamId, CameraChangeEvent.cameraTypeSendNumBits)
    self.actorName = streamReadString(streamId)
    self:run(connection)
end

function CameraChangeEvent:run(connection)
    if (not connection:getIsServer() or connection:getIsLocal()) then
        if g_spectatorMode ~= nil and g_spectatorMode.server ~= nil then
            g_spectatorMode.server:cameraChange(self.actorName, self.cameraId, self.cameraIndex, self.cameraType)
        end
    else
        if g_spectatorMode ~= nil then
            g_spectatorMode:cameraChanged(self.actorName, self.cameraId, self.cameraIndex, self.cameraType)
        end
    end
end
