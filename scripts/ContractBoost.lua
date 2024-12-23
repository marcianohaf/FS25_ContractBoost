-- ContractBoost:core
-- @author GMNGjoy
-- @copyright 12/16/2024
-- @contact https://github.com/GMNGjoy/FS25_ContractBoost
-- @license CC0 1.0 Universal

ContractBoost = {}
ContractBoost.listeners = {}
ContractBoost.debug = false
ContractBoost.modDirectory = g_currentModDirectory or ""
MOD_NAME = g_currentModName or "unknown"


---Initializes Contract Boost!
function ContractBoost:init()
    if ContractBoost.debug then Logging.info('-- ContractBoost:ContractBoost :: init.') end

    -- Load the config from xml
    -- ContractBoost.settings = SettingsManager.new()
    -- g_currentMission.contractBoostSettings = ContractBoost.settings:initializeSettings()
    SettingsManager:restoreSettings()
    ContractBoost.debug = g_currentMission.contractBoostSettings.debugMode

    -- Setup the UIHelper & settings
    ContractBoost.uiSettings = SettingsUI.new()
    ContractBoost.uiSettings:injectUiSettings(g_currentMission.contractBoostSettings)

    ContractBoost.initializeListeners()

    Logging.info('ContractBoost :: loaded. debug: %s', ContractBoost.debug and "on" or "off")
end


---Activates individual settings across the mod.
function ContractBoost:activateSettings()
    if ContractBoost.debug then Logging.info('ContractBoost :: activateSettings') end

    -- MissionBalance: on map load apply new mission settings
    if g_currentMission.contractBoostSettings.enableContractValueOverrides then
        MissionBalance:setMissionSettings()
        MissionBalance:scaleMissionReward()
    end

    -- MissionBorrow: on map load add items for fieldwork tools
    if g_currentMission.contractBoostSettings.enableFieldworkToolFillItems then
        MissionBorrow:addFillItemsToMissionTools()
    end

    -- MissionTools: setup to allow more tools based on settings.
    MissionTools:setupAdditionalAllowedVehicles()

    if ContractBoost.debug then Logging.info('ContractBoost :: activateSettings complete.') end
end


---Initializes all the listeners that will be used to integrate the settings with gameplay
function ContractBoost.initializeListeners()
    -- Setup function overrides
    MissionManager.loadMapData = Utils.appendedFunction(MissionManager.loadMapData, ContractBoost.activateSettings)
    MissionManager.getIsMissionWorkAllowed = Utils.overwrittenFunction(MissionManager.getIsMissionWorkAllowed, MissionTools.getIsMissionWorkAllowed)

    -- Enable extra fieldwork fill items to be added to contract items
    AbstractMission.onSpawnedVehicle = Utils.overwrittenFunction(AbstractMission.onSpawnedVehicle, MissionBorrow.onSpawnedVehicle)

    -- Enable collecting of bales from baling contracts.
    BaleMission.addBale = Utils.overwrittenFunction(BaleMission.addBale, MissionTools.addBale)
    BaleMission.finishField = Utils.overwrittenFunction(BaleMission.finishField, MissionTools.finishBaleField)
    BaleWrapMission.finishField = Utils.overwrittenFunction(BaleWrapMission.finishField, MissionTools.finishBaleWrapField)

    -- Make sure to show the details when someone looks at a mission
    AbstractMission.getDetails = Utils.overwrittenFunction(AbstractMission.getDetails, MissionBalance.getDetails)
end


---Creates a settings object which can be accessed from the UI and the rest of the code
---@param   mission     table   @The object which is later available as g_currentMission
local function createModSettings(mission)
    -- Register the settings object globally so we can access it from the event class and others later
    mission.contractBoostSettings = Settings.new()
    addModEventListener(mission.contractBoostSettings)
end
Mission00.load = Utils.prependedFunction(Mission00.load, createModSettings)


---Destroys the settings object when it is no longer needed.
local function destroyModSettings()
    if g_currentMission ~= nil and g_currentMission.contractBoostSettings ~= nil then
        removeModEventListener(g_currentMission.contractBoostSettings)
        g_currentMission.contractBoostSettings = nil
    end
end
FSBaseMission.delete = Utils.appendedFunction(FSBaseMission.delete, destroyModSettings)


---Initialize ContractBoost when the map has finished loading
BaseMission.loadMapFinished = Utils.prependedFunction(BaseMission.loadMapFinished, function(...)
    ContractBoost:init()
end)


---Save the config when the savegame is being saved
FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame,  function(...)
    ContractBoost.settings:saveSettings()
end)