--
-- SpectatorMode
--
-- @author TyKonKet
-- @date 09/02/2017

VehicleExtensions = {}

function VehicleExtensions:isSpectated()
    if g_spectatorMode ~= nil then
        if g_spectatorMode.spectating and self.controllerName == g_spectatorMode.spectatedPlayer then
            return true
        end
    end
    return false
end
