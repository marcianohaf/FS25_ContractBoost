---@class Settings
---This class stores settings for the ContractBoost mod
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
        self.settings[settingParent][settingName] = newState
    else 
        self.settings[settingName] = newState
    end
    self:publishNewSettings()
end

---Retrieves the stored setting by name
---@param settingName string @The name of the setting
---@param settingParent string @The name of the parent of the setting
---@return string|boolean @The current index
function Settings:getSetting(settingName, settingParent)
    if settingParent then
        return self.settings[settingParent][settingName]
    else
        return self.settings[settingName]
    end
end

---Retrieves the all settings at once
---@return table @The current index
function Settings:getSettings()
    return self.settings
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
    --self.settings = streamReadInt8(streamId)
end

---Sends the current settings to a client which is connecting to a multiplayer game
---@param streamId any @The ID of the stream to write to
---@param connection any @Unused
function Settings:onWriteStream(streamId, connection)
    Logging.info(MOD_NAME .. ": Sending new settings", streamId)
    --streamWriteInt8(streamId, self.settings)
end