--- XML Config Loader
-- @author GMNGjoy
-- @copyright 12/16/2024
-- @contact https://github.com/GMNGjoy/FS25_ContractBoost
-- @license CC0 1.0 Universal
---This class is responsible for loading User Settings
---@class SettingsManager
---@field loadComplete boolean @Have we loaded the configuration?
---@field loadDebug boolean @Is debugging turned on for this class
---@field defaultConfig table @default values for all settings
---@field loadedConfig table @loaded values for all settings
---@field modSettingsConfigFile string @depreciated user configuration filename previously located in modSettings 
---@field savegameConfigFile string @savegame configuration file
---@field xmlTag string @the root xml tag
---@field xmlSchema table @the configured xml schema
---@field missionTypes table @re-used set of mission types
SettingsManager = {}
local XMLTAG = "contractBoost"
SettingsManager.missionTypes = {
    "baleMission",
    "baleWrapMission",
    "plowMission",
    "cultivateMission",
    "sowMission",
    "harvestMission",
    "hoeMission",
    "weedMission",
    "herbicideMission",
    "fertilizeMission",
    "mowMission",
    "tedderMission",
    "stonePickMission",
    "deadwoodMission",
    "treeTransportMission",
    "destructibleRockMission"
}

-- Create a meta table to get basic Class-like behavior
local SettingsManager_mt = Class(SettingsManager)

---Creates the xml configuration manager object
---@return SettingsManager @The new object
function SettingsManager.new()
    local self = setmetatable({}, SettingsManager_mt)
    self.loadDebug = true

    -- configuration files and loading states
    self.loadComplete = false
    self.loadedConfig = {}

    -- defaultConfig for existing settings
    self.defaultConfig = {
        debugMode = true,
        rewardFactor = 1.5,
        maxContractsPerFarm = 10,
        maxContractsPerType = 5,
        maxContractsOverall = 50,
        enableContractValueOverrides = true,
        enableStrawFromHarvestMissions = true,
        enableSwathingForHarvestMissions = true,
        enableGrassFromMowingMissions = true,
        enableHayFromTedderMissions = true,
        enableStonePickingFromMissions = true,
        enableFieldworkToolFillItems = true,
        enableCollectingBalesFromMissions = false,
        customRewards = {},
        customMaxPerType = {},
    }

    -- xmlConfigFiles
    self.modSettingsConfigFile = "modSettings/`xml"
    self.savegameConfigFile = MOD_NAME..".xml"

    return self
end

--- Load the user's configuration file from either the savegame or modSettingsFile
---@return table
function SettingsManager:restoreSettings()
    if self.loadDebug then Logging.info(MOD_NAME..":LOAD :: read user configurations") end

    -- setup the xml schema
    self:initXmlSchema()

    -- don't load it twice if the config is already loaded.
    if self.loadComplete then
        if self.loadDebug then Logging.info(MOD_NAME..":LOAD :: exit early!") end
        return self.loadedConfig
    end

    -- determine the proper path for the user's settings file
    local modSettingsFile = self:getModSettingsXmlFilePath()
    local savegameSettingsFile = self.getSavegameXmlFilePath()

    -- pull the settings from memory if needed
    local settings = g_currentMission.contractBoostSettings
    if settings == nil or savegameSettingsFile == nil then
        Logging.warning(MOD_NAME .. ": Could not read settings since g_currentMission.unloadBalesEarlySettings is nil")
        return
    end

    -- Default is to load from the savegameSettingsFile
    if savegameSettingsFile and fileExists(savegameSettingsFile) then
        
        self:importConfig(savegameSettingsFile, settings)
        Logging.info(MOD_NAME..":LOAD :: SAVEGAME configuration from: %s | debug: %s", savegameSettingsFile, userConfig.debugMode and "true" or "false")
    
    -- If they loaded a previous version, they may have modSettings file
    elseif modSettingsFile and fileExists(modSettingsFile) then

        self:importConfig(modSettingsFile, settings)
        Logging.info(MOD_NAME..":LOAD :: MODSETTINGS configuration from: %s | debug: %s", modSettingsFile, userConfig.debugMode and "true" or "false")

    else
        settings = self.defaultConfig
        Logging.info(MOD_NAME..":LOAD: DEFAULT configuration used. | debug: %s", userConfig.debugMode and "true" or "false")
    end

    function logBoostSettings(t, indent)
        -- sort the table
        local tkeys = {}
        for k in pairs(t) do table.insert(tkeys, k) end
        table.sort(tkeys)

        -- print the table out
        local v = ""
        local key = ""
        for _, k in ipairs(tkeys) do
            v = t[k]
            key = string.rep("   ", indent) .. tostring(k)
            if type(v) == "table" then
                Logging.info(key .. ": ")
                logBoostSettings(v, indent + 1)
            else
                Logging.info(key .. " :: " .. tostring(v))
            end
        end
    end

    Logging.info('ContractBoost:LOAD :: config loaded')
    logBoostSettings(settings, 1)

    -- make sure we don't load it twice
    self.userConfigLoaded = true
    
    -- store the config just in case.
    self.loadedConfig = settings
