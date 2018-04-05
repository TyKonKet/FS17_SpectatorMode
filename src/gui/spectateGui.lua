SpectateGui = {};
local SpectateGui_mt = Class(SpectateGui, ScreenElement);

function SpectateGui:new(target, custom_mt)
	if custom_mt == nil then
		custom_mt = SpectateGui_mt;
	end

	local self = ScreenElement:new(target, custom_mt);
	self.returnScreenName = "";
	self.selectedUser = nil;
	self.selectedState = 1;
	self.areButtonsDisabled = false;
	return self;
end

function SpectateGui:onOpen()
	SpectateGui:superClass().onOpen(self);
	FocusManager:setFocus(self.spectateButton);
end

function SpectateGui:onClickActivate()
	SpectateGui:superClass().onClickActivate(self);
	if self.areButtonsDisabled then
		return;
	end
	if self.onSelectCallback ~= nil then
		if self.target ~= nil then
			self.onSelectCallback(self.target, self.selectedUser);
		else
			self.onSelectCallback(self.selectedUser);
		end
	end
	self.onClickBack(self);
end

function SpectateGui:setSelectionCallback(target, onSelectCallback)
	self.onSelectCallback = onSelectCallback;
	self.target = target;
end

function SpectateGui:onClickSpectableUsers(state)
	local i = 1;
	for k, v in pairs(self.users) do
		if i == state then
			self.selectedUser = v;
			break
		end
		i = i + 1;
	end
	self.selectedState = state;
end

function SpectateGui:setSpectableUsers(users)
	if #users == 0 then
		self:setDisabled(true);
		self.messageBackground:setVisible(true);
		self.spectableUsersElement:setTexts({});
		self.spectableUsersElement:setState(0);
	else
		self:setDisabled(false);
		self.messageBackground:setVisible(false);
		self.users = users;
		self.spectableUsersElement:setTexts(users);
		self.spectableUsersElement:setState(self.selectedState);
		self:onClickSpectableUsers(self.selectedState);
	end
end

function SpectateGui:setDisabled(disabled)
	self.areButtonsDisabled = disabled;
	self.spectateButton:setDisabled(disabled);
	self.spectableUsersElement:setDisabled(disabled);
end
