--
-- SpectatorMode
--
-- @author TyKonKet
-- @date 20/01/2017

SteerableExtensions = {};

function SteerableExtensions:setActiveCameraIndex(index)
    local cameraType = CameraChangeEvent.CAMERA_TYPE_VEHICLE;
    if self.activeCamera.isInside then
        cameraType = CameraChangeEvent.CAMERA_TYPE_VEHICLE_INDOOR;
    end
    Event.send(CameraChangeEvent:new(g_currentMission.player.controllerName, self.activeCamera.cameraNode, self.camIndex, cameraType));
end