end

--- Initiaze the XML file configuration
function SettingsManager:initXmlSchema()
    if self.loadDebug then Logging.info(MOD_NAME..":LOAD ::  init xml schema") end

    self.xmlSchema = XMLSchema.new(XMLTAG)

    self.xmlSchema:register(XMLValueType.BOOL, XMLTAG..".settings.debugMode", "Turn debugMode on for additional log output", self.defaultConfig.debugMode)
    self.xmlSchema:register(XMLValueType.BOOL, XMLTAG..".settings.enableContractValueOverrides", "enables overriding contract system default setting values", self.defaultConfig.enableContractValueOverrides)
    self.xmlSchema:register(XMLValueType.BOOL, XMLTAG..".settings.enableStrawFromHarvestMissions", "should straw be collectible from during harvest missions?", self.defaultConfig.enableStrawFromHarvestMissions)
    self.xmlSchema:register(XMLValueType.BOOL, XMLTAG..".settings.enableSwathingForHarvestMissions", "should you be able to use a Swather for harvest missions?", self.defaultConfig.enableSwathingForHarvestMissions)
    self.xmlSchema:register(XMLValueType.BOOL, XMLTAG..".settings.enableGrassFromMowingMissions", "should grass be collectible from during mowing missions?", self.defaultConfig.enableGrassFromMowingMissions)
    self.xmlSchema:register(XMLValueType.BOOL, XMLTAG..".settings.enableHayFromTedderMissions", "should hay be collectible from during tedder missions?", self.defaultConfig.enableHayFromTedderMissions)
    self.xmlSchema:register(XMLValueType.BOOL, XMLTAG..".settings.enableStonePickingFromMissions", "should stones be collectible from during tilling & sowing missions?", self.defaultConfig.enableStonePickingFromMissions)
    self.xmlSchema:register(XMLValueType.BOOL, XMLTAG..".settings.enableFieldworkToolFillItems", "should borrowed equipment come with free fieldwork items to fill your tools", self.defaultConfig.enableFieldworkToolFillItems)
    self.xmlSchema:register(XMLValueType.BOOL, XMLTAG..".settings.enableCollectingBalesFromMissions", "should you be able to collect bales from baling and baleWrapping contracts?", self.defaultConfig.enableCollectingBalesFromMissions)
    self.xmlSchema:register(XMLValueType.FLOAT, XMLTAG..".settings.rewardFactor", "applies a multiplier to the base game rewardPer value", self.defaultConfig.rewardFactor)
    self.xmlSchema:register(XMLValueType.INT, XMLTAG..".settings.maxContractsPerFarm", "how many contracts can be active at once", self.defaultConfig.maxContractsPerFarm)
    self.xmlSchema:register(XMLValueType.INT, XMLTAG..".settings.maxContractsPerType", "how many contracts per contract type can be available", self.defaultConfig.maxContractsPerType)
    self.xmlSchema:register(XMLValueType.INT, XMLTAG..".settings.maxContractsOverall", "how many contracts overall can be available", self.defaultConfig.maxContractsOverall)

    -- loop through the mission types to setup the customRewards
    for _, missionType in SettingsManager.missionTypes do
        self.xmlSchema:register(XMLValueType.INT, XMLTAG..".customRewards."..missionType, "custom rewards for "..missionType, nil)
    end

    -- loop through the mission types to setup the customMaxPerType
    for _, missionType in SettingsManager.missionTypes do
        self.xmlSchema:register(XMLValueType.INT, XMLTAG..".customMaxPerType."..missionType, "custom maxPerType for "..missionType, nil)
    end

    if self.loadDebug then Logging.info(MOD_NAME..":LOAD :: xml complete") end
end

