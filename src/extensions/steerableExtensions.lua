--
-- SpectatorMode
--
-- @author TyKonKet
-- @date 20/01/2017
SteerableExtensions = {}

function SteerableExtensions:postLoad(savegame)
    self.camerasLerp = {}
    for _, v in pairs(self.cameras) do
        self.camerasLerp[v.cameraNode] = {}
        self.camerasLerp[v.cameraNode].lastQuaternion = {0, 0, 0, 0}
        self.camerasLerp[v.cameraNode].targetQuaternion = {0, 0, 0, 0}
        self.camerasLerp[v.cameraNode].lastTranslation = {0, 0, 0}
        self.camerasLerp[v.cameraNode].targetTranslation = {0, 0, 0}
        self.camerasLerp[v.cameraNode].interpolationAlphaRot = 0
    end
end

function SteerableExtensions:setActiveCameraIndex(index)
    if not g_spectatorMode.spectating then
        local cameraType = CameraChangeEvent.CAMERA_TYPE_VEHICLE
        if self.activeCamera.isInside then
            cameraType = CameraChangeEvent.CAMERA_TYPE_VEHICLE_INDOOR
        end
        g_spectatorMode:print("Steerable.send(CameraChangeEvent:new(controllerName:%s, cameraNode:%s, camIndex:%s, cameraType:%s, toServer:true))", g_currentMission.player.controllerName, self.activeCamera.cameraNode, self.camIndex, cameraType)
        Event.sendToServer(CameraChangeEvent:new(g_currentMission.player.controllerName, self.activeCamera.cameraNode, self.camIndex, cameraType, true))
    end
end

function SteerableExtensions:writeUpdateStream(streamId, connection, dirtyMask)
    if self.isServer then
        for _, v in pairs(self.cameras) do
            streamWriteFloat32(streamId, self.camerasLerp[v.cameraNode].targetQuaternion[1])
            streamWriteFloat32(streamId, self.camerasLerp[v.cameraNode].targetQuaternion[2])
            streamWriteFloat32(streamId, self.camerasLerp[v.cameraNode].targetQuaternion[3])
            streamWriteFloat32(streamId, self.camerasLerp[v.cameraNode].targetQuaternion[4])
            streamWriteFloat32(streamId, self.camerasLerp[v.cameraNode].targetTranslation[1])
            streamWriteFloat32(streamId, self.camerasLerp[v.cameraNode].targetTranslation[2])
            streamWriteFloat32(streamId, self.camerasLerp[v.cameraNode].targetTranslation[3])
        end
    else
        for _, v in pairs(self.cameras) do
            local x, y, z, w = getQuaternion(v.rotateNode)
            streamWriteFloat32(streamId, x)
            streamWriteFloat32(streamId, y)
            streamWriteFloat32(streamId, z)
            streamWriteFloat32(streamId, w)
            x, y, z = getTranslation(v.cameraPositionNode)
            streamWriteFloat32(streamId, x)
            streamWriteFloat32(streamId, y)
            streamWriteFloat32(streamId, z)
        end
    end
end

function SteerableExtensions:readUpdateStream(streamId, timestamp, connection)
    for _, v in pairs(self.cameras) do
        local x, y, z, w, tx, ty, tz = 0
        x = streamReadFloat32(streamId)
        y = streamReadFloat32(streamId)
        z = streamReadFloat32(streamId)
        w = streamReadFloat32(streamId)
        tx = streamReadFloat32(streamId)
        ty = streamReadFloat32(streamId)
        tz = streamReadFloat32(streamId)
        self.camerasLerp[v.cameraNode].lastQuaternion = {getQuaternion(v.rotateNode)}
        self.camerasLerp[v.cameraNode].targetQuaternion = {x, y, z, w}
        self.camerasLerp[v.cameraNode].lastTranslation = {getTranslation(v.cameraPositionNode)}
        self.camerasLerp[v.cameraNode].targetTranslation = {tx, ty, tz}
        self.camerasLerp[v.cameraNode].interpolationAlphaRot = 0
    end
end

