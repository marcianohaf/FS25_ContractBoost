--- XML Config Loader
-- @author GMNGjoy
-- @copyright 11/15/2024
-- @contact https://github.com/GMNGjoy/FS25_ContractBoost
-- @license CC0 1.0 Universal

XmlConfigManager = {}
XmlConfigManager.path = g_currentModDirectory;
XmlConfigManager.loadComplete = false;
XmlConfigManager.loadDebug = true;

-- configuration files and loading states
XmlConfigManager.userConfig = {};
XmlConfigManager.userConfigLoaded = false;

-- defaults for existing settings
XmlConfigManager.rewardFactor = 1.5
XmlConfigManager.maxContractsPerFarm = 10
XmlConfigManager.maxContractsPerType = 5
XmlConfigManager.maxContractsOverall = 50
XmlConfigManager.enableContractValueOverrides = true
XmlConfigManager.enableStrawFromHarvestMissions = true
XmlConfigManager.enableSwathingForHarvestMissions = true
XmlConfigManager.enableGrassFromMowingMissions = true
XmlConfigManager.enableHayFromTedderMissions = true
XmlConfigManager.enableStonePickingFromMissions = true
XmlConfigManager.enableFieldworkToolFillItems = true
XmlConfigManager.enableCollectingBalesFromMissions = false
XmlConfigManager.debugMode = false

-- xmlConfigFiles
XmlConfigManager.defaultConfigFile = "xml/defaultConfig.xml"
XmlConfigManager.userConfigFile = "modSettings/ContractBoost.xml"
XmlConfigManager.savegameConfigFile = "FS22_ContractBoost.xml"
XmlConfigManager.xmlTag = "contractBoost"

