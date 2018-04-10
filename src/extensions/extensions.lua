--
-- SpectatorMode
--
-- @author TyKonKet
-- @date 03/01/2017

-- Event methods extension

function Event.sendToServer(event)
    g_client:getServerConnection():sendEvent(event)
end

-- Utils methods extension

function Utils.getNumBits(range)
    return math.min(math.max(math.ceil(math.log(range, 2)), 1), 31)
end