function SteerableExtensions:update(dt)
    if not self.isServer and self.isControlled and not self.isEntered then
        for _, v in pairs(self.cameras) do
            self.camerasLerp[v.cameraNode].interpolationAlphaRot = self.camerasLerp[v.cameraNode].interpolationAlphaRot + g_physicsDtUnclamped / 75
            if self.camerasLerp[v.cameraNode].interpolationAlphaRot > 1 then
                self.camerasLerp[v.cameraNode].interpolationAlphaRot = 1
            end

            local rx, ry, rz, rw =
                Utils.nlerpQuaternionShortestPath(
                self.camerasLerp[v.cameraNode].lastQuaternion[1],
                self.camerasLerp[v.cameraNode].lastQuaternion[2],
                self.camerasLerp[v.cameraNode].lastQuaternion[3],
                self.camerasLerp[v.cameraNode].lastQuaternion[4],
                self.camerasLerp[v.cameraNode].targetQuaternion[1],
                self.camerasLerp[v.cameraNode].targetQuaternion[2],
                self.camerasLerp[v.cameraNode].targetQuaternion[3],
                self.camerasLerp[v.cameraNode].targetQuaternion[4],
                self.camerasLerp[v.cameraNode].interpolationAlphaRot
            )
            if rx == rx and ry == ry and rz == rz and rw == rw then
                setQuaternion(v.rotateNode, rx, ry, rz, rw)
            end
            local tx, ty, tz =
                Utils.vector3Lerp(
                self.camerasLerp[v.cameraNode].lastTranslation[1],
                self.camerasLerp[v.cameraNode].lastTranslation[2],
                self.camerasLerp[v.cameraNode].lastTranslation[3],
                self.camerasLerp[v.cameraNode].targetTranslation[1],
                self.camerasLerp[v.cameraNode].targetTranslation[2],
                self.camerasLerp[v.cameraNode].targetTranslation[3],
                self.camerasLerp[v.cameraNode].interpolationAlphaRot
            )
            if tx == tx and ty == ty and tz == tz then
                setTranslation(v.cameraPositionNode, tx, ty, tz)
            end

            if v.rotateNode ~= v.cameraPositionNode then
                local wtx, wty, wtz = getWorldTranslation(v.cameraPositionNode)
                local dx = wtx
                local dy = wty
                local dz = wtz
                wtx, wty, wtz = getWorldTranslation(v.rotateNode)
                dx = dx - wtx
                dy = dy - wty
                dz = dz - wtz
                local upx, upy, upz = 0, 1, 0
                if math.abs(dx) < 0.001 and math.abs(dz) < 0.001 then
                    upx = 0.1
                end
                if math.abs(dx) > 0.0001 and math.abs(dy) > 0.0001 and math.abs(dz) > 0.0001 then
                    setDirection(v.cameraNode, dx, dy, dz, upx, upy, upz)
                end
            else
                local wrx, wry, wrz, wrw = getWorldQuaternion(v.rotateNode)
                setQuaternion(v.cameraNode, wrx, wry, wrz, wrw)
            end
            local wtx, wty, wtz = getWorldTranslation(v.cameraPositionNode)
            setTranslation(v.cameraNode, wtx, wty, wtz)
        end
    end
end

function SteerableExtensions:drawUIInfo(superFunc)
    if superFunc ~= nil then
        superFunc(self)
    end
    local spectated = self.isSpectated ~= nil
    if spectated then
        spectated = self:isSpectated()
    end
    if (not self.isEntered and not spectated) and self.isClient and self:getIsActive() and self.isControlled and not g_gui:getIsGuiVisible() and g_currentMission.showHudEnv then
        local x, y, z = getWorldTranslation(self.nicknameRenderNode)
        local x1, y1, z1 = getWorldTranslation(getCamera())
        local distSq = Utils.vector3LengthSq(x - x1, y - y1, z - z1)
        if distSq <= 100 * 100 then
            x = x + self.nicknameRenderNodeOffset[1]
            y = y + self.nicknameRenderNodeOffset[2]
            z = z + self.nicknameRenderNodeOffset[3]
            Utils.renderTextAtWorldPosition(x, y, z, self.controllerName, getCorrectTextSize(0.02), 0)
        end
    end
end
