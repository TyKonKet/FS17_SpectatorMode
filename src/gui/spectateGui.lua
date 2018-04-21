--
-- SpectatorMode
--
-- @author TyKonKet
-- @date 23/12/2016
SpectateGui = {}
local SpectateGui_mt = Class(SpectateGui, ScreenElement)

function SpectateGui:new(target, custom_mt)
	if custom_mt == nil then
		custom_mt = SpectateGui_mt
	end

	local self = ScreenElement:new(target, custom_mt)
	self.returnScreenName = ""
	self.selectedState = 1
	self.areButtonsDisabled = false
	return self
end

function SpectateGui:onOpen()
	SpectateGui:superClass().onOpen(self)
	FocusManager:setFocus(self.spectateButton)
end

function SpectateGui:onClickActivate()
	SpectateGui:superClass().onClickActivate(self)
	if self.areButtonsDisabled then
		return
	end
	g_spectatorMode:startSpectate(self.selectedState)
	self.onClickBack(self)
end

function SpectateGui:onClickSpectableUsers(state)
	self.selectedState = state
end

function SpectateGui:setSpectableUsers(users)
	if #users == 0 then
		self:setDisabled(true)
		self.messageBackground:setVisible(true)
		self.spectableUsersElement:setTexts({})
		self.spectableUsersElement:setState(0)
	else
		self:setDisabled(false)
		self.messageBackground:setVisible(false)
		self.users = users
		self.spectableUsersElement:setTexts(users)
		self.spectableUsersElement:setState(self.selectedState)
		self:onClickSpectableUsers(self.selectedState)
	end
end

function SpectateGui:setDisabled(disabled)
	self.areButtonsDisabled = disabled
	self.spectateButton:setDisabled(disabled)
	self.spectableUsersElement:setDisabled(disabled)
end
