-- MissionBalance
-- @author GMNGjoy
-- @copyright 11/15/2024
-- @contact https://github.com/GMNGjoy/FS25_ContractBoost
-- @license CC0 1.0 Universal

MissionBalance = {}
MissionBalance.config = {}
MissionBalance.debug = false

function MissionBalance:init()
    if MissionBalance.debug then print('-- MissionBalance :: init.') end

    -- load the config from xml
    source(g_currentModDirectory.."scripts/xmlConfigLoader.lua")
    MissionBalance.config = XmlConfigLoader.init()
    MissionBalance.debug = MissionBalance.config.debugMode
    
    g_missionManager.loadMapData = Utils.appendedFunction(MissionManager.loadMapData, MissionBalance.loadMapData)

    print('-- ContractBoost:MissionBalance :: loaded.')
end

function MissionBalance:loadMapData()
    if MissionBalance.debug then print('-- MissionBalance :: loadMapData') end

    MissionBalance:initMissionSettings()
    MissionBalance:scaleMissionReward()

    if MissionBalance.debug then print('-- MissionBalance :: loadMapData complete') end
end

function MissionBalance:initMissionSettings()
    MissionManager.MAX_MISSIONS = MissionBalance.config.maxContractsOverall
    MissionManager.MAX_MISSIONS_PER_FARM = MissionBalance.config.maxContractsPerFarm
    MissionManager.MISSION_GENERATION_INTERVAL = 360000 --360000
    if MissionBalance.debug then print('-- MissionBalance :: settings updated.') end
end

function MissionBalance:scaleMissionReward()
    if MissionBalance.debug then print('-- MissionBalance :: scaleMissionReward') end

    local rewardFactor = MissionBalance.config.rewardFactor

    for _, missionType in ipairs(g_missionManager.missionTypes) do
        
        local typeName = missionType.name
        local prevValue = nil
        local newValue = nil

        if typeName == "baleWrapMission" then
            prevValue = missionType.data.rewardPerBale
            newValue = MissionBalance.config.customRewards[typeName] or missionType.data.rewardPerBale * rewardFactor
            missionType.data.rewardPerBale = newValue
        elseif typeName == "deadwoodMission" or typeName == "treeTransportMission" then
            prevValue = missionType.data.rewardPerTree
            newValue = MissionBalance.config.customRewards[typeName] or missionType.data.rewardPerTree * rewardFactor
            missionType.data.rewardPerTree = newValue
        elseif typeName == "destructibleRockMission" then
            prevValue = missionType.data.rewardPerRock
            newValue = MissionBalance.config.customRewards[typeName] or missionType.data.rewardPerRock * rewardFactor
            missionType.data.rewardPerRock = newValue
        else
            prevValue = missionType.data.rewardPerHa
            newValue = MissionBalance.config.customRewards[typeName] or missionType.data.rewardPerHa * rewardFactor
            missionType.data.rewardPerHa = newValue
        end

        -- update the number of each type to 5
        missionType.data.maxNumInstances = MissionBalance.config.maxContractsPerType

        if MissionBalance.debug then printf('---- Mission %s: %s | updated %s => %s', missionType.typeId, missionType.name, prevValue, newValue) end
    end

    if MissionBalance.debug then print('-- MissionBalance :: scaleMissionReward complete') end
end

MissionBalance:init();