--- Initiaze the a specified xmlFilename as a config
---@param xmlFilename string
---@param settingsObject table
function SettingsManager:importConfig(xmlFilename, settingsObject)
    local xmlFile = XMLFile.load("xmlFile", xmlFilename, self.xmlSchema)

    if SettingsManager.loadDebug then
        Logging.info(MOD_NAME..":LOAD :: loaded file: %s", xmlFilename)
    end

    if xmlFile ~= 0 then

        settingsObject.debugMode = xmlFile:getValue(XMLTAG..".settings.debugMode", self.defaultConfig.debugMode)

        settingsObject.enableContractValueOverrides = xmlFile:getValue(XMLTAG..".settings.enableContractValueOverrides", self.defaultConfig.enableContractValueOverrides)
        settingsObject.enableStrawFromHarvestMissions = xmlFile:getValue(XMLTAG..".settings.enableStrawFromHarvestMissions", self.defaultConfig.enableStrawFromHarvestMissions)
        settingsObject.enableSwathingForHarvestMissions = xmlFile:getValue(XMLTAG..".settings.enableSwathingForHarvestMissions", self.defaultConfig.enableSwathingForHarvestMissions)
        settingsObject.enableGrassFromMowingMissions = xmlFile:getValue(XMLTAG..".settings.enableGrassFromMowingMissions", self.defaultConfig.enableGrassFromMowingMissions)
        settingsObject.enableHayFromTedderMissions = xmlFile:getValue(XMLTAG..".settings.enableHayFromTedderMissions", self.defaultConfig.enableHayFromTedderMissions)
        settingsObject.enableStonePickingFromMissions = xmlFile:getValue(XMLTAG..".settings.enableStonePickingFromMissions", self.defaultConfig.enableStonePickingFromMissions)
        settingsObject.enableFieldworkToolFillItems = xmlFile:getValue(XMLTAG..".settings.enableFieldworkToolFillItems", self.defaultConfig.enableFieldworkToolFillItems)
        settingsObject.enableCollectingBalesFromMissions = xmlFile:getValue(XMLTAG..".settings.enableCollectingBalesFromMissions", self.defaultConfig.enableCollectingBalesFromMissions)
        
        settingsObject.rewardFactor = xmlFile:getValue(XMLTAG..".settings.rewardFactor", self.defaultConfig.rewardFactor)
        settingsObject.maxContractsPerFarm = xmlFile:getValue(XMLTAG..".settings.maxContractsPerFarm", self.defaultConfig.maxContractsPerFarm)
        settingsObject.maxContractsPerType = xmlFile:getValue(XMLTAG..".settings.maxContractsPerType", self.defaultConfig.maxContractsPerType)
        settingsObject.maxContractsOverall = xmlFile:getValue(XMLTAG..".settings.maxContractsOverall", self.defaultConfig.maxContractsOverall)

        -- loop through the mission types to pull the customRewards
        settingsObject.customRewards = {}
        for _, missionType in SettingsManager.missionTypes do
            settingsObject.customRewards[missionType] = xmlFile:getValue(XMLTAG..".customRewards."..missionType, nil)
        end

        -- loop through the mission types to pull the customMaxPerType
        settingsObject.customMaxPerType = {}
        for _, missionType in SettingsManager.missionTypes do
            settingsObject.customMaxPerType[missionType] = xmlFile:getValue(XMLTAG..".customMaxPerType."..missionType, nil)
        end

        -- ensure that values are within limits for numerical values
        if settingsObject.rewardFactor < 0.1 or settingsObject.rewardFactor > 5.0 then
            Logging.info('ContractBoost:LOAD :: user configured rewardFactor (%s) outside of limits, reset to default.', settingsObject.rewardFactor)
            settingsObject.rewardFactor = self.defaultConfig.rewardFactor
        end

        if settingsObject.maxContractsPerFarm < 1 or settingsObject.maxContractsPerFarm > 100 then
            Logging.info('ContractBoost:LOAD :: user configured maxContractsPerFarm (%s) outside of limits, reset to default.', settingsObject.maxContractsPerFarm)
            settingsObject.maxContractsPerFarm = self.defaultConfig.maxContractsPerFarm
        end

        if settingsObject.maxContractsPerType < 1 or settingsObject.maxContractsPerType > 20 then
            Logging.info('ContractBoost:LOAD :: user configured maxContractsPerType (%s) outside of limits, reset to default.', settingsObject.maxContractsPerType)
            settingsObject.maxContractsPerType = self.defaultConfig.maxContractsPerType
        end

        if settingsObject.maxContractsOverall < 1 or settingsObject.maxContractsOverall > 100 then
            Logging.info('ContractBoost:LOAD :: user configured maxContractsOverall (%d) outside of limits, reset to default.', settingsObject.maxContractsOverall)
            settingsObject.maxContractsOverall = self.defaultConfig.maxContractsOverall
            
        end

        local missionTypesCalculatedPerItem = {
            baleMission = true,
            baleWrapMission = true,
            deadwoodMission = true,
            treeTransportMission = true,
            destructibleRockMission = true,
        }

        -- Custom rewards must match steps in the new UI settings
        for propName, value in settingsObject.customRewards do
            if value ~= nil and value % 50 ~= 0 and missionTypesCalculatedPerItem[propName] then
                -- Round to steps of 50
                settingsObject.customRewards[propName] = math.ceil(value / 50) * 50
                Logging.info('ContractBoost:LOAD :: Rounded property customRewards.%s from %d to %d', propName, value, settingsObject.customRewards[propName])
            elseif value ~= nil and value % 100 ~= 0 then
                -- Round to steps of 100
                settingsObject.customRewards[propName] = math.ceil(value / 100) * 100
                Logging.info('ContractBoost:LOAD :: Rounded property customRewards.%s from %d to %d', propName, value, settingsObject.customRewards[propName])
            end
        end
        
    end

    xmlFile:delete()

    -- if self.loadDebug then
    --     print('-- ContractBoost:SettingsManager :: settingsObject')
    --     DebugUtil.printTableRecursively(settingsObject)
    -- end
