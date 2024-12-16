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

-- include the XMLConfigManager globally
source(ContractBoost.modDirectory.."scripts/XmlConfigManager.lua")

---Initializes Contract Boost!
function ContractBoost:init()
    if ContractBoost.debug then Logging.info('-- ContractBoost:ContractBoost :: init.') end

    -- Load the config from xml
    ContractBoost.xmlManager = XmlConfigManager.new()
    ContractBoost.config = ContractBoost.xmlManager:initializeConfig()
    ContractBoost.debug = ContractBoost.config.debugMode

    -- Setup the UIHelper & settings
    source(ContractBoost.modDirectory.."scripts/lib/UIHelper.lua")
    source(ContractBoost.modDirectory.."scripts/SettingsUI.lua")
    ContractBoost.uiSettings = SettingsUI.new()
    ContractBoost.uiSettings:injectUiSettings(ContractBoost.config)

    -- Include the related Mission files.
    source(ContractBoost.modDirectory.."scripts/MissionBalance.lua")
    source(ContractBoost.modDirectory.."scripts/MissionBorrow.lua")
    source(ContractBoost.modDirectory.."scripts/MissionTools.lua")

    -- Setup function overrides
    MissionManager.loadMapData = Utils.appendedFunction(MissionManager.loadMapData, ContractBoost.activateSettings)
    MissionManager.getIsMissionWorkAllowed = Utils.overwrittenFunction(MissionManager.getIsMissionWorkAllowed, MissionTools.getIsMissionWorkAllowed)

    -- Enable extra fieldwork fill items to be added to contract items
    AbstractMission.onSpawnedVehicle = Utils.overwrittenFunction(AbstractMission.onSpawnedVehicle, MissionBorrow.onSpawnedVehicle)

    -- Enable collecting of bales from baling contracts.
    BaleMission.addBale = Utils.overwrittenFunction(BaleMission.addBale, MissionTools.addBale)
    BaleMission.finishField = Utils.overwrittenFunction(BaleMission.finishField, MissionTools.finishField)
    BaleWrapMission.finishField = Utils.overwrittenFunction(BaleWrapMission.finishField, MissionTools.finishField)

    -- Make sure to show the details when someone looks at a mission
    AbstractMission.getDetails = Utils.overwrittenFunction(AbstractMission.getDetails, MissionBalance.getDetails)

    Logging.info('-- ContractBoost :: loaded. debug: %s', ContractBoost.debug and "on" or "off")
end

function ContractBoost:activateSettings()
    if ContractBoost.debug then print('-- ContractBoost :: activateSettings') end

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

    if ContractBoost.debug then print('-- ContractBoost :: activateSettings complete.') end
end

-- Initialize ContractBoost when the map has finished loading
BaseMission.loadMapFinished = Utils.prependedFunction(BaseMission.loadMapFinished, function(...)
	ContractBoost:init()
end)

-- Save the config when the savegame is being saved
FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame,  function(...)
	ContractBoost.xmlManager:saveConfig()
end)