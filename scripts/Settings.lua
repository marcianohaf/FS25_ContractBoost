---@class Settings
---This class stores settings for the ContractBoost mod
Settings = {}
local Settings_mt = Class(Settings)

---Creates a new settings instance
---@return table @The new instance
function Settings.new()
    local self = setmetatable({}, Settings_mt)
    self.settings = {}
    return self
end

---Stores the setting into the local opbject
---@param settingName string @The name of the setting, in dot notation for nested settings
---@param newState string|number|boolean @The new value
---@param settingName string @The name of the setting, in dot notation for nested settings
function Settings:onSettingChanged(settingName, newState, settingParent)
    if settingParent then
        self[settingParent][settingName] = newState
    else
        self[settingName] = newState
    end
    self:publishNewSettings()
end

---Retrieves the stored setting by name
---@param settingName string @The name of the setting
---@param settingParent string @The name of the parent of the setting
---@return string|boolean @The current index
function Settings:getSetting(settingName, settingParent)
    if settingParent then
        return self[settingParent][settingName]
    else
        return self[settingName]
    end
end

---Retrieves the all settings at once
---@return table @The current index
function Settings:getSettings()
    return self
end

---Publishes new settings in case of multiplayer
function Settings:publishNewSettings()
    if g_server ~= nil then
        -- Broadcast to other clients, if any are connected
        g_server:broadcastEvent(SettingsChangeEvent.new())
    else
        -- Ask the server to broadcast the event
        g_client:getServerConnection():sendEvent(SettingsChangeEvent.new())
    end
end

---Recevies the initial settings from the server when joining a multiplayer game
---@param streamId any @The ID of the stream to read from
---@param connection any @Unused
function Settings:onReadStream(streamId, connection)
    Logging.info(MOD_NAME .. ": Receiving new settings", streamId)

    self.debugMode = streamReadBool(streamId)
    self.enableContractValueOverrides = streamReadBool(streamId)
    self.enableStrawFromHarvestMissions = streamReadBool(streamId)
    self.enableSwathingForHarvestMissions = streamReadBool(streamId)
    self.enableGrassFromMowingMissions = streamReadBool(streamId)
    self.enableHayFromTedderMissions = streamReadBool(streamId)
    self.enableStonePickingFromMissions = streamReadBool(streamId)
    self.enableFieldworkToolFillItems = streamReadBool(streamId)
    self.enableCollectingBalesFromMissions = streamReadBool(streamId)

    self.rewardFactor = streamReadFloat32(streamId)
    self.maxContractsPerFarm = streamReadInt16(streamId)
    self.maxContractsPerType = streamReadInt16(streamId)
    self.maxContractsOverall = streamReadInt16(streamId)

    self.customRewards = {}
    for _, missionType in SettingsManager.missionTypes do
        if streamReadBool(streamId) then
            self.customRewards[missionType] = streamReadInt16(streamId)
        else
            self.customRewards[missionType] = nil
        end
    end

    self.customMaxPerType = {}
    for _, missionType in SettingsManager.missionTypes do
        if streamReadBool(streamId) then
            self.customMaxPerType[missionType] = streamReadInt16(streamId)
        else
            self.customMaxPerType[missionType] = nil
        end
    end

    Logging.info(MOD_NAME .. ": Completed recieving new settings", streamId)
    DebugUtil.printTableRecursively(self)
end

---Sends the current settings to a client which is connecting to a multiplayer game
---@param streamId any @The ID of the stream to write to
---@param connection any @Unused
function Settings:onWriteStream(streamId, connection)
    Logging.info(MOD_NAME .. ": Sending new settings", streamId)
    --streamWriteInt8(streamId, self.settings)

    streamWriteBool(streamId, self.debugMode)
    streamWriteBool(streamId, self.enableContractValueOverrides)
    streamWriteBool(streamId, self.enableStrawFromHarvestMissions)
    streamWriteBool(streamId, self.enableSwathingForHarvestMissions)
    streamWriteBool(streamId, self.enableGrassFromMowingMissions)
    streamWriteBool(streamId, self.enableHayFromTedderMissions)
    streamWriteBool(streamId, self.enableStonePickingFromMissions)
    streamWriteBool(streamId, self.enableFieldworkToolFillItems)
    streamWriteBool(streamId, self.enableCollectingBalesFromMissions)

    streamWriteFloat32(streamId, self.rewardFactor)
    streamWriteInt16(streamId, self.maxContractsPerFarm)
    streamWriteInt16(streamId, self.maxContractsPerType)
    streamWriteInt16(streamId, self.maxContractsOverall)

    for _, missionType in SettingsManager.missionTypes do
        if streamWriteBool(streamId, self.customRewards[missionType] ~= nil) then
            streamWriteInt16(streamId, self.customRewards[missionType])
        end
    end

    for _, missionType in SettingsManager.missionTypes do
        if streamWriteBool(streamId, self.customMaxPerType[missionType] ~= nil) then
            streamWriteInt16(streamId, self.customMaxPerType[missionType])
        end
    end

    Logging.info(MOD_NAME .. ": Completed sending new settings", streamId)
end