end


---Writes the settings to our own XML file
function SettingsManager:saveSettings()
    local xmlPath = self:getSavegameXmlFilePath()
    if xmlPath == nil then
        Logging.warning('ContractBoost:SAVE :: Could not save current settings.') -- another warning has been logged before this
        return
    end

    local currentSettings = g_currentMission.contractBoostSettings

    -- Create an empty XML file in memory
    local xmlFileId = createXMLFile("ContractBoost", xmlPath, XMLTAG)

    setXMLBool(xmlFileId, XMLTAG..".settings.debugMode", currentSettings.debugMode)
    
    setXMLBool(xmlFileId, XMLTAG..".settings.enableContractValueOverrides", currentSettings.enableContractValueOverrides)
    setXMLBool(xmlFileId, XMLTAG..".settings.enableStrawFromHarvestMissions", currentSettings.enableStrawFromHarvestMissions)
    setXMLBool(xmlFileId, XMLTAG..".settings.enableSwathingForHarvestMissions", currentSettings.enableSwathingForHarvestMissions)
    setXMLBool(xmlFileId, XMLTAG..".settings.enableGrassFromMowingMissions", currentSettings.enableGrassFromMowingMissions)
    setXMLBool(xmlFileId, XMLTAG..".settings.enableHayFromTedderMissions", currentSettings.enableHayFromTedderMissions)
    setXMLBool(xmlFileId, XMLTAG..".settings.enableStonePickingFromMissions", currentSettings.enableStonePickingFromMissions)
    setXMLBool(xmlFileId, XMLTAG..".settings.enableFieldworkToolFillItems", currentSettings.enableFieldworkToolFillItems)
    setXMLBool(xmlFileId, XMLTAG..".settings.enableCollectingBalesFromMissions", currentSettings.enableCollectingBalesFromMissions)
    
    setXMLFloat(xmlFileId, XMLTAG..".settings.rewardFactor", currentSettings.rewardFactor)
    setXMLInt(xmlFileId, XMLTAG..".settings.maxContractsPerFarm", currentSettings.maxContractsPerFarm)
    setXMLInt(xmlFileId, XMLTAG..".settings.maxContractsPerType", currentSettings.maxContractsPerType)
    setXMLInt(xmlFileId, XMLTAG..".settings.maxContractsOverall", currentSettings.maxContractsOverall)

    -- loop through the mission types to pull the customRewards
    for _, missionType in SettingsManager.missionTypes do
        if currentSettings.customRewards[missionType] ~= nil then
            setXMLInt(xmlFileId, XMLTAG..".customRewards."..missionType, currentSettings.customRewards[missionType])
        end
    end

    -- loop through the mission types to pull the customMaxPerType
    for _, missionType in SettingsManager.missionTypes do
        if currentSettings.customMaxPerType[missionType] ~= nil then
            setXMLInt(xmlFileId, XMLTAG..".customMaxPerType."..missionType, currentSettings.customMaxPerType[missionType])
        end
    end

    -- Write the XML file to disk
    saveXMLFile(xmlFileId)

    Logging.info('ContractBoost:SAVE :: saved config to savegame: %s', xmlPath)
end


---Builds a path to the XML file.
---@return string|nil @The path to the XML file
function SettingsManager:getModSettingsXmlFilePath()
    return Utils.getFilename(self.modSettingsConfigFile, getUserProfileAppPath())
end


---Builds a path to the XML file.
---@return string|nil @The path to the XML file
function SettingsManager.getSavegameXmlFilePath()
    if g_currentMission and g_currentMission.missionInfo then
        local savegameDirectory = g_currentMission.missionInfo.savegameDirectory
        if savegameDirectory ~= nil then
            return ("%s/%s.xml"):format(savegameDirectory, MOD_NAME)
        -- else: Save game directory is nil if this is a brand new save
        end
    else
        Logging.warning(MOD_NAME .. ": Could not get path to Contract Boost xml settings file since g_currentMission.missionInfo is nil.")
    end
    return nil
end
