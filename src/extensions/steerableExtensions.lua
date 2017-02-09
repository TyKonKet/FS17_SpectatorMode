--
-- SpectatorMode
--
-- @author TyKonKet
-- @date 20/01/2017
SteerableExtensions = {};

function SteerableExtensions:postLoad(savegame)
    self.camerasLerp = {};
    for _, v in pairs(self.cameras) do
        self.camerasLerp[v.cameraNode] = {};
        self.camerasLerp[v.cameraNode].lastQuaternion = {0, 0, 0, 0};
        self.camerasLerp[v.cameraNode].targetQuaternion = {0, 0, 0, 0};
        self.camerasLerp[v.cameraNode].lastTranslation = {0, 0, 0};
        self.camerasLerp[v.cameraNode].targetTranslation = {0, 0, 0};
        self.camerasLerp[v.cameraNode].interpolationAlphaRot = 0;
    end
end

function SteerableExtensions:setActiveCameraIndex(index)
    local cameraType = CameraChangeEvent.CAMERA_TYPE_VEHICLE;
    if self.activeCamera.isInside then
        cameraType = CameraChangeEvent.CAMERA_TYPE_VEHICLE_INDOOR;
    end
    Event.send(CameraChangeEvent:new(g_currentMission.player.controllerName, self.activeCamera.cameraNode, self.camIndex, cameraType));
end

function SteerableExtensions:writeUpdateStream(streamId, connection, dirtyMask)
    local sm = g_spectatorMode;
    --sm:print("writeUpdateStream()");
    local printText = "";
    if self.isServer then
        for _, v in pairs(self.cameras) do
            streamWriteFloat32(streamId, self.camerasLerp[v.cameraNode].targetQuaternion[1]);
            streamWriteFloat32(streamId, self.camerasLerp[v.cameraNode].targetQuaternion[2]);
            streamWriteFloat32(streamId, self.camerasLerp[v.cameraNode].targetQuaternion[3]);
            streamWriteFloat32(streamId, self.camerasLerp[v.cameraNode].targetQuaternion[4]);
            streamWriteFloat32(streamId, self.camerasLerp[v.cameraNode].targetTranslation[1]);
            streamWriteFloat32(streamId, self.camerasLerp[v.cameraNode].targetTranslation[2]);
            streamWriteFloat32(streamId, self.camerasLerp[v.cameraNode].targetTranslation[3]);
        end
    else
        for _, v in pairs(self.cameras) do
            local x, y, z, w = getQuaternion(v.rotateNode);
            streamWriteFloat32(streamId, x);
            streamWriteFloat32(streamId, y);
            streamWriteFloat32(streamId, z);
            streamWriteFloat32(streamId, w);
            --printText = string.format("Data written: rx:%s, ry:%s, rz:%s, rw:%s, ", x, y, z, w);
            x, y, z = getTranslation(v.cameraPositionNode);
            streamWriteFloat32(streamId, x);
            streamWriteFloat32(streamId, y);
            streamWriteFloat32(streamId, z);
        --printText = printText .. string.format("tx:%s,  ty:%s, tz:%s", x, y, z);
        --if self.configFileName == "data/vehicles/steerable/newHolland/newHolland8340.xml" and g_spectatorMode.printWUS then
        --sm:print(printText);
        --end
        end
    end
--if self.configFileName == "data/vehicles/steerable/newHolland/newHolland8340.xml" and g_spectatorMode.printWUS then -- and not self.isServer
--g_spectatorMode.printWUS = false;
--end
end