XmlConfigManager.missionTypes = {
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

--- Initialize the loader
---@return table
function XmlConfigManager.init()

	if XmlConfigManager.loadDebug then print("---- ContractBoost:XmlConfigManager: read user configurations") end

	-- setup the xml schema
	XmlConfigManager.initXml()

	-- don't load it twice if the config is already loaded.
	if XmlConfigManager.userConfigLoaded then 
		return XmlConfigManager.userConfig
	end

	-- determine the proper path for the user's settings file
	local userSettingsFile = XmlConfigManager.getModSettingsXmlFilePath()
	local savegameSettingsFile = XmlConfigManager.getSavegameXmlFilePath()

	-- local savegameSettingsFile = Utils.getFilename(XmlConfigManager.savegameConfigFile, FSCareerMissionInfo.getSavegameDirectory())
	-- printf("---- ContractBoost:XmlConfigManager: savegameSettingsFile %s", savegameSettingsFile)
	-- print('-- ContractBoost:XmlConfigManager :: FSCareerMissionInfo')
	-- DebugUtil.printTableRecursively(FSCareerMissionInfo.savegameDirectory)

	local N = 0
	local loadedConfig = {}
	if fileExists(savegameSettingsFile) then
		-- case: savegameSettingsFile does not exist yet.

		XmlConfigManager.userConfig = XmlConfigManager.importConfig(savegameSettingsFile)
		XmlConfigManager.userConfigLoaded = true

		loadedConfig = XmlConfigManager.userConfig

		printf("---- ContractBoost:XmlConfigManager: IMPORT savegame configuration from: %s | debug: %s", XmlConfigManager.userConfigsavegameSettingsFileFile, loadedConfig.debugMode and "true" or "false")
	
	elseif fileExists(userSettingsFile) then
		-- case: savegameSettingsFile does not exist yet.

		XmlConfigManager.userConfig = XmlConfigManager.importConfig(userSettingsFile)
		XmlConfigManager.userConfigLoaded = true

		loadedConfig = XmlConfigManager.userConfig

		printf("---- ContractBoost:XmlConfigManager: IMPORT user configuration from: %s | debug: %s", XmlConfigManager.userConfigFile, loadedConfig.debugMode and "true" or "false")

	else

		printf("---- ContractBoost:XmlConfigManager: CREATING user configuration file: %s", XmlConfigManager.userConfigFile)
		local defaultSettingsFile = Utils.getFilename(XmlConfigManager.defaultConfigFile, XmlConfigManager.path)
		copyFile(defaultSettingsFile, userSettingsFile, false)

		loadedConfig = XmlConfigManager.importConfig(userSettingsFile)
	end

	if XmlConfigManager.loadDebug then
        print('-- ContractBoost:XmlConfigManager :: returned config')
        DebugUtil.printTableRecursively(loadedConfig)
    end

	return loadedConfig
end

--- Initiaze the XML file configuration
function XmlConfigManager.initXml()

	XmlConfigManager.xmlSchema = XMLSchema.new(XmlConfigManager.xmlTag)

	XmlConfigManager.xmlSchema:register(XMLValueType.BOOL, XmlConfigManager.xmlTag..".settings.debugMode", "Turn debugMode on for additional log output", XmlConfigManager.debugMode)
	
	XmlConfigManager.xmlSchema:register(XMLValueType.BOOL, XmlConfigManager.xmlTag..".settings.enableContractValueOverrides", "enables overriding contract system default setting values", XmlConfigManager.enableContractValueOverrides)
	XmlConfigManager.xmlSchema:register(XMLValueType.BOOL, XmlConfigManager.xmlTag..".settings.enableStrawFromHarvestMissions", "should straw be collectible from during harvest missions?", XmlConfigManager.enableStrawFromHarvestMissions)
	XmlConfigManager.xmlSchema:register(XMLValueType.BOOL, XmlConfigManager.xmlTag..".settings.enableSwathingForHarvestMissions", "should you be able to use a Swather for harvest missions?", XmlConfigManager.enableSwathingForHarvestMissions)
	XmlConfigManager.xmlSchema:register(XMLValueType.BOOL, XmlConfigManager.xmlTag..".settings.enableGrassFromMowingMissions", "should grass be collectible from during mowing missions?", XmlConfigManager.enableGrassFromMowingMissions)
	XmlConfigManager.xmlSchema:register(XMLValueType.BOOL, XmlConfigManager.xmlTag..".settings.enableHayFromTedderMissions", "should hay be collectible from during tedder missions?", XmlConfigManager.enableHayFromTedderMissions)
	XmlConfigManager.xmlSchema:register(XMLValueType.BOOL, XmlConfigManager.xmlTag..".settings.enableStonePickingFromMissions", "should stones be collectible from during tilling & sowing missions?", XmlConfigManager.enableStonePickingFromMissions)
	XmlConfigManager.xmlSchema:register(XMLValueType.BOOL, XmlConfigManager.xmlTag..".settings.enableFieldworkToolFillItems", "should borrowed equipment come with free fieldwork items to fill your tools", XmlConfigManager.enableFieldworkToolFillItems)
	XmlConfigManager.xmlSchema:register(XMLValueType.BOOL, XmlConfigManager.xmlTag..".settings.enableCollectingBalesFromMissions", "should you be able to collect bales from baling and baleWrapping contracts?", XmlConfigManager.enableCollectingBalesFromMissions)


	XmlConfigManager.xmlSchema:register(XMLValueType.FLOAT, XmlConfigManager.xmlTag..".settings.rewardFactor", "applies a multiplier to the base game rewardPer value", XmlConfigManager.rewardFactor)
	XmlConfigManager.xmlSchema:register(XMLValueType.INT, XmlConfigManager.xmlTag..".settings.maxContractsPerFarm", "how many contracts can be active at once", XmlConfigManager.maxContractsPerFarm)
	XmlConfigManager.xmlSchema:register(XMLValueType.INT, XmlConfigManager.xmlTag..".settings.maxContractsPerType", "how many contracts per contract type can be available", XmlConfigManager.maxContractsPerType)
	XmlConfigManager.xmlSchema:register(XMLValueType.INT, XmlConfigManager.xmlTag..".settings.maxContractsOverall", "how many contracts overall can be available", XmlConfigManager.maxContractsOverall)

	-- loop through the mission types to setup the customRewards
	for _, missionType in XmlConfigManager.missionTypes do
        XmlConfigManager.xmlSchema:register(XMLValueType.INT, XmlConfigManager.xmlTag..".customRewards."..missionType, "custom rewards for "..missionType, nil)
    end

	-- loop through the mission types to setup the customMaxPerType
	for _, missionType in XmlConfigManager.missionTypes do
        XmlConfigManager.xmlSchema:register(XMLValueType.INT, XmlConfigManager.xmlTag..".customMaxPerType."..missionType, "custom maxPerType for "..missionType, nil)
    end
	
end

--- Initiaze the a specified xmlFilename as a config
---@param xmlFilename string
---@return table
function XmlConfigManager.importConfig(xmlFilename)
	local loadedConfig = {}
	local xmlFile = XMLFile.load("xmlFile", xmlFilename, XmlConfigManager.xmlSchema)

	if XmlConfigManager.loadDebug then
        printf('-- ContractBoost:XmlConfigManager :: loaded file: %s', xmlFilename)
	end

	if xmlFile ~= 0 then

		loadedConfig.debugMode = xmlFile:getValue(XmlConfigManager.xmlTag..".settings.debugMode", XmlConfigManager.debugMode)

		loadedConfig.enableContractValueOverrides = xmlFile:getValue(XmlConfigManager.xmlTag..".settings.enableContractValueOverrides", XmlConfigManager.enableContractValueOverrides)
		loadedConfig.enableStrawFromHarvestMissions = xmlFile:getValue(XmlConfigManager.xmlTag..".settings.enableStrawFromHarvestMissions", XmlConfigManager.enableStrawFromHarvestMissions)
		loadedConfig.enableSwathingForHarvestMissions = xmlFile:getValue(XmlConfigManager.xmlTag..".settings.enableSwathingForHarvestMissions", XmlConfigManager.enableSwathingForHarvestMissions)
		loadedConfig.enableGrassFromMowingMissions = xmlFile:getValue(XmlConfigManager.xmlTag..".settings.enableGrassFromMowingMissions", XmlConfigManager.enableGrassFromMowingMissions)
		loadedConfig.enableHayFromTedderMissions = xmlFile:getValue(XmlConfigManager.xmlTag..".settings.enableHayFromTedderMissions", XmlConfigManager.enableHayFromTedderMissions)
		loadedConfig.enableStonePickingFromMissions = xmlFile:getValue(XmlConfigManager.xmlTag..".settings.enableStonePickingFromMissions", XmlConfigManager.enableStonePickingFromMissions)
		loadedConfig.enableFieldworkToolFillItems = xmlFile:getValue(XmlConfigManager.xmlTag..".settings.enableFieldworkToolFillItems", XmlConfigManager.enableFieldworkToolFillItems)
		loadedConfig.enableCollectingBalesFromMissions = xmlFile:getValue(XmlConfigManager.xmlTag..".settings.enableCollectingBalesFromMissions", XmlConfigManager.enableCollectingBalesFromMissions)
		
		loadedConfig.rewardFactor = xmlFile:getValue(XmlConfigManager.xmlTag..".settings.rewardFactor", XmlConfigManager.rewardFactor)
		loadedConfig.maxContractsPerFarm = xmlFile:getValue(XmlConfigManager.xmlTag..".settings.maxContractsPerFarm", XmlConfigManager.maxContractsPerFarm)
		loadedConfig.maxContractsPerType = xmlFile:getValue(XmlConfigManager.xmlTag..".settings.maxContractsPerType", XmlConfigManager.maxContractsPerType)
		loadedConfig.maxContractsOverall = xmlFile:getValue(XmlConfigManager.xmlTag..".settings.maxContractsOverall", XmlConfigManager.maxContractsOverall)

		-- loop through the mission types to pull the customRewards
		loadedConfig.customRewards = {}
		for _, missionType in XmlConfigManager.missionTypes do
			loadedConfig.customRewards[missionType] = xmlFile:getValue(XmlConfigManager.xmlTag..".customRewards."..missionType, nil)
		end

		-- loop through the mission types to pull the customMaxPerType
		loadedConfig.customMaxPerType = {}
		for _, missionType in XmlConfigManager.missionTypes do
			loadedConfig.customMaxPerType[missionType] = xmlFile:getValue(XmlConfigManager.xmlTag..".customMaxPerType."..missionType, nil)
		end

		-- ensure that values are within limits for numerical values
		if loadedConfig.rewardFactor < 0.1 or loadedConfig.rewardFactor > 5.0 then
			printf('-- ContractBoost:XmlConfigManager :: user configured rewardFactor (%s) outside of limits, reset to default.', loadedConfig.rewardFactor)
			loadedConfig.rewardFactor = XmlConfigManager.rewardFactor
		end

		if loadedConfig.maxContractsPerFarm < 1 or loadedConfig.maxContractsPerFarm > 100 then
			printf('-- ContractBoost:XmlConfigManager :: user configured maxContractsPerFarm (%s) outside of limits, reset to default.', loadedConfig.maxContractsPerFarm)
			loadedConfig.maxContractsPerFarm = XmlConfigManager.maxContractsPerFarm
		end

		if loadedConfig.maxContractsPerType < 1 or loadedConfig.maxContractsPerType > 20 then
			printf('-- ContractBoost:XmlConfigManager :: user configured maxContractsPerType (%s) outside of limits, reset to default.', loadedConfig.maxContractsPerType)
			loadedConfig.maxContractsPerType = XmlConfigManager.maxContractsPerType
		end

		if loadedConfig.maxContractsOverall < 1 or loadedConfig.maxContractsOverall > 100 then
			printf('-- ContractBoost:XmlConfigManager :: user configured maxContractsOverall (%d) outside of limits, reset to default.', loadedConfig.maxContractsOverall)
			loadedConfig.maxContractsOverall = XmlConfigManager.maxContractsOverall
			
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

	if XmlConfigManager.loadDebug then
        print('-- ContractBoost:XmlConfigManager :: loadedConfig')
        DebugUtil.printTableRecursively(loadedConfig)
    end

	return loadedConfig
end


---Writes the settings to our own XML file
function XmlConfigManager.storeConfig()
    local xmlPath = XmlConfigManager.getSavegameXmlFilePath()
    if xmlPath == nil then
        Logging.warning(MOD_NAME .. ": Could not store settings.") -- another warning has been logged before this
        return
    end

	local config = ContractBoost.config;

	print('-- ContractBoost:XmlConfigManager :: storeConfig')
	DebugUtil.printTableRecursively(config)

    -- Create an empty XML file in memory
	local xmlFileId = createXMLFile("ContractBoost", xmlPath, XmlConfigManager.xmlTag)

	setXMLBool(xmlFileId, XmlConfigManager.xmlTag..".settings.debugMode", config.debugMode)
	
	setXMLBool(xmlFileId, XmlConfigManager.xmlTag..".settings.enableContractValueOverrides", config.enableContractValueOverrides)
	setXMLBool(xmlFileId, XmlConfigManager.xmlTag..".settings.enableStrawFromHarvestMissions", config.enableStrawFromHarvestMissions)
	setXMLBool(xmlFileId, XmlConfigManager.xmlTag..".settings.enableSwathingForHarvestMissions", config.enableSwathingForHarvestMissions)
	setXMLBool(xmlFileId, XmlConfigManager.xmlTag..".settings.enableGrassFromMowingMissions", config.enableGrassFromMowingMissions)
	setXMLBool(xmlFileId, XmlConfigManager.xmlTag..".settings.enableHayFromTedderMissions", config.enableHayFromTedderMissions)
	setXMLBool(xmlFileId, XmlConfigManager.xmlTag..".settings.enableStonePickingFromMissions", config.enableStonePickingFromMissions)
	setXMLBool(xmlFileId, XmlConfigManager.xmlTag..".settings.enableFieldworkToolFillItems", config.enableFieldworkToolFillItems)
	setXMLBool(xmlFileId, XmlConfigManager.xmlTag..".settings.enableCollectingBalesFromMissions", config.enableCollectingBalesFromMissions)
	
	setXMLFloat(xmlFileId, XmlConfigManager.xmlTag..".settings.rewardFactor", config.rewardFactor)
	setXMLInt(xmlFileId, XmlConfigManager.xmlTag..".settings.maxContractsPerFarm", config.maxContractsPerFarm)
	setXMLInt(xmlFileId, XmlConfigManager.xmlTag..".settings.maxContractsPerType", config.maxContractsPerType)
	setXMLInt(xmlFileId, XmlConfigManager.xmlTag..".settings.maxContractsOverall", config.maxContractsOverall)

	-- loop through the mission types to pull the customRewards
	for _, missionType in XmlConfigManager.missionTypes do
		printf('---- customRewards missionType: %s | %s', missionType, config.customRewards[missionType])
		if config.customRewards[missionType] ~= nil then
			setXMLInt(xmlFileId, XmlConfigManager.xmlTag..".customRewards."..missionType, config.customRewards[missionType])
		end
	end

	-- loop through the mission types to pull the customMaxPerType
	for _, missionType in XmlConfigManager.missionTypes do
		printf('---- customMaxPerType missionType: %s | %s', missionType, config.customMaxPerType[missionType])
		if config.customMaxPerType[missionType] ~= nil then
			setXMLInt(xmlFileId, XmlConfigManager.xmlTag..".customMaxPerType."..missionType, config.customMaxPerType[missionType])
		end
	end

    -- Write the XML file to disk
    saveXMLFile(xmlFileId)

	printf('-- ContractBoost:XmlConfigManager :: saved config to savegame: %s', xmlPath)
end


---Builds a path to the XML file.
---@return string|nil @The path to the XML file
function XmlConfigManager.getModSettingsXmlFilePath()
    return Utils.getFilename(XmlConfigManager.userConfigFile, getUserProfileAppPath())
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
