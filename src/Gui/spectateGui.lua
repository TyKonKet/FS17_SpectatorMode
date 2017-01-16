SpectateGui = {}
local SpectateGui_mt = Class(SpectateGui, ScreenElement);

function SpectateGui:new(target, custom_mt)
	if custom_mt == nil then
		custom_mt = SpectateGui_mt;
	end

	local self = ScreenElement:new(target, custom_mt)
    self.returnScreenName = ""
	self.selectedUser = nil;
	self.selectedState = 1;
	self.areButtonsDisabled = false;
	return self;
end

function SpectateGui:onCreateDialogTitle(element)
	element:setText(g_i18n:getText("SPECTATOR_MODE_NAME"));
end

function SpectateGui:onCreateDialogText(element)
	element:setText(g_i18n:getText("SPECTATOR_MODE_GUI_DIALOG_TEXT") .. ":");
end

function SpectateGui:onCreateMessageBackground(element)
	self.messageBackground = element;
end

function SpectateGui:onCreateMessage(element)
	element:setText(g_i18n:getText("SPECTATOR_MODE_GUI_DIALOG_MESSAGE"));
end

function SpectateGui:onCreateSpectateButtonConsole(element)
	self.spectateButtonConsole = element;
end

function SpectateGui:onCreateSpectateButton(element)
	self.spectateButton = element;
end

function SpectateGui:onClickActivate()
	SpectateGui:superClass():onClickActivate();

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
  			break;
  		end
  		i = i + 1;
  	end
  
  	self.selectedState = state;
end

function SpectateGui:setSpectableUsers(users)
	if #users == 0 then
		self:setDisabled(true);
		self.messageBackground:setVisible(true);
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
	self.spectateButtonConsole:setDisabled(disabled);
	self.spectableUsersElement:setDisabled(disabled);
end
