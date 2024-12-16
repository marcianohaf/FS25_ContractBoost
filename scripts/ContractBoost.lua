-- ContractBoost:core
-- @author GMNGjoy
-- @copyright 11/15/2024
-- @contact https://github.com/GMNGjoy/FS25_ContractBoost
-- @license CC0 1.0 Universal

ContractBoost = {}
ContractBoost.config = {}
ContractBoost.listeners = {}
ContractBoost.debug = false
ContractBoost.modDirectory = g_currentModDirectory or ""
MOD_NAME = g_currentModName or "unknown"

source(ContractBoost.modDirectory.."scripts/XmlConfigManager.lua")

function ContractBoost:init()
    if ContractBoost.debug then print('-- ContractBoost:ContractBoost :: init.') end

    -- load the config from xml
    ContractBoost.config = XmlConfigManager.init()
    ContractBoost.debug = ContractBoost.config.debugMode
    source(ContractBoost.modDirectory.."scripts/lib/UIHelper.lua")
    source(ContractBoost.modDirectory.."scripts/SettingsUI.lua")
    ContractBoost.uiSettings = SettingsUI.new()
    ContractBoost.uiSettings:injectUiSettings(ContractBoost.config)

    source(ContractBoost.modDirectory.."scripts/MissionBalance.lua")
    source(ContractBoost.modDirectory.."scripts/MissionBorrow.lua")
    source(ContractBoost.modDirectory.."scripts/MissionTools.lua")

    -- setup function overrides
    MissionManager.loadMapData = Utils.appendedFunction(MissionManager.loadMapData, ContractBoost.loadMapData)
    -- ContractBoost.loadMapData()
    MissionManager.getIsMissionWorkAllowed = Utils.overwrittenFunction(MissionManager.getIsMissionWorkAllowed, MissionTools.getIsMissionWorkAllowed)

    -- enable extra fieldwork fill items to be added to contract items
    if ContractBoost.config.enableFieldworkToolFillItems then
        AbstractMission.onSpawnedVehicle = Utils.overwrittenFunction(AbstractMission.onSpawnedVehicle, MissionBorrow.onSpawnedVehicle)
    end

    -- enable collecting of bales from baling contracts.
    if ContractBoost.config.enableCollectingBalesFromMissions then
        BaleMission.addBale = Utils.overwrittenFunction(BaleMission.addBale, MissionTools.addBale)
        BaleMission.finishField = Utils.overwrittenFunction(BaleMission.finishField, MissionTools.finishField)
        BaleWrapMission.finishField = Utils.overwrittenFunction(BaleWrapMission.finishField, MissionTools.finishField)
    end

    -- make sure to show the details when someone looks at a mission
    AbstractMission.getDetails = Utils.overwrittenFunction(AbstractMission.getDetails, MissionBalance.getDetails)

    printf('-- ContractBoost :: loaded. debug: %s', ContractBoost.debug and "on" or "off")
end

-- function ContractBoost:setupListeners()
--     if ContractBoost.debug then print('-- ContractBoost:ContractBoost :: init.') end

--     -- setup load map data listener
--     if not ContractBoost.listeners.globalMapListeners then
--         g_missionManager.loadMapData = Utils.appendedFunction(MissionManager.loadMapData, ContractBoost.loadMapData)
--         MissionManager.getIsMissionWorkAllowed = Utils.overwrittenFunction(MissionManager.getIsMissionWorkAllowed, MissionTools.getIsMissionWorkAllowed)
--         ContractBoost.listeners.globalMapListeners = true
--     end

--     -- enable extra fieldwork fill items to be added to contract items
--     if ContractBoost.config.enableFieldworkToolFillItems then
--         AbstractMission.onSpawnedVehicle = Utils.overwrittenFunction(AbstractMission.onSpawnedVehicle, MissionBorrow.onSpawnedVehicle)
        
--     end

--     -- enable collecting of bales from baling contracts.
--     if ContractBoost.config.enableCollectingBalesFromMissions then
--         BaleMission.addBale = Utils.overwrittenFunction(BaleMission.addBale, MissionTools.addBale)
--         BaleMission.finishField = Utils.overwrittenFunction(BaleMission.finishField, MissionTools.finishField)
--         BaleWrapMission.finishField = Utils.overwrittenFunction(BaleWrapMission.finishField, MissionTools.finishField)
--     end

--     AbstractMission.getDetails = Utils.overwrittenFunction(AbstractMission.getDetails, MissionBalance.getDetails)

--     printf('-- ContractBoost :: loaded. debug: %s', ContractBoost.debug and "on" or "off")
-- end

function ContractBoost:loadMapData()
    if ContractBoost.debug then print('-- ContractBoost :: loadMapData') end

    -- MissionBalance: on map load apply new mission settings
    if ContractBoost.config.enableContractValueOverrides then
        MissionBalance:initMissionSettings()
        MissionBalance:scaleMissionReward()
    end

    -- MissionBorrow: on map load add items for fieldwork tools
    if ContractBoost.config.enableFieldworkToolFillItems then
        MissionBorrow:addFillItemsToMissionTools()
    end

    -- MissionTools: setup to allow more tools based on settings.
    MissionTools:setupAdditionalAllowedVehicles()

    if ContractBoost.debug then print('-- ContractBoost :: loadMapData complete.') end
end

-- Initialize ContractBoost when the map has finished loading
BaseMission.loadMapFinished = Utils.prependedFunction(BaseMission.loadMapFinished, function(...)
	ContractBoost:init()
end)

-- Save the config when the savegame is being saved
FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame, XmlConfigManager.storeConfig)


