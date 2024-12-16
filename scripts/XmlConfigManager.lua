--- XML Config Loader
-- @author GMNGjoy
-- @copyright 11/15/2024
-- @contact https://github.com/GMNGjoy/FS25_ContractBoost
-- @license CC0 1.0 Universal
---This class is responsible for loading User Settings
---@class XmlConfigManager
---@field loadComplete boolean @Have we loaded the configuration?
---@field loadDebug boolean @Is debugging turned on for this class
---@field defaultConfig table @default values for all settings
---@field loadedConfig table @loaded values for all settings
---@field modSettingsConfigFile string @depreciated user configuration filename previously located in modSettings 
---@field savegameConfigFile string @savegame configuration file
---@field xmlTag string @the root xml tag
---@field xmlSchema table @the configured xml schema
---@field missionTypes table @re-used set of mission types
XmlConfigManager = {}
local XMLTAG = "contractBoost"

-- Create a meta table to get basic Class-like behavior
local XmlConfigManager_mt = Class(XmlConfigManager)

---Creates the xml configuration manager object
---@return XmlConfigManager @The new object
function XmlConfigManager.new()
    local self = setmetatable({}, XmlConfigManager_mt)
    self.loadDebug = true

    -- configuration files and loading states
    self.loadComplete = false
    self.loadedConfig = {}

    -- defaultConfig for existing settings
    self.defaultConfig = {
        debugMode = false,
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
    self.modSettingsConfigFile = "modSettings/ContractBoost.xml"
    self.savegameConfigFile = "FS22_ContractBoost.xml"

    -- supported missionTypes.
    self.missionTypes = {
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
    self.isInitialized = false

    return self
end

--- Load the user's configuration file from either the savegame or modSettingsFile
---@return table
function XmlConfigManager:initializeConfig()
    if self.loadDebug then print("---- ContractBoost:XmlConfigManager: read user configurations") end

    -- setup the xml schema
    self:initXmlSchema()

    -- don't load it twice if the config is already loaded.
    if self.loadComplete then
        if self.loadDebug then print("---- ContractBoost:XmlConfigManager: exit early!") end
        return self.loadedConfig
    end

    -- determine the proper path for the user's settings file
    local modSettingsFile = self:getModSettingsXmlFilePath()
    local savegameSettingsFile = self.getSavegameXmlFilePath()

    -- initialize the empty local object
    local userConfig = {}

    -- Default is to load from the savegameSettingsFile
    if savegameSettingsFile and fileExists(savegameSettingsFile) then
        
        userConfig = self:importConfig(savegameSettingsFile)
        printf("---- ContractBoost:XmlConfigManager: SAVEGAME configuration from: %s | debug: %s", savegameSettingsFile, userConfig.debugMode and "true" or "false")
    
    -- If they loaded a previous version, they may have modSettings file
    elseif modSettingsFile and fileExists(modSettingsFile) then

        userConfig = self:importConfig(modSettingsFile)
        printf("---- ContractBoost:XmlConfigManager: MODSETTINGS configuration from: %s | debug: %s", modSettingsFile, userConfig.debugMode and "true" or "false")

    else
        userConfig = self.defaultConfig
        printf("---- ContractBoost:XmlConfigManager: DEFAULT configuration used. | debug: %s", userConfig.debugMode and "true" or "false")
    end

    if self.loadDebug then
        print('-- ContractBoost:XmlConfigManager :: returned config')
        DebugUtil.printTableRecursively(userConfig)
    end

    -- make sure we don't load it twice
    self.userConfigLoaded = true
    
    -- store the config just in case.
    self.loadedConfig = userConfig
    return userConfig
end

--- Initiaze the XML file configuration
function XmlConfigManager:initXmlSchema()
    if self.loadDebug then print("---- ContractBoost:XmlConfigManager: init xml schema") end

    print('-- ContractBoost:XmlConfigManager :: self')
    DebugUtil.printTableRecursively(self)

    self.xmlSchema = XMLSchema.new(XMLTAG)

    print('post create schema')

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

    print('post primary register')

    -- loop through the mission types to setup the customRewards
    for _, missionType in self.missionTypes do
        self.xmlSchema:register(XMLValueType.INT, XMLTAG..".customRewards."..missionType, "custom rewards for "..missionType, nil)
    end

    print('post customRewards')

    -- loop through the mission types to setup the customMaxPerType
    for _, missionType in self.missionTypes do
        self.xmlSchema:register(XMLValueType.INT, XMLTAG..".customMaxPerType."..missionType, "custom maxPerType for "..missionType, nil)
    end

    print('post customMaxPerType')
    
    if self.loadDebug then print("---- ContractBoost:XmlConfigManager: xml complete") end
end

--- Initiaze the a specified xmlFilename as a config
---@param xmlFilename string
---@return table
function XmlConfigManager:importConfig(xmlFilename)
    local loadedConfig = {}
    local xmlFile = XMLFile.load("xmlFile", xmlFilename, self.xmlSchema)

    if XmlConfigManager.loadDebug then
        printf('-- ContractBoost:XmlConfigManager :: loaded file: %s', xmlFilename)
    end

    if xmlFile ~= 0 then

        loadedConfig.debugMode = xmlFile:getValue(XMLTAG..".settings.debugMode", self.defaultConfig.debugMode)

        loadedConfig.enableContractValueOverrides = xmlFile:getValue(XMLTAG..".settings.enableContractValueOverrides", self.defaultConfig.enableContractValueOverrides)
        loadedConfig.enableStrawFromHarvestMissions = xmlFile:getValue(XMLTAG..".settings.enableStrawFromHarvestMissions", self.defaultConfig.enableStrawFromHarvestMissions)
        loadedConfig.enableSwathingForHarvestMissions = xmlFile:getValue(XMLTAG..".settings.enableSwathingForHarvestMissions", self.defaultConfig.enableSwathingForHarvestMissions)
        loadedConfig.enableGrassFromMowingMissions = xmlFile:getValue(XMLTAG..".settings.enableGrassFromMowingMissions", self.defaultConfig.enableGrassFromMowingMissions)
        loadedConfig.enableHayFromTedderMissions = xmlFile:getValue(XMLTAG..".settings.enableHayFromTedderMissions", self.defaultConfig.enableHayFromTedderMissions)
        loadedConfig.enableStonePickingFromMissions = xmlFile:getValue(XMLTAG..".settings.enableStonePickingFromMissions", self.defaultConfig.enableStonePickingFromMissions)
        loadedConfig.enableFieldworkToolFillItems = xmlFile:getValue(XMLTAG..".settings.enableFieldworkToolFillItems", self.defaultConfig.enableFieldworkToolFillItems)
        loadedConfig.enableCollectingBalesFromMissions = xmlFile:getValue(XMLTAG..".settings.enableCollectingBalesFromMissions", self.defaultConfig.enableCollectingBalesFromMissions)
        
        loadedConfig.rewardFactor = xmlFile:getValue(XMLTAG..".settings.rewardFactor", self.defaultConfig.rewardFactor)
        loadedConfig.maxContractsPerFarm = xmlFile:getValue(XMLTAG..".settings.maxContractsPerFarm", self.defaultConfig.maxContractsPerFarm)
        loadedConfig.maxContractsPerType = xmlFile:getValue(XMLTAG..".settings.maxContractsPerType", self.defaultConfig.maxContractsPerType)
        loadedConfig.maxContractsOverall = xmlFile:getValue(XMLTAG..".settings.maxContractsOverall", self.defaultConfig.maxContractsOverall)

        -- loop through the mission types to pull the customRewards
        loadedConfig.customRewards = {}
        for _, missionType in self.missionTypes do
            loadedConfig.customRewards[missionType] = xmlFile:getValue(XMLTAG..".customRewards."..missionType, nil)
        end

        -- loop through the mission types to pull the customMaxPerType
        loadedConfig.customMaxPerType = {}
        for _, missionType in self.missionTypes do
            loadedConfig.customMaxPerType[missionType] = xmlFile:getValue(XMLTAG..".customMaxPerType."..missionType, nil)
        end

        -- ensure that values are within limits for numerical values
        if loadedConfig.rewardFactor < 0.1 or loadedConfig.rewardFactor > 5.0 then
            printf('-- ContractBoost:XmlConfigManager :: user configured rewardFactor (%s) outside of limits, reset to default.', loadedConfig.rewardFactor)
            loadedConfig.rewardFactor = self.rewardFactor
        end

        if loadedConfig.maxContractsPerFarm < 1 or loadedConfig.maxContractsPerFarm > 100 then
            printf('-- ContractBoost:XmlConfigManager :: user configured maxContractsPerFarm (%s) outside of limits, reset to default.', loadedConfig.maxContractsPerFarm)
            loadedConfig.maxContractsPerFarm = self.maxContractsPerFarm
        end

        if loadedConfig.maxContractsPerType < 1 or loadedConfig.maxContractsPerType > 20 then
            printf('-- ContractBoost:XmlConfigManager :: user configured maxContractsPerType (%s) outside of limits, reset to default.', loadedConfig.maxContractsPerType)
            loadedConfig.maxContractsPerType = self.maxContractsPerType
        end

        if loadedConfig.maxContractsOverall < 1 or loadedConfig.maxContractsOverall > 100 then
            printf('-- ContractBoost:XmlConfigManager :: user configured maxContractsOverall (%d) outside of limits, reset to default.', loadedConfig.maxContractsOverall)
            loadedConfig.maxContractsOverall = self.maxContractsOverall
            
        end

        local missionTypesCalculatedPerItem = {
            baleMission = true,
            baleWrapMission = true,
            deadwoodMission = true,
            treeTransportMission = true,
            destructibleRockMission = true,
        }

        -- Custom rewards must match steps in the new UI settings
        for propName, value in loadedConfig.customRewards do
            if value ~= nil and value % 50 ~= 0 and missionTypesCalculatedPerItem[propName] then
                -- Round to steps of 50
                loadedConfig.customRewards[propName] = math.ceil(value / 50) * 50
                printf('-- ContractBoost:XmlConfigManager :: Rounded property customRewards.%s from %d to %d', propName, value, loadedConfig.customRewards[propName])
            elseif value ~= nil and value % 100 ~= 0 then
                -- Round to steps of 100
                loadedConfig.customRewards[propName] = math.ceil(value / 100) * 100
                printf('-- ContractBoost:XmlConfigManager :: Rounded property customRewards.%s from %d to %d', propName, value, loadedConfig.customRewards[propName])
            end
        end
        
    end

    xmlFile:delete()

    if self.loadDebug then
        print('-- ContractBoost:XmlConfigManager :: loadedConfig')
        DebugUtil.printTableRecursively(loadedConfig)
    end

    return loadedConfig
end


---Writes the settings to our own XML file
function XmlConfigManager:storeConfig()
    local xmlPath = ContractBoost.xmlManager:getSavegameXmlFilePath()
    if xmlPath == nil then
        Logging.warning(MOD_NAME .. ": Could not store settings.") -- another warning has been logged before this
        return
    end

    local config = ContractBoost.config;
    local missionTypes = ContractBoost.xmlManager.missionTypes;

    print('-- ContractBoost:XmlConfigManager :: storeConfig')
    DebugUtil.printTableRecursively(config)

    -- Create an empty XML file in memory
    local xmlFileId = createXMLFile("ContractBoost", xmlPath, XMLTAG)

    setXMLBool(xmlFileId, XMLTAG..".settings.debugMode", config.debugMode)
    
    setXMLBool(xmlFileId, XMLTAG..".settings.enableContractValueOverrides", config.enableContractValueOverrides)
    setXMLBool(xmlFileId, XMLTAG..".settings.enableStrawFromHarvestMissions", config.enableStrawFromHarvestMissions)
    setXMLBool(xmlFileId, XMLTAG..".settings.enableSwathingForHarvestMissions", config.enableSwathingForHarvestMissions)
    setXMLBool(xmlFileId, XMLTAG..".settings.enableGrassFromMowingMissions", config.enableGrassFromMowingMissions)
    setXMLBool(xmlFileId, XMLTAG..".settings.enableHayFromTedderMissions", config.enableHayFromTedderMissions)
    setXMLBool(xmlFileId, XMLTAG..".settings.enableStonePickingFromMissions", config.enableStonePickingFromMissions)
    setXMLBool(xmlFileId, XMLTAG..".settings.enableFieldworkToolFillItems", config.enableFieldworkToolFillItems)
    setXMLBool(xmlFileId, XMLTAG..".settings.enableCollectingBalesFromMissions", config.enableCollectingBalesFromMissions)
    
    setXMLFloat(xmlFileId, XMLTAG..".settings.rewardFactor", config.rewardFactor)
    setXMLInt(xmlFileId, XMLTAG..".settings.maxContractsPerFarm", config.maxContractsPerFarm)
    setXMLInt(xmlFileId, XMLTAG..".settings.maxContractsPerType", config.maxContractsPerType)
    setXMLInt(xmlFileId, XMLTAG..".settings.maxContractsOverall", config.maxContractsOverall)

    -- loop through the mission types to pull the customRewards
    for _, missionType in missionTypes do
        printf('---- customRewards missionType: %s | %s', missionType, config.customRewards[missionType])
        if config.customRewards[missionType] ~= nil then
            setXMLInt(xmlFileId, XMLTAG..".customRewards."..missionType, config.customRewards[missionType])
        end
    end

    -- loop through the mission types to pull the customMaxPerType
    for _, missionType in missionTypes do
        printf('---- customMaxPerType missionType: %s | %s', missionType, config.customMaxPerType[missionType])
        if config.customMaxPerType[missionType] ~= nil then
            setXMLInt(xmlFileId, XMLTAG..".customMaxPerType."..missionType, config.customMaxPerType[missionType])
        end
    end

    -- Write the XML file to disk
    saveXMLFile(xmlFileId)

    printf('-- ContractBoost:XmlConfigManager :: saved config to savegame: %s', xmlPath)
end


---Builds a path to the XML file.
---@return string|nil @The path to the XML file
function XmlConfigManager:getModSettingsXmlFilePath()
    return Utils.getFilename(self.modSettingsConfigFile, getUserProfileAppPath())
end


---Builds a path to the XML file.
---@return string|nil @The path to the XML file
function XmlConfigManager.getSavegameXmlFilePath()
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