function SteerableExtensions:readUpdateStream(streamId, timestamp, connection)
    local sm = g_spectatorMode;
    --sm:print("readUpdateStream()");
    for _, v in pairs(self.cameras) do
        local x, y, z, w, tx, ty, tz = 0;
        x = streamReadFloat32(streamId);
        y = streamReadFloat32(streamId);
        z = streamReadFloat32(streamId);
        w = streamReadFloat32(streamId);
        tx = streamReadFloat32(streamId);
        ty = streamReadFloat32(streamId);
        tz = streamReadFloat32(streamId);
        self.camerasLerp[v.cameraNode].lastQuaternion = {getQuaternion(v.rotateNode)};
        self.camerasLerp[v.cameraNode].targetQuaternion = {x, y, z, w};
        self.camerasLerp[v.cameraNode].lastTranslation = {getTranslation(v.cameraPositionNode)};
        self.camerasLerp[v.cameraNode].targetTranslation = {tx, ty, tz};
        self.camerasLerp[v.cameraNode].interpolationAlphaRot = 0;
    --sm:print(("Data read: rx:%s, ry:%s, rz:%s, rw:%s, tx:%s, ty:%s, tz:%s"):format(x, y, z, w, tx, ty, tz));
    end
end

function SteerableExtensions:update(dt)
    --local sm = g_spectatorMode;
    if not self.isServer and self.isControlled and not self.isEntered then
        for _, v in pairs(self.cameras) do
            self.camerasLerp[v.cameraNode].interpolationAlphaRot = self.camerasLerp[v.cameraNode].interpolationAlphaRot + g_physicsDtUnclamped / 75;
            if self.camerasLerp[v.cameraNode].interpolationAlphaRot > 1 then
                self.camerasLerp[v.cameraNode].interpolationAlphaRot = 1;
            end

            local rx, ry, rz, rw = Utils.nlerpQuaternionShortestPath(self.camerasLerp[v.cameraNode].lastQuaternion[1], self.camerasLerp[v.cameraNode].lastQuaternion[2], self.camerasLerp[v.cameraNode].lastQuaternion[3], self.camerasLerp[v.cameraNode].lastQuaternion[4], self.camerasLerp[v.cameraNode].targetQuaternion[1], self.camerasLerp[v.cameraNode].targetQuaternion[2], self.camerasLerp[v.cameraNode].targetQuaternion[3], self.camerasLerp[v.cameraNode].targetQuaternion[4], self.camerasLerp[v.cameraNode].interpolationAlphaRot);
            setQuaternion(v.rotateNode, rx, ry, rz, rw);
            --sm:print(string.format("isInside:%s", v.isInside));
            --sm:print(string.format("setQuaternion(v.rotateNode, rx:%s, ry:%s, rz:%s, rw:%s)", rx, ry, rz, rw));
            local tx, ty, tz = Utils.vector3Lerp(self.camerasLerp[v.cameraNode].lastTranslation[1], self.camerasLerp[v.cameraNode].lastTranslation[2], self.camerasLerp[v.cameraNode].lastTranslation[3], self.camerasLerp[v.cameraNode].targetTranslation[1], self.camerasLerp[v.cameraNode].targetTranslation[2], self.camerasLerp[v.cameraNode].targetTranslation[3], self.camerasLerp[v.cameraNode].interpolationAlphaRot);
            setTranslation(v.cameraPositionNode, tx, ty, tz);
            --sm:print(string.format("setTranslation(v.cameraPositionNode, tx:%s, ty:%s, tz:%s)", tx, ty, tz));

            if v.rotateNode ~= v.cameraPositionNode then
                local wtx, wty, wtz = getWorldTranslation(v.cameraPositionNode);
                local dx = wtx;
                local dy = wty;
                local dz = wtz;
                wtx, wty, wtz = getWorldTranslation(v.rotateNode);
                dx = dx - wtx;
                dy = dy - wty;
                dz = dz - wtz;
                local upx, upy, upz = 0, 1, 0;
                if math.abs(dx) < 0.001 and math.abs(dz) < 0.001 then
                    upx = 0.1;
                end       
                setDirection(v.cameraNode, dx, dy, dz, upx, upy, upz);
            else
                local wrx, wry, wrz, wrw = getWorldQuaternion(v.rotateNode);
                setQuaternion(v.cameraNode, wrx, wry, wrz, wrw);
            end
            local wtx, wty, wtz = getWorldTranslation(v.cameraPositionNode);
            setTranslation(v.cameraNode, wtx, wty, wtz);
        end
    end
end
