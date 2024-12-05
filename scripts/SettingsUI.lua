---This class is responsible for adding UI settings and mapping them to the existing settings variables
---@class SettingsUI
---@field sectionTitle table @The UI control which displays the section title
---@field controls table @A list of UI controls
---@field loadedConfig table @A reference to the loaded configuration object
---@field enableContractValueOverrides table @A UI control
---@field rewardFactor table @A UI control
---@field maxContractsPerFarm table @A UI control
---@field maxContractsPerType table @A UI control
---@field maxContractsOverall table @A UI control
---@field enableStrawFromHarvestMissions table @A UI control
---@field enableSwathingForHarvestMissions table @A UI control
---@field enableGrassFromMowingMissions table @A UI control
---@field enableStonePickingFromMissions table @A UI control
---@field enableFieldworkToolFillItems table @A UI control
---@field baleMissionReward table @A UI control
---@field baleWrapMissionReward table @A UI control
---@field treeTransportMissionReward table @A UI control
SettingsUI = {
}

-- Create a meta table to get basic Class-like behavior
local SettingsUI_mt = Class(SettingsUI)

---Creates the settings UI object
---@return SettingsUI @The new object
function SettingsUI.new()
	local self = setmetatable({}, SettingsUI_mt)

	self.controls = {}
	self.loadedConfig = nil
	self.isInitialized = false

	return self
end

---Injects the UI controls into the general settings menu
---@param loadedConfig table @The loaded config
function SettingsUI:injectUiSettings(loadedConfig)
	-- Remember the settings object
	self.loadedConfig = loadedConfig

	if self.isInitialized then
		return
	end
	self.isInitialized = true

	-- Get a reference to the base game general settings page
	local settingsPage = g_gui.screenControllers[InGameMenu].pageSettings

	-- Define the UI controls. For bool values, supply just the name, for ranges, supply min, max and step, and for choices, supply a values table
	-- For every name, a <prefix>_<name>_long and _short text must exist in the l10n files
	-- The _short text will be the title of the setting, the _long" text will be its tool tip
	-- For each control, a on_<name>_changed callback will be called on change
	local controlProperties = {
		{ name = "enableContractValueOverrides" },
		{ name = "rewardFactor", min = 0.5, max = 5.0, step = 0.1 },
		{ name = "maxContractsPerFarm", values = { 1, 2, 3, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 } },
		{ name = "maxContractsPerType", min = 1, max = 20, step = 1 },
		{ name = "maxContractsOverall", values = { 1, 2, 3, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 } },
		{ name = "enableStrawFromHarvestMissions" },
		{ name = "enableSwathingForHarvestMissions" },
		{ name = "enableGrassFromMowingMissions" },
		{ name = "enableStonePickingFromMissions" },
		{ name = "enableFieldworkToolFillItems" },
		{ name = "baleMissionReward", nillable = true, min = 0, max = 10000, step = 500 },
		{ name = "baleWrapMissionReward", nillable = true, min = 0, max = 10000, step = 500 },
		{ name = "treeTransportMissionReward", nillable = true, min = 0, max = 10000, step = 500 }
	}
	UIHelper.createControlsDynamically(settingsPage, "contract_boosted", self, controlProperties, "cb_")

	-- Apply initial values
	self:updateUiElements()

	-- Update the settings controls whenever the frame gets opened
	InGameMenuSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuSettingsFrame.onFrameOpen, function()
		self:updateUiElements()
	end)
end

---Updates the UI elements to reflect the current settings
function SettingsUI:updateUiElements()
	UIHelper.setBoolValue(self.enableContractValueOverrides,self.loadedConfig.enableContractValueOverrides)
	UIHelper.setRangeValue(self.rewardFactor, self.loadedConfig.rewardFactor)
	UIHelper.setChoiceValue(self.maxContractsPerFarm, self.loadedConfig.maxContractsPerFarm)
	UIHelper.setRangeValue(self.maxContractsPerType, self.loadedConfig.maxContractsPerType)
	UIHelper.setChoiceValue(self.maxContractsOverall, self.loadedConfig.maxContractsOverall)
	UIHelper.setBoolValue(self.enableStrawFromHarvestMissions, self.loadedConfig.enableStrawFromHarvestMissions)
	UIHelper.setBoolValue(self.enableSwathingForHarvestMissions, self.loadedConfig.enableSwathingForHarvestMissions)
	UIHelper.setBoolValue(self.enableGrassFromMowingMissions, self.loadedConfig.enableGrassFromMowingMissions)
	UIHelper.setBoolValue(self.enableStonePickingFromMissions, self.loadedConfig.enableStonePickingFromMissions)
	UIHelper.setBoolValue(self.enableFieldworkToolFillItems, self.loadedConfig.enableFieldworkToolFillItems)
	UIHelper.setRangeValue(self.baleMissionReward, self.loadedConfig.customRewards.baleMission)
	UIHelper.setRangeValue(self.baleWrapMissionReward, self.loadedConfig.customRewards.baleWrapMission)
	UIHelper.setRangeValue(self.treeTransportMissionReward, self.loadedConfig.customRewards.treeTransportMission)

	-- Disable all other settings if requested
	for _, control in ipairs(self.controls) do
		if control ~= self.enableContractValueOverrides then
			control:setDisabled(not self.loadedConfig.enableContractValueOverrides)
		end
	end

	-- Update the focus manager
	local settingsPage = g_gui.screenControllers[InGameMenu].pageSettings
	settingsPage.generalSettingsLayout:invalidateLayout()
end

function SettingsUI:on_enableContractValueOverrides_changed(newState)
	self.loadedConfig.enableContractValueOverrides = UIHelper.getBoolValue(newState)
	self:updateUiElements()